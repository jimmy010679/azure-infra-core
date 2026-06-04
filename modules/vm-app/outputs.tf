output "vm_private_ip" {
  description = "VM 的內網 IP"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "vm_id" {
  description = "VM 的 Azure Resource ID"
  value       = azurerm_linux_virtual_machine.vm.id
}