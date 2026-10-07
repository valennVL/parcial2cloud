locals {
  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }

  ssh_public_key_data = trimspace(var.ssh_public_key) != "" ? trimspace(var.ssh_public_key) : (can(file(pathexpand(var.ssh_public_key_path))) ? trimspace(file(pathexpand(var.ssh_public_key_path))) : "")
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name != "" ? var.resource_group_name : "${var.project_name}-rg"
  location = var.azure_region

  tags = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vnet"
  })
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.30.10.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "nodes" {
  name                = "${var.project_name}-nodes-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HAProxy
  security_rule {
    name                       = "HAProxy"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HAProxy stats
  security_rule {
    name                       = "HAProxyStats"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Microservices users
  security_rule {
    name                       = "Users"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3001"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Microservices products
  security_rule {
    name                       = "Products"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3002"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Microservices orders
  security_rule {
    name                       = "Orders"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3003"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nodes-nsg"
  })
}

# Network Interface for HAProxy
resource "azurerm_network_interface" "haproxy" {
  name                = "${var.project_name}-haproxy-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.30.10.10"
    public_ip_address_id          = azurerm_public_ip.haproxy.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-haproxy-nic"
  })
}

# Network Interface for Microservices
resource "azurerm_network_interface" "microservices" {
  name                = "${var.project_name}-microservices-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.30.10.20"
    public_ip_address_id          = azurerm_public_ip.microservices.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-microservices-nic"
  })
}

# Public IP for HAProxy
resource "azurerm_public_ip" "haproxy" {
  name                = "${var.project_name}-haproxy-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-haproxy-pip"
  })
}

# Public IP for Microservices
resource "azurerm_public_ip" "microservices" {
  name                = "${var.project_name}-microservices-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-microservices-pip"
  })
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.nodes.id
}

# HAProxy VM
resource "azurerm_virtual_machine" "vm_haproxy" {
  name                  = "vm-haproxy"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.haproxy.id]
  vm_size               = var.vm_size

  lifecycle {
    precondition {
      condition     = local.ssh_public_key_data != ""
      error_message = "SSH public key not found. Set ssh_public_key or provide a valid ssh_public_key_path."
    }
  }

  storage_os_disk {
    name              = "vm-haproxy-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "vm-haproxy"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = local.ssh_public_key_data
    }
  }

  tags = merge(local.common_tags, {
    Name = "vm-haproxy"
    Role = "haproxy"
  })
}

# Microservices VM
resource "azurerm_virtual_machine" "vm_microservices" {
  name                  = "vm-microservices"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.microservices.id]
  vm_size               = var.vm_size

  lifecycle {
    precondition {
      condition     = local.ssh_public_key_data != ""
      error_message = "SSH public key not found. Set ssh_public_key or provide a valid ssh_public_key_path."
    }
  }

  storage_os_disk {
    name              = "vm-microservices-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "vm-microservices"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = local.ssh_public_key_data
    }
  }

  tags = merge(local.common_tags, {
    Name = "vm-microservices"
    Role = "microservices"
  })
}

# Generate Ansible Inventory
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    haproxy_public_ip       = azurerm_public_ip.haproxy.ip_address
    microservices_public_ip = azurerm_public_ip.microservices.ip_address
    ssh_private_key_path    = var.ssh_private_key_path
    dockerhub_user          = var.dockerhub_user
    image_tag               = var.image_tag
  })
}
