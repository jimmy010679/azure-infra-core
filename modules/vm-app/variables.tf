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
  description = "從大管家網路端撈出來的 Subnet ID"
  type        = string
}

variable "vm_size" {
  description = "VM 的規格大小"
  type        = string
  default     = "Standard_B2s"
}