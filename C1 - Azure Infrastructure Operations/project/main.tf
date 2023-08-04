# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name = var.resource_group_name
  location = "West Europe"
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    udacity = "C1"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "main" {
  count               = var.virtual_machines_count
  name                = "${var.prefix}-main-${count.index}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
    security_rule {
    description                = "Allow access between VMs within virtual network."
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "accessInboundBetweenVM"
    priority                   = 100
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = azurerm_subnet.internal.address_prefixes[0]
    destination_port_range     = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }
  security_rule {
    description                = "Allow outbound acces from vms."
    access                     = "Allow"
    direction                  = "Outbound"
    name                       = "accessOutboundBetweenVM"
    priority                   = 200
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = azurerm_subnet.internal.address_prefixes[0]
    destination_port_range     = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }
  security_rule {
    description                = "Allow HTTP Traffic from the Load Balancer to the VMs."
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "allowHttp"
    priority                   = 300
    protocol                   = "Tcp"
    source_port_range          = "${var.port_range}"
    source_address_prefix      = azurerm_subnet.internal.address_prefixes[0]
    destination_port_range     = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }
  security_rule {
    description                = "Deny direct acces from internet."
    access                     = "Deny"
    direction                  = "Inbound"
    name                       = "denyPublicAccess"
    priority                   = 400
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }

  tags = {
        udacity = "C1"
    }
}

resource "azurerm_network_interface_security_group_association" "main" {
  count                     = var.virtual_machines_count
  network_interface_id      = element(azurerm_network_interface.main.*.id, count.index)
  network_security_group_id = element(azurerm_network_security_group.main.*.id, count.index)
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-load-balancer"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.prefix}-public-ip"
    public_ip_address_id = azurerm_public_ip.main.id
  }
  
  tags = {
    udacity = "C1"
  }
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-network-interface"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    udacity = "C1"
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-public-ip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    udacity = "C1"
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-backend-address-pool"
}

resource "azurerm_lb_probe" "main" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-probe"
  port                = 80
}

resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "${var.prefix}-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.main.id
  idle_timeout_in_minutes        = 15
  enable_tcp_reset               = true
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.virtual_machines_count
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  ip_configuration_name   = "public"
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
}

resource "azurerm_availability_set" "main" {
  name                         = "${var.prefix}-availability-set"
  location                     = data.azurerm_resource_group.main.location
  resource_group_name          = data.azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  
  tags = {
    udacity = "C1"
  }
}

data "azurerm_image" "main" {
    name = "UdacityPackerImage"
    resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine" "main" {
    count                 = var.virtual_machines_count
    name                  = "${var.prefix}-vm-${count.index}"
    
    admin_username                  = "${var.admin_user}"
    admin_password                  = "${var.admin_password}"
    disable_password_authentication = false

    resource_group_name   = data.azurerm_resource_group.main.name
    location              = data.azurerm_resource_group.main.location
    network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
    
    size               = "Standard_B1s"
    
    availability_set_id   = azurerm_availability_set.main.id

    source_image_id = "${data.azurerm_image.main.id}"

    os_disk {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }

    tags = {
        udacity = "C1"
    }
}