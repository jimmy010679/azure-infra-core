# =====================================================================
# 出網 NAT Gateway
# PROD
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
# UAT 核心網路層出網設定 (NAT Gateway) 
# =====================================================================

# =====================================================================
# DEV 核心網路層出網設定 (NAT Gateway) 
# =====================================================================