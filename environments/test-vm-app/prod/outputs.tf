# ==========================================
# module vm-app
# ==========================================
# output "prod_vm_private_ip" {
#   description = "Prod 環境 VM 的內網 IP"
#   value       = module.vm_infra.vm_private_ip
# }

# ==========================================
# module vm-app-scale
# ==========================================
output "prod_vmss_id" {
  description = "Prod 環境虛擬機器擴展集 (VMSS) 的資源 ID"
  value       = module.vm_scale_infra.vmss_id
}