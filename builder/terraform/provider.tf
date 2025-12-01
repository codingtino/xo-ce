variable "xo_url" {
  type = string
}

variable "xo_username" {
  type = string
}

variable "xo_password" {
  type      = string
  sensitive = true
}

variable "xo_insecure" {
  type    = bool
  default = false
}

provider "xenorchestra" {
  url      = var.xo_url
  username = var.xo_username
  password = var.xo_password
  insecure = var.xo_insecure
}