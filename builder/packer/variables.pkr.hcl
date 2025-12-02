packer {
  required_plugins {
    xenserver = {
      # Same plugin Olivier uses in the Debian 12 generator
      # https://gist.github.com/olivierlambert/0eff6d8c10dfb11e1f28efe66d37ce6f 
      version = ">= 0.7.0"
      source  = "github.com/ddelnano/xenserver"
    }
  }
}

variable "iso_url" {
  type        = string
  description = "URL of Debian 13 ISO"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum for Debian 13 ISO (sha256:...)"
}

variable "remote_host" {
  type        = string
  description = "IP/FQDN of XCP-ng pool master"
}

variable "remote_username" {
  type        = string
  description = "User to access XCP-ng (root)"
  sensitive   = true
}

variable "remote_password" {
  type        = string
  description = "Password to access XCP-ng"
  sensitive   = true
}

variable "sr_iso_name" {
  type        = string
  description = "Name of ISO SR"
  default     = "ISO SR"
}

variable "sr_name" {
  type        = string
  description = "Name of SR for VM disk"
  default     = "VM SR"
}

variable "template_name" {
  type        = string
  description = "VM name"
  default     = "debian-13-base"
}

variable "template_description" {
  type        = string
  description = "Description for VM/template"
  default     = "Debian 13 base image built by Packer on XCP-ng"
}

variable "template_cpu" {
  type        = number
  description = "Number of vCPUs"
  default     = 2
}

variable "template_ram" {
  type        = number
  description = "RAM in MB"
  default     = 2048
}

variable "template_disk" {
  type        = number
  description = "Disk size in MB"
  default     = 20480
}

variable "template_networks" {
  type        = list(string)
  description = "List of network names to attach"
  default     = ["eth0"]
}

variable "template_tags" {
  type        = list(string)
  description = "Tags for VM/template"
  default     = ["packer", "debian13"]
}

variable "ssh_username" {
  type        = string
  description = "SSH user (created by preseed)"
  default     = "packer"
}

variable "ssh_password" {
  type        = string
  description = "SSH password"
  sensitive   = true
  default     = "packer"
}

variable "ssh_wait_timeout" {
  type        = string
  description = "How long Packer waits for SSH"
  default     = "30m"
}