variable "env" {
  description = "目前的環境名稱 (e.g., prod, uat, dev)"
  type        = string
}

variable "location" {
  type    = string
  default = "Taiwan North"
}

variable "test_vm_app_app_name" {
  description = "應用程式或專案的識別名稱"
  type        = string
}
