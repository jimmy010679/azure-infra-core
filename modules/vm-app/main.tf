

# 1. 網路介面卡 (NIC)
resource "azurerm_network_interface" "vm_nic" {
  # ➔ 產出：test-k8s-app-prod-nic
  name                = "${var.resource_prefix}-${var.env}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# 2. 網路安全性群組 (NSG)
resource "azurerm_network_security_group" "vm_nsg" {
  # ➔ 產出：test-k8s-app-prod-nsg
  name                = "${var.resource_prefix}-${var.env}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.1.250.0/24" # base-network Bastion 網段 
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowNodejs3000"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*" # 允許任何人訪問網頁
    destination_address_prefix = "*"
  }
}

# 3. NSG 與網卡綁定
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# 4. 虛擬機本體
resource "azurerm_linux_virtual_machine" "vm" {
  # ➔ 產出：test-k8s-app-prod
  name                = "${var.resource_prefix}-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}