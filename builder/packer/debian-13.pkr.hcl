source "xenserver-iso" "debian13" {
  # ISO
  iso_checksum = "none"          # For a real setup, put the SHA256 here
  iso_url      = var.iso_url

  # Storage repositories
  sr_iso_name    = var.sr_iso_name
  sr_name        = var.sr_name
  tools_iso_name = ""

  # XCP-ng connection
  remote_host     = var.remote_host
  remote_username = var.remote_username
  remote_password = var.remote_password

  # Preseed HTTP server (served by Packer)
  http_directory = "http"
  ip_getter      = "tools"

  boot_wait = "5s"

  # Boot the Debian installer and point it to our preseed.cfg
  # This follows the pattern used in the official Debian 12 example.  [oai_citation:3‡College Sidekick](https://www.collegesidekick.com/study-docs/14583800?utm_source=chatgpt.com)
  boot_command = [
    "<wait><wait><wait><esc><wait>",
    "/install.amd/vmlinuz ",
    "initrd=/install.amd/initrd.gz ",
    "auto=true ",
    "priority=critical ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "debian-installer=en_US ",
    "locale=en_US.UTF-8 ",
    "keyboard-configuration/xkb-keymap=de ",
    "netcfg/get_hostname=debian13 ",
    "netcfg/get_domain=local ",
    "fb=false ",
    "debconf/frontend=noninteractive ",
    "console-setup/ask_detect=false ",
    "quiet --- <enter>"
  ]

  # VM/template properties
  # Using a Debian 12 template is fine to install Debian 13; this is what
  # XCP-ng folks do in their examples.  [oai_citation:4‡College Sidekick](https://www.collegesidekick.com/study-docs/14583800?utm_source=chatgpt.com)
  clone_template   = "Debian Trixie 13"
  vm_name          = var.template_name
  vm_description   = var.template_description
  vcpus_max        = var.template_cpu
  vcpus_atstartup  = var.template_cpu
  vm_memory        = var.template_ram
  network_names    = var.template_networks
  disk_size        = var.template_disk
  disk_name        = "${var.template_name}-disk"
  vm_tags          = var.template_tags

  # Communicator settings
  communicator           = "ssh"
  ssh_username           = var.ssh_username
  ssh_password           = var.ssh_password
  ssh_wait_timeout       = var.ssh_wait_timeout
  ssh_handshake_attempts = 100

  # What Packer does with the VM afterwards
  output_directory = "packer-debian-13"
  keep_vm          = "on_success"  # leave the VM on your XCP-ng host
  format           = "none"        # don't export XVA, just keep the VM
}

build {
  name    = "debian-13-xcp-ng"
  sources = ["source.xenserver-iso.debian13"]

  # Simple provisioning: just ensure SSH is enabled and system is updated.
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo systemctl enable ssh",
      "sudo systemctl restart ssh"
    ]
  }
}