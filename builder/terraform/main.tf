resource "xenorchestra_vm" "xo_builder" {
  name_label  = "xo-builder"
  template    = data.xenorchestra_template.debian13.id
  power_state = "Running"

  cpus       = 4
  memory_max = 8 * 1024 * 1024 * 1024  # 8 GiB

  hvm_boot_firmware = "uefi"

  network {
    network_id = data.xenorchestra_network.lan.id
  }

  disk {
    name_label = "xo-builder-disk0"
    sr_id      = data.xenorchestra_sr.vm_sr.id
    size       = 80 * 1024 * 1024 * 1024  # 80 GiB
  }

  cloud_config = <<-EOF
  #cloud-config
  hostname: xo-builder
  fqdn: xo-ce.lab.local
  manage_etc_hosts: true

  timezone: Europe/Berlin

  users:
    - name: xo-builder
      sudo: ALL=(ALL) NOPASSWD:ALL
      groups: sudo
      shell: /bin/bash
      ssh-authorized-keys:
        - ${var.ssh_public_key}

  ssh_pwauth: false
  disable_root: true

  package_update: true
  packages:
    - git
    - curl
    - wget
    - build-essential
    - redis-server
    - python3
    - python3-pip
    - ca-certificates

  write_files:
    - path: /usr/local/sbin/install-xo.sh
      permissions: '0755'
      content: |
        #!/bin/bash
        set -euo pipefail
        exec > /var/log/install-xo.log 2>&1

        echo "[*] Installing Node.js 20 LTS..."
        curl -fsSL --http1.1 https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs

        echo "[*] Adding Debian 12 (bookworm) repo for libfuse2..."
        echo 'deb http://deb.debian.org/debian bookworm main' > /etc/apt/sources.list.d/bookworm.list
        apt-get update
        apt-get install -y -t bookworm libfuse2

        echo "[*] Installing yarn..."
        npm install --global yarn

        echo "[*] Cloning Xen Orchestra sources..."
        if [ ! -d /opt/xen-orchestra ]; then
          git clone https://github.com/vatesfr/xen-orchestra.git /opt/xen-orchestra
        fi

        cd /opt/xen-orchestra

        echo "[*] Installing dependencies and building..."
        yarn install
        yarn build

        echo "[*] Building XO 6 web UI..."
        yarn workspace @xen-orchestra/web build || echo "[!] XO 6 build failed, check logs in /opt/xen-orchestra"

        echo "[*] Creating systemd service for XO server..."
        cat >/etc/systemd/system/xo-server.service <<'EOSVC'
        [Unit]
        Description=Xen Orchestra Server
        After=network.target redis-server.service

        [Service]
        WorkingDirectory=/opt/xen-orchestra/packages/xo-server
        ExecStart=/usr/bin/node dist/cli.mjs
        Restart=always
        RestartSec=10
        User=root
        Environment=NODE_ENV=production

        [Install]
        WantedBy=multi-user.target
        EOSVC

        systemctl daemon-reload
        systemctl enable redis-server
        systemctl restart redis-server
        systemctl enable xo-server
        systemctl restart xo-server

        echo "[*] XO installation completed."
        echo "[*] XO should be available on port 80 (http://<ip>/)."

  runcmd:
    - /usr/local/sbin/install-xo.sh

  EOF
}

output "xo_builder_name" {
  value = xenorchestra_vm.xo_builder.name_label
}

output "xo_builder_ipv4" {
  value = xenorchestra_vm.xo_builder.ipv4_addresses
}