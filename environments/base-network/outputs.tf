# 輸出 核心 Prod VNet 的 ID
output "vnet_id" {
  description = "核心 Prod VNet 的 ID"
  value       = azurerm_virtual_network.prod_vnet.id
}

# 輸出 核心 Prod VNet 的名稱
output "vnet_name" {
  description = "核心 Prod VNet 的名稱"
  value       = azurerm_virtual_network.prod_vnet.name
}

# 輸出資源組 (RG) 的名稱
output "network_resource_group_name" {
  description = "核心網路所屬的 Resource Group 名稱"
  value       = azurerm_resource_group.network_rg.name
}

# test_vm_app_prod 的 Subnet ID
output "test_vm_app_prod_subnet_id" {
  description = "test-vm-app 專案在 Prod 環境的子網 ID"
  value       = azurerm_subnet.test_vm_app_prod.id
}

# test_k8s_app_prod 的 Subnet ID
output "test_k8s_app_prod_subnet_id" {
  description = "test-k8s-app 專案在 Prod 環境的子網 ID"
  value       = azurerm_subnet.test_k8s_app_prod.id
}