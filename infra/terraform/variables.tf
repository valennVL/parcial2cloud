variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_region" {
  description = "Azure region where resources will be created (must be allowed by subscription policy)"
  type        = string
}

variable "project_name" {
  description = "Project prefix for naming resources"
  type        = string
  default     = "parcial2cloud"
}

variable "resource_group_name" {
  description = "Azure Resource Group name override. Leave empty to use <project_name>-rg"
  type        = string
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key that will be injected into VMs"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_public_key" {
  description = "Raw SSH public key content. If set, it has priority over ssh_public_key_path"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key used by Ansible"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "vm_size" {
  description = "Azure VM size for both nodes"
  type        = string
  default     = "Standard_D2s_v4"
}

variable "dockerhub_user" {
  description = "Docker Hub username/organization hosting the service images"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag for all services"
  type        = string
  default     = "v1.0"
}
