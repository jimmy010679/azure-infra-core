
output "vmss_id" {
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
  description = "虛擬機器擴展集 VMSS 的完整資源 ID"
}

output "vmss_name" {
  value       = azurerm_linux_virtual_machine_scale_set.vmss.name
  description = "虛擬機器擴展集 VMSS 的名稱"
}

output "vmss_nsg_id" {
  value       = azurerm_network_security_group.vmss_nsg.id
  description = "附隨於此擴展叢集的網路安全性群組 NSG 資源 ID"
}

output "vmss_identity_principal_id" {
  value       = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
  description = "此 VMSS 叢集系統指派託管身分 System Assigned Identity 的 Principal ID，供未來 Key Vault 或資料庫授權使用"
}