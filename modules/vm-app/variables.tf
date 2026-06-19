variable "resource_prefix" {
  description = "資源名稱的前綴 (e.g., test-k8s-app, order-api)"
  type        = string
}

variable "env" {
  description = "環境名稱 (e.g., prod, dev)"
  type        = string
}

variable "resource_group_name" {
  description = "應用程式資源要放置的 Resource Group 名稱"
  type        = string
}

variable "location" {
  description = "部署的 Azure 區域"
  type        = string
}

variable "subnet_id" {
  description = "從 Landing Zone 網路端撈出來的 Subnet ID"
  type        = string
}

variable "vm_size" {
  description = "VM 的規格大小"
  type        = string
  default     = "Standard_D2s_v6"
}

variable "app_port" {
  description = "應用程式服務所使用的 Port (e.g., 3000, 8080)"
  type        = number
  default     = 3000
}

variable "appgw_subnet_prefix" {
  description = "允許連入的 Application Gateway 子網網段"
  type        = string
  default     = "10.1.10.0/24" # 預設 AppGW 網段
}

variable "custom_script_base64" {
  type        = string
  description = "由外部呼叫端傳入，已經經過 Base64 編碼的開機自動化腳本"
  default     = ""
}