output "vm_nic_id" {
  description = "提供給 Hub 網關對接使用的虛擬網卡 (NIC) ID"
  value       = azurerm_network_interface.vm_nic.id
}

output "vm_private_ip" {
  description = "VM 的內網實體 IP"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "vm_id" {
  description = "VM 的 Azure Resource ID"
  value       = azurerm_linux_virtual_machine.vm.id
}