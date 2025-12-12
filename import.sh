#!/bin/bash
set -euo pipefail

echo "=== Xen Orchestra CE import script ==="

# VM image
XO_IMAGE_URL="${XO_IMAGE_URL:-"https://github.com/codingtino/xo-ce/releases/latest/download/xo-ce_build.xva"}"

# VM name label
XO_VM_NAME="${XO_VM_NAME:-xo-ce}"

# Name of the SR where the XO VM disk will live
SR_NAME="${SR_NAME:-VM SR}"

# Name of the network to attach the XO VM to (you renamed it to 'eth0')
NET_NAME="${NET_NAME:-eth0}"

# IP mode: "dhcp" or "static"
IP_MODE="${IP_MODE:-dhcp}"

# Static network settings (used only if IP_MODE != 'dhcp')
XO_IP_ADDRESS="${XO_IP_ADDRESS:-10.0.0.10}"
XO_NETMASK="${XO_NETMASK:-255.255.0.0}"
XO_GATEWAY="${XO_GATEWAY:-10.0.0.1}"
XO_DNS="${XO_DNS:-1.1.1.1,1.0.0.1}"

# ----------------------------------------

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

xe vm-param-set uuid="$XO_VM_UUID" name-label="$XO_VM_NAME"

# Check if the imported VM already has a VIF
EXISTING_VIFS=$(xe vif-list vm-uuid="$XO_VM_UUID" --minimal || true)

if [[ -n "$EXISTING_VIFS" ]]; then
  echo "VM already has one or more VIFs; skipping VIF creation."
else
  echo "Creating VIF on network '$NET_NAME'..."
  xe vif-create network-uuid="$NET_UUID" vm-uuid="$XO_VM_UUID" device=0 >/dev/null
fi

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
xe vm-param-remove uuid="$XO_VM_UUID" param-name=HVM-boot-params param-key=order 2>/dev/null || true
xe vm-param-set uuid="$XO_VM_UUID" HVM-boot-params:"order=c"

echo
echo "Starting XO VM..."
xe vm-start uuid="$XO_VM_UUID"

# Wait for IP address
echo
echo "Waiting for XO VM to obtain an IP address..."
IP=""

for i in {1..30}; do
  NETS=$(xe vm-param-get uuid="$XO_VM_UUID" param-name=networks)
  IP=$(echo "$NETS" | sed -n 's/.*0\/ip: \([0-9\.]*\).*/\1/p')
  if [[ -n "$IP" ]]; then
    echo "XO VM IP address: $IP"
    break
  fi
  sleep 2
done

if [[ -z "$IP" ]]; then
  echo "WARNING: No IP detected yet. Use the command below to check later:"
  echo "  xe vm-param-get uuid=$XO_VM_UUID param-name=networks"
fi

echo
echo "=== Done ==="
echo "Default XO credentials depend on the image you use."
echo "If you're using the ronivay image, it's typically something like:"
echo "  Web UI: admin@admin.net / admin"
echo "  SSH:    xo / xopass"
echo
echo "To get the IP once tools report it:"
echo "  xe vm-param-get uuid=$XO_VM_UUID param-name=networks"
