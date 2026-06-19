# =====================================================================
# 應用基礎設施
# =====================================================================
# 1. 拋棄式金鑰
resource "tls_private_key" "discardable_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. 網路介面卡 (NIC)
resource "azurerm_network_interface" "vm_nic" {
  # ➔ 產出：test-k8s-app-prod-nic
  name                = "${var.resource_prefix}-${var.env}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# 3. 網路安全性群組 (NSG)
resource "azurerm_network_security_group" "vm_nsg" {
  # ➔ 產出：test-k8s-app-prod-nsg
  name                = "${var.resource_prefix}-${var.env}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # 安全保護：SSH 22 埠限制在 VNet 內 (供 az ssh 登入使用)
  security_rule {
    name                       = "AllowEntraSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork" # 🎯 限制只能從內網互通連線
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
    source_address_prefix      = var.appgw_subnet_prefix  # 只有 Application Gateway 子網 能轉發流量進來
    destination_address_prefix = "*"
  }
}

# 4. NSG 與網卡綁定
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# 5. 虛擬機本體
resource "azurerm_linux_virtual_machine" "vm" {
  # ➔ 產出：test-k8s-app-prod
  name                = "${var.resource_prefix}-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.discardable_ssh.public_key_openssh
  }

  # 開啟 VM 的託管身分
  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# 6. VM 加裝 AADSSHLoginForLinux 擴充功能 (讓作業系統底層直接對接 Azure Entra ID 身分驗證)
resource "azurerm_virtual_machine_extension" "entra_id_login" {
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id

  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux" # 舊版 AADLoginForLinux
  type_handler_version       = "1.0"

  auto_upgrade_minor_version = true
}

# 7. 開機腳本
resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "NodeAppInstall"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = <<SETTINGS
    {
      "script": "${var.custom_script_base64}"
    }
  SETTINGS
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
  name         = "${var.resource_prefix}-${var.env}-ssh-key"
  value        = tls_private_key.discardable_ssh.private_key_pem
  key_vault_id = data.azurerm_key_vault.remote_kv.id

  lifecycle {
    prevent_destroy = false
  }
}