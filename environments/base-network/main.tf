# 1. 建立資源組
resource "azurerm_resource_group" "network_rg" {
  name     = "azure-infra-core-network-rg" # 網路專用資料夾
  location = "Japan East"
}

# 2. 建立 核心基礎 VNet
resource "azurerm_virtual_network" "core_vnet" {
  name                = "core-hub-vnet"
  address_space       = ["10.1.0.0/16"] # 核心網段
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
}

# 3. 建立 test-vm-app 應用端 VM 的子網
resource "azurerm_subnet" "app_subnet" {
  name                 = "test-vm-app-prod-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name

  address_prefixes     = ["10.1.1.0/24"] # 與 test-vm-app 劃分好的不衝突子網
}

# 4. 建立 Application Gateway 專用的子網
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-prod-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.1.10.0/24"]
}

# 5. 建立 對外的公共 IP
resource "azurerm_public_ip" "appgw_pip" {
  name                = "core-appgw-pip"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  allocation_method   = "Static"
  sku                 = "Standard" # 負載平衡器要求必須是 Standard
}

# 6. 建立 Application Gateway
resource "azurerm_application_gateway" "network_appgw" {
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
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "my-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  # 後端伺服器池：這裡先保留，未來透過 VM 的 Private IP 註冊進來
  backend_address_pool {
    name = "node-app-backend-pool"
  }

  backend_http_settings {
    name                  = "node-app-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 3000 # ➔ 核心：轉發到內網 VM 的 3000 port
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "node-app-listener"
    frontend_ip_configuration_name = "my-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "node-app-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "node-app-listener"
    backend_address_pool_name  = "node-app-backend-pool"
    backend_http_settings_name = "node-app-http-settings"
    priority                   = 10
  }
}