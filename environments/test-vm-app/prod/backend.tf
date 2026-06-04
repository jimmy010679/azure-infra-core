terraform {
  backend "azurerm" {
    resource_group_name  = "azure-infra-core-rg"
    storage_account_name = "azureinfracoresa"
    container_name       = "tfstate"
    key                  = "test-vm-app/prod.tfstate"
  }
}