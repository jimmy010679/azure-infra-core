# 輸出虛擬網路 (VNet) 的 ID
output "vnet_id" {
  description = "核心 Hub 虛擬網路的 Resource ID"
  value       = azurerm_virtual_network.core_vnet.id
}

# 輸出虛擬網路 (VNet) 的名稱
output "vnet_name" {
  description = "核心 Hub 虛擬網路的名稱"
  value       = azurerm_virtual_network.core_vnet.name
}

# 輸出資源組 (RG) 的名稱
output "network_resource_group_name" {
  description = "核心網路所屬的 Resource Group 名稱"
  value       = azurerm_resource_group.network_rg.name
}

# ➔ 最關鍵：輸出幫 test-vm-app 準備好的 Subnet ID
output "test_vm_app_prod_subnet_id" {
  description = "專門給 test-vm-app 生產環境使用的子網 ID"
  value       = azurerm_subnet.app_subnet.id
}