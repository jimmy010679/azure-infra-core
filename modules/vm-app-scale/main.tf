# =====================================================================
# 高可用水平擴展架構
# =====================================================================

# 1. 拋棄式金鑰 (供叢集內所有擴展實例統一使用或緊急排查)
resource "tls_private_key" "discardable_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. 網路安全性群組 (NSG) - 維持原本的嚴格隔離邏輯
resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "${var.resource_prefix}-${var.env}-vmss-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # 安全保護：SSH 22 埠限制在 VNet 內
  security_rule {
    name                       = "AllowEntraSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # 網頁安全：指定 app_port 只允許 Application Gateway 子網轉發流量
  security_rule {
    name                       = "AllowAppGatewayToNodejs"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.app_port
    source_address_prefix      = var.appgw_subnet_prefix
    destination_address_prefix = "*"
  }
}

# 3. 虛擬機水平擴展集 (VMSS) 本體
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "${var.resource_prefix}-${var.env}-vmss"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_size
  instances           = var.desired_instances # ➔ 初始預開的機器數量（例如：2）
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.discardable_ssh.public_key_openssh
  }

  # 網路介面模板配置
  network_interface {
    name                      = "vmss-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id
      
      # 🎯 關鍵對接：直接將擴展出來的機器自動塞進大管家的後端池！
      application_gateway_backend_address_pool_ids = [var.appgw_backend_pool_id]
    }
  }

  # 開啟叢集所有機器的託管身分
  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2" # ➔ 完美對齊第 6 代硬體的 Gen2 核心
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS" # ➔ 順手幫你修正為正統 Prod 規格的高級 SSD
  }

  # VMSS 規定：宣告升級策略
  upgrade_mode = "Manual"

  # -----------------------------------------------------------------
  # 擴充套件（Extensions）直接內嵌封裝在 VMSS 內部
  # -----------------------------------------------------------------
  
  # A. 對接 Azure Entra ID 身分驗證外掛
  extension {
    name                       = "AADSSHLoginForLinux"
    publisher                  = "Microsoft.Azure.ActiveDirectory"
    type                       = "AADSSHLoginForLinux"
    type_handler_version       = "1.0"
    auto_upgrade_minor_version = true
  }

  # B. 萬能開機自動化安裝腳本
  extension {
    name                       = "NodeAppInstall"
    publisher                  = "Microsoft.Azure.Extensions"
    type                       = "CustomScript"
    type_handler_version       = "2.1"
    auto_upgrade_minor_version = true

    protected_settings = <<SETTINGS
      {
        "script": "${var.custom_script_base64}"
      }
    SETTINGS
  }

  # 確保順序：防火牆關聯先定型，再開始長機器
  depends_on = [azurerm_network_security_group.vmss_nsg]
}



# =====================================================================
# Azure Key Vault
# =====================================================================
# 1. 動態撈取目前執行應用層部署的身分
data "azurerm_client_config" "current" {}

# 2. 引用大管家的保險箱 (本體在 base-network)
data "azurerm_key_vault" "remote_kv" {
  name                = "core-${var.env}-kv-kyj"
  resource_group_name = "azure-infra-core-network-rg"
}

# 3. 把私鑰當作加密秘密塞進 Key Vault 的核心抽屜中
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "test-vm-app-${var.env}-ssh-key"
  value        = tls_private_key.discardable_ssh.private_key_pem
  key_vault_id = data.azurerm_key_vault.remote_kv.id

  lifecycle {
    prevent_destroy = false # 練習用
  }
}