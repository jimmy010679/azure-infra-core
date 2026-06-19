# =====================================================================
# 虛擬機免金鑰登入 RBAC 角色指派
# =====================================================================

# 1. 動態抓取你目前的 Entra ID 使用者身分
# data "azurerm_client_config" "current_user" {}

# # 2. 指派「虛擬機器管理員登入」角色給自己
# resource "azurerm_role_assignment" "vm_admin_access" {
#   description          = "Automated by Terraform - 放行運維工程師免金鑰穿透登入專案虛擬機"

#   scope                = azurerm_resource_group.app_rg.id
  
#   # 角色名稱
#   role_definition_name = "Virtual Machine Administrator Login"
  
#   # 授權對象
#   principal_id         = data.azurerm_client_config.current_user.object_id
# }