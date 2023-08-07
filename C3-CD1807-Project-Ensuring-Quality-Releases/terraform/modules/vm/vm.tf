resource "azurerm_network_interface" "test" {
  name                = "${var.application_type}-${var.resource_type}-nic"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "${var.subnet_id_test}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${var.public_ip_address_id}"
  }
}

resource "azurerm_linux_virtual_machine" "test" {
  name                = "${var.application_type}-${var.resource_type}-vm"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  size                = "Standard_DS2_v2"
  source_image_id       = "${var.packer_image}"
  admin_username      = "${var.admin_username}"
  network_interface_ids = [azurerm_network_interface.test.id]
  disable_password_authentication = true
  admin_ssh_key {
    username   = "${var.admin_username}"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrDfWXQ7FKhqI/CAeQqPq46mSQbVkmtefH2lw7qqsGFiLIjUuDTX77oAn66U8P56s8juU+6+6Q0XOEj1JMh+Ma2Icd2nBDU7moDNVxKYiC3p9paCm+7rS3NhYcjf1O7pP9pOw0lAn2T3ZJGWg7v9CVkRKCrPesN2SrkfrPJPCI6amDRhzD++njzIZoX6v4wSAgo4WVsfL1i3otoIeMmETx7kaDWEiAlg+CxV+BdTIs2Ge2SvaParqY9ejIk0JZuaEHYVi/AVNJJYfYKP2/uwVhYXgLu24eX8ml4KhsGH9YkaHCZrfNM7Ng0xSaF1PDjFQ0nhfUw2yqDQnvecrmISAv"
  }
  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
