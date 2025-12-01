terraform {
  required_version = ">= 1.14.0"

  required_providers {
    xenorchestra = {
      source  = "vatesfr/xenorchestra"
      version = "0.36.1"
    }
  }
}