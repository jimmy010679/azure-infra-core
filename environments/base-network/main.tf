# =====================================================================
# 核心資源組 (全環境共用網路機房)
# =====================================================================
resource "azurerm_resource_group" "network_rg" {
  name     = "azure-infra-core-network-rg" # 網路專用資料夾
  location = "Japan East"
}

# =====================================================================
# PROD 網路地基
# =====================================================================

# 1. 建立 prod 核心基礎 VNet
resource "azurerm_virtual_network" "prod_vnet" {
  name                = "core-prod-vnet"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  address_space       = ["10.10.0.0/16", "10.110.0.0/16"] # 核心網段
}

# 2. 專案 test-vm-app 的實體子網
resource "azurerm_subnet" "test_vm_app_prod" {
  name                 = "test-vm-app-prod-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.10.20.0/24"]
}

# 3. 專案 test-k8s-app 的 AKS 節點/容器大網段 (第3碼=0，吃 /16 大網段)
resource "azurerm_subnet" "test_k8s_app_prod" {
  name                 = "test-k8s-app-prod-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.prod_vnet.name
  address_prefixes     = ["10.110.0.0/16"] 
}

# =====================================================================
# DEV 網路地基
# =====================================================================
