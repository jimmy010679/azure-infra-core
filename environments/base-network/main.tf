# =====================================================================
# 核心資源組 (全環境共用網路機房)
# =====================================================================
resource "azurerm_resource_group" "network_rg" {
  name     = "azure-infra-core-network-rg" # 網路專用資料夾
  location = "Japan East"
}

# =====================================================================
# PROD 網路地基
# =====================================================================

# 1. 建立 prod 核心基礎 VNet
resource "azurerm_virtual_network" "prod_vnet" {
  name                = "core-prod-vnet"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  address_space       = ["10.10.0.0/16", "10.110.0.0/16"] # 核心網段
}

# 2. 專案 test-vm-app 的實體子網
resource "azurerm_subnet" "test_vm_app_prod" {
  name                 = "test-vm-app-prod-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.10.20.0/24"]
}

# 3. 專案 test-k8s-app 的 AKS 節點/容器大網段 (第3碼=0，吃 /16 大網段)
resource "azurerm_subnet" "test_k8s_app_prod" {
  name                 = "test-k8s-app-prod-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.110.0.0/16"] 
}

# 4. 對外網關（Application Gateway）專用子網
resource "azurerm_subnet" "prod_appgw_subnet" {
  name                 = "appgw-prod-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.10.99.0/24"]
}

# 5. Prod 對外獨立公共 IP
resource "azurerm_public_ip" "prod_appgw_pip" {
  name                = "core-prod-appgw-pip"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 6. Prod 專用 Application Gateway
resource "azurerm_application_gateway" "prod_appgw" {
  name                = "core-prod-appgw"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-config"
    subnet_id = azurerm_subnet.prod_appgw_subnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "my-frontend-ip"
    public_ip_address_id = azurerm_public_ip.prod_appgw_pip.id
  }

  # ==========================================
  # 專案 test-vm-app (Port 3000)
  # ==========================================
  backend_address_pool {
    name = "test-vm-app-backend-pool"
  }

  backend_http_settings {
    name                  = "test-vm-app-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 3000 # ➔ 核心：轉發到內網 VM 的 3000 port
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "test-vm-app-listener"
    frontend_ip_configuration_name = "my-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
    host_name                      = "azure-test-vm-app.kyjhome.com"
  }

  request_routing_rule {
    name                       = "test-vm-app-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "test-vm-app-listener"
    backend_address_pool_name  = "test-vm-app-backend-pool"
    backend_http_settings_name = "test-vm-app-http-settings"
    priority                   = 10
  }

  # ==========================================
  # test-vm-app-2 (Port 8080)
  # ==========================================

}

# =====================================================================
# PROD 核心網路層出網設定 (NAT Gateway) 
# =====================================================================

# 1. PROD 固定 的公網 IP
resource "azurerm_public_ip" "nat_pip" {
  name                = "core-prod-nat-pip"
  location            = "japaneast"
  resource_group_name = "azure-infra-core-network-rg"
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 2. 建立 NAT 網關本體
resource "azurerm_nat_gateway" "nat_gw" {
  name                    = "core-prod-nat-gateway"
  location                = "japaneast"
  resource_group_name     = "azure-infra-core-network-rg"
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
}

# 3. 把固定 IP 綁定到 NAT 網關上
resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

# 4. 網關 與 應用子網 對接
resource "azurerm_subnet_nat_gateway_association" "subnet_assoc" {
  subnet_id      = azurerm_subnet.test_vm_app_prod.id 
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

# =====================================================================
# 核心網路層網頁跳板設定 (Azure Bastion)
# =====================================================================

# 1. 建立 Bastion 專屬子網
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.10.100.0/24"]
}

# 2. Bastion 專屬的獨立公網 IP (網頁連線入口)
resource "azurerm_public_ip" "bastion_pip" {
  name                = "core-prod-bastion-pip"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 3. 建立 Bastion 託管主機本體
resource "azurerm_bastion_host" "bastion" {
  name                = "core-prod-bastion"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  sku                 = "Standard"
  tunneling_enabled   = true
  ip_connect_enabled  = true

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

# =====================================================================
# Azure Key Vault
# =====================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "core_kv" {
  name                        = "core-prod-kv-kyj"
  location                    = azurerm_resource_group.network_rg.location 
  resource_group_name         = azurerm_resource_group.network_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }
}

# =====================================================================
# DEV 網路地基
# =====================================================================
