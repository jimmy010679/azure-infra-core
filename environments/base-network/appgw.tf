# =====================================================================
# 平衡負載
# PROD
# =====================================================================

# 1. 對外網關（Application Gateway）專用子網
resource "azurerm_subnet" "prod_appgw_subnet" {
  name                 = "appgw-prod-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.10.99.0/24"]
}

# 2. Prod 對外獨立公共 IP
resource "azurerm_public_ip" "prod_appgw_pip" {
  name                = "core-prod-appgw-pip"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 3. Prod 專用 Application Gateway
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