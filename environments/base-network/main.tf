resource "azurerm_resource_group" "network_rg" {
  name     = "azure-infra-core-network-rg" # 網路專用資料夾
  location = "Taiwan North"
}

resource "azurerm_virtual_network" "core_vnet" {
  name                = "core-hub-vnet"
  address_space       = ["10.1.0.0/16"] # 核心網段
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "test-vm-app-prod-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name

  address_prefixes     = ["10.1.1.0/24"] # 與 test-vm-app 劃分好的不衝突子網
}