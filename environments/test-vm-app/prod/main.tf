# 1. 建立應用程式 RG
resource "azurerm_resource_group" "app_rg" {
  name     = "${var.test_vm_app_app_name}-${var.env}-rg"
  location = var.location
}

# 2. 動態查詢子網
data "azurerm_subnet" "shared_subnet" {
  name                 = "${var.test_vm_app_app_name}-${var.env}-subnet" # 透過變數動態拼接
  virtual_network_name = "core-hub-vnet"
  resource_group_name  = "azure-infra-core-network-rg"
}

# 3. 部署 VM 模組
module "vm_infra" {
  source              = "../../../modules/vm-app"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  env                 = var.env
  resource_prefix     = var.test_vm_app_app_name

  subnet_id           = data.azurerm_subnet.shared_subnet.id
  app_port            = 3000
  appgw_subnet_prefix = "10.1.10.0/24"
}