# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default     = "udacity-c1"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "West EU"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  default     = "udacity"
}

variable "packer_image_name" {
  description = "The name of the packer image"
  default     = "UdacityPackerImage"
}

variable "admin_user" {
  description = "Default username for admin user"
  default     = "secret"
}

variable "admin_password" {
  description = "Default password for admin user"
  default     = "secret$123"
}

variable "virtual_machines_count" {
  description = "The count of virtual machines"
  default     = 2
}

variable "port_range" {
  description = "The port to expose to the load balancer"
  default     = 80
}