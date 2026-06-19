# ==========================================
# 外部核心網路地基動態查詢 (Data Sources)
# ==========================================

# 1. 查詢 Landing Zone 分配給本專案的專屬內網子網 (Subnet)
data "azurerm_subnet" "shared_subnet" {
  name                 = "${var.test_vm_app_app_name}-${var.env}-subnet"
  virtual_network_name = "core-${var.env}-vnet"
  resource_group_name  = "azure-infra-core-network-rg"
}

# 2. 查詢核心對外總網關 (Application Gateway)
data "azurerm_application_gateway" "core_appgw" {
  name                = "core-${var.env}-appgw"
  resource_group_name = "azure-infra-core-network-rg"
}

# ==========================================
# 應用端專屬資源宣告 (Application Resources)
# ==========================================

# 1. 建立本應用獨立的資源組
resource "azurerm_resource_group" "app_rg" {
  name     = "${var.test_vm_app_app_name}-${var.env}-rg"
  location = var.location
}

# 2. 部署 VM 基礎設施 (vm-app)
# module "vm_infra" {
#   source              = "../../../modules/vm-app"
#   resource_group_name = azurerm_resource_group.app_rg.name
#   location            = azurerm_resource_group.app_rg.location
#   env                 = var.env
#   resource_prefix     = var.test_vm_app_app_name

#   vm_size             = "Standard_D2s_v6"       
#   subnet_id           = data.azurerm_subnet.shared_subnet.id
#   app_port            = 3000
#   appgw_subnet_prefix = "10.10.99.0/24" # 限制只允許 Landing Zone 網關子網連入

#   # 啟動開機腳本
#   custom_script_base64 = base64encode(templatefile("${path.cwd}/scripts/node_startup.sh.tpl", { app_port = 3000 }))
# }

# 2. 部署 VMSS 水平擴展叢集基礎設施 (vm-app-scale)
module "vm_scale_infra" {
  source              = "../../../modules/vm-app-scale"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  env                 = var.env
  resource_prefix     = var.test_vm_app_app_name

  vm_size             = "Standard_D2s_v6"       
  subnet_id           = data.azurerm_subnet.shared_subnet.id
  app_port            = 3000
  appgw_subnet_prefix = "10.10.99.0/24" # 限制只允許 Landing Zone 網關子網連入

  desired_instances   = 2

  # 擴展架構
  appgw_backend_pool_id = [
    for pool in data.azurerm_application_gateway.core_appgw.backend_address_pool : 
    pool.id if pool.name == "test-vm-app-backend-pool"
  ][0]

  # 啟動開機腳本
  custom_script_base64 = base64encode(templatefile("${path.cwd}/scripts/node_startup.sh.tpl", { app_port = 3000 }))
}

# ==========================================
# 跨架構通道對接 (Traffic Routing Bridge)
# 只有 vm-app 才需要
# ==========================================

# 1. 將本應用 VM 網卡插進 Landing Zone 網關的後端池 (Backend Pool)
# resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgw_assoc" {
#   network_interface_id    = module.vm_infra.vm_nic_id
#   ip_configuration_name   = "internal"

#   # 動態匹配
#   backend_address_pool_id = [
#     for pool in data.azurerm_application_gateway.core_appgw.backend_address_pool : 
#     pool.id if pool.name == "test-vm-app-backend-pool"
#   ][0]
# }