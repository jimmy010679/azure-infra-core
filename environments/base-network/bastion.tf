# =====================================================================
# Bastion 維運跳板機
# PROD
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