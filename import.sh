#!/bin/bash
set -euo pipefail

echo "=== Xen Orchestra CE import script ==="

# ---------------- CONFIG ----------------

# URL of the XO VM image (gzipped XVA)
# 👉 TODO: set this to the same URL used by the original xo-vm-import.sh
# For example, open the ronivay script and copy the IMAGE_URL / XVA URL here.
XO_IMAGE_URL="${XO_IMAGE_URL:-"https://xo-image.yawn.fi/downloads/image.xva.gz"}"

# Name of the SR where the XO VM disk will live
SR_NAME="${SR_NAME:-VM SR}"

# Name of the network to attach the XO VM to (you renamed it to 'eth0')
NET_NAME="${NET_NAME:-eth0}"

# IP mode: "dhcp" or "static"
IP_MODE="${IP_MODE:-dhcp}"

# Static network settings (used only if IP_MODE != 'dhcp')
XO_IP_ADDRESS="${XO_IP_ADDRESS:-10.24.107.50}"
XO_NETMASK="${XO_NETMASK:-255.255.0.0}"
XO_GATEWAY="${XO_GATEWAY:-10.24.0.1}"
XO_DNS="${XO_DNS:-8.8.8.8}"

# VM name label
XO_VM_NAME="${XO_VM_NAME:-xo-ce}"

# ----------------------------------------

if [[ "$XO_IMAGE_URL" == *"REPLACE-ME"* ]]; then
  echo "ERROR: XO_IMAGE_URL is not set."
  echo "Edit import.sh and set XO_IMAGE_URL to the actual XO VM image URL (xva.gz)."
  exit 1
fi

echo "Using SR name:    $SR_NAME"
echo "Using network:    $NET_NAME"
echo "XO VM name:       $XO_VM_NAME"
echo "IP mode:          $IP_MODE"
echo "XO image URL:     $XO_IMAGE_URL"
echo

# Resolve SR and network UUIDs
SR_UUID=$(xe sr-list name-label="$SR_NAME" --minimal || true)
NET_UUID=$(xe network-list name-label="$NET_NAME" --minimal || true)

if [[ -z "$SR_UUID" ]]; then
  echo "ERROR: SR '$SR_NAME' not found. Check 'xe sr-list'."
  exit 1
fi

if [[ -z "$NET_UUID" ]]; then
  echo "ERROR: Network '$NET_NAME' not found. Check 'xe network-list'."
  exit 1
fi

echo "Resolved SR UUID:  $SR_UUID"
echo "Resolved NET UUID: $NET_UUID"
echo

# Download and import XO VM
echo "Downloading and importing XO VM image..."
echo "(this may take a while, depending on your link to the XO image host)"
echo

XO_VM_UUID=$(
  curl -fL "$XO_IMAGE_URL" \
    | zcat \
    | xe vm-import filename=/dev/stdin sr-uuid="$SR_UUID"
)

if [[ -z "$XO_VM_UUID" ]]; then
  echo "ERROR: vm-import returned empty UUID."
  exit 1
fi

echo
echo "XO VM imported with UUID: $XO_VM_UUID"

# Set a friendly name (in case the image comes with its own)
xe vm-param-set uuid="$XO_VM_UUID" name-label="$XO_VM_NAME"

# Create VIF on the chosen network
echo "Creating VIF on network '$NET_NAME'..."
xe vif-create network-uuid="$NET_UUID" vm-uuid="$XO_VM_UUID" device=0 >/dev/null

# Configure IP via xenstore (if static)
if [[ "$IP_MODE" != "dhcp" ]]; then
  echo "Configuring static IP via xenstore..."
  xe vm-param-set uuid="$XO_VM_UUID" \
    xenstore-data:vm-data/ip="$XO_IP_ADDRESS" \
    xenstore-data:vm-data/netmask="$XO_NETMASK" \
    xenstore-data:vm-data/gateway="$XO_GATEWAY" \
    xenstore-data:vm-data/dns="$XO_DNS"
else
  echo "XO VM will use DHCP for IP configuration."
fi

# Ensure it boots from disk
echo "Setting HVM boot params..."
xe vm-param-remove uuid="$XO_VM_UUID" param-name=HVM-boot-params param-key=order 2>/dev/null || true
xe vm-param-set uuid="$XO_VM_UUID" HVM-boot-params:"order=c"

echo
echo "Starting XO VM..."
xe vm-start uuid="$XO_VM_UUID"

echo
echo "=== Done ==="
echo "XO VM UUID: $XO_VM_UUID"
echo
echo "Default XO credentials depend on the image you use."
echo "If you're using the ronivay image, it's typically something like:"
echo "  Web UI: admin@admin.net / admin"
echo "  SSH:    xo / xopass"
echo
echo "To get the IP once tools report it:"
echo "  xe vm-param-get uuid=$XO_VM_UUID param-name=networks"
echo
echo "You can override defaults like this, for example:"
echo "  SR_NAME='VM SR' NET_NAME='eth0' IP_MODE='static' \\"
echo "    XO_IP_ADDRESS='10.24.107.60' XO_GATEWAY='10.24.0.1' \\"
echo "    sudo bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/codingtino/xo-ce/master/import.sh)\""