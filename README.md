# xo-ce

Bootstrap Xen Orchestra Community Edition VM on XCP-ng.

Usage:

```bash
SR_NAME="VM SR" NET_NAME="eth0" IP_MODE="dhcp" \
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/codingtino/xo-ce/master/import.sh)"
