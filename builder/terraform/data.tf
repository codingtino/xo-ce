data "xenorchestra_template" "debian13" {
  name_label = "debian_13_golden"
}

data "xenorchestra_network" "lan" {
  name_label = "eth0"
}

data "xenorchestra_sr" "vm_sr" {
  name_label = "VM SR"
}
