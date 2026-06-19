variable "resource_group_name" {
  type        = string
  description = "應用端專屬資源組名稱"
}

variable "location" {
  description = "部署的 Azure 區域"
  type        = string
}

variable "env" {
  description = "環境名稱 (e.g., prod, dev)"
  type        = string
}

variable "resource_prefix" {
  type        = string
  description = "資源名稱的前綴字串"
}

variable "vm_size" {
  type        = string
  description = "虛擬機器的規格大小"
  default     = "Standard_D2s_v6"
}

variable "subnet_id" {
  type        = string
  description = "VMSS 叢集要插進去的內網子網 Subnet 資源 ID"
}

variable "app_port" {
  type        = number
  description = "後端應用程式運行的連接埠"
  default     = 3000
}

variable "appgw_subnet_prefix" {
  type        = string
  description = "大管家 Application Gateway 的子網網段（用於 NSG 白名單精準隔離）"
}

variable "custom_script_base64" {
  type        = string
  description = "由外部呼叫端（環境層）傳入、已經過 Base64 編碼的開機自動化安裝腳本"
}

# 🎯 擴展架構專屬進階變數
variable "desired_instances" {
  type        = number
  description = "VMSS 叢集初始預開的虛擬機實例數量"
  default     = 2
}

variable "appgw_backend_pool_id" {
  type        = string
  description = "大管家 Application Gateway 後端池 Backend Address Pool 的完整資源 ID"
}