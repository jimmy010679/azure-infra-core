resource "azurerm_resource_group" "app_rg" {
  name     = "${var.test_vm_app_app_name}-${var.env}-rg"
  location = var.location
}

# 建立 VCP
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.test_vm_app_app_name}-${var.env}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
}

# 切 Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.test_vm_app_app_name}-${var.env}-internal-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = "azure-infra-core-rg"
}

module "vm_infra" {
  source              = "../../../modules/vm-app"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  env                 = var.env
  
  subnet_id           = azurerm_subnet.subnet.id
}