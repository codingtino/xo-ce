# xo-ce

Bootstrap Xen Orchestra Community Edition VM on XCP-ng.

Usage:

```bash
SR_NAME="VM SR" NET_NAME="eth0" IP_MODE="dhcp" \
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/codingtino/xo-ce/master/import.sh)"

packer init ./builder/packer/
packer validate ./builder/packer/
packer build ./builder/packer/

terraform -chdir=./builder/terraform init
terraform -chdir=./builder/terraform apply -auto-approve
terraform -chdir=./builder/terraform destroy -auto-approve

