### ref:
# https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine#creating-a-virtual-machine-from-a-template
# https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs/resources/virtual_machine#cloning-and-customization-example
# https://github.com/Terraform-VMWare-Modules/terraform-vsphere-vm
###

terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "2.0.2"
    }
  }
}

### Pull environmental variables from .envrc ##
# vsphere
variable "VSPHERE_USER" {}
variable "VSPHERE_USER_PASS" {}
variable "VSPHERE_SERVER" {}
variable "VSPHERE_DC" {}
variable "VSPHERE_VMRP" {}
variable "VSPHERE_VMFOLDER" {}
variable "VSPHERE_DATASTORE" {}
variable "VSPHERE_VMTEMPLATE" {}
variable "VSPHERE_PORTGROUP" {}
variable "DNS" {type=list}
variable "DOMAIN" {}
variable "GATEWAY" {}

# node/vm
variable "CTRL_IPs" {type=list}
variable "WORK_IPs" {type=list}
variable "KUBE_VIP" {}
variable "NODE_USER" {}
variable "NODE_PASS" {}
variable "SSH_ID" {}

# ansible
variable "ANSIBLE_HOSTS_FILE" {}
variable "ANSIBLE_PLAYBOOK_DIR" {}
variable "KUBECONFIG" {}

# Configure the VMware vSphere Provider
provider "vsphere" {
  user           = var.VSPHERE_USER
  password       = var.VSPHERE_USER_PASS
  vsphere_server = var.VSPHERE_SERVER

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

# Deploy n linux VMs
module "controllers" {
  source  = "Terraform-VMWare-Modules/vm/vsphere"
  version = "3.3.0"

  dc            = var.VSPHERE_DC
  vmrp          = var.VSPHERE_VMRP
  vmfolder      = var.VSPHERE_VMFOLDER
  datastore     = var.VSPHERE_DATASTORE

  vmtemp        = "ubuntu_2004-k8s-nodhcp"

  instances     = length(var.CTRL_IPs)
  vmname        = "k-ctrl-"

  cpu_number    = 4
  ram_size      = 8192  # [4096, 6144, 8192, 12288, 16384]
  # cpu_hot_add_enabled     = true
  # memory_hot_add_enabled  = true
  # disk_label        = "disk0"
  disk_size_gb      = [40]
  enable_disk_uuid  = true

  network = tomap({
    (var.VSPHERE_PORTGROUP) = var.CTRL_IPs # To use DHCP create Empty list ["","",""]
  })
  ipv4submask = ["16"]
  dns_server_list = var.DNS
  domain      = var.DOMAIN
  vmgateway   = var.GATEWAY

  enable_logging  = true
  # ### Does not pass cloud-init currently
  # extra_config    = {
  #   "guestinfo.userdata" = base64encode(file("${path.root}/cloudinit/user-data")),
  #   "guestinfo.userdata.encoding" = "base64",
  # }
}

module "workers" {
  source  = "Terraform-VMWare-Modules/vm/vsphere"
  version = "3.3.0"

  dc            = var.VSPHERE_DC
  vmrp          = var.VSPHERE_VMRP
  vmfolder      = var.VSPHERE_VMFOLDER
  datastore     = var.VSPHERE_DATASTORE

  vmtemp        = "ubuntu_2004-k8s-nodhcp"

  instances     = length(var.WORK_IPs)
  vmname        = "k-work-"

  cpu_number    = 4
  ram_size      = 8192  # [4096, 6144, 8192, 12288, 16384]
  # cpu_hot_add_enabled     = true
  # memory_hot_add_enabled  = true
  # disk_label        = "disk0"
  disk_size_gb      = [40]
  enable_disk_uuid  = true

  network = tomap({
    (var.VSPHERE_PORTGROUP) = var.WORK_IPs # To use DHCP create Empty list ["","",""]
  })
  ipv4submask = ["16"]
  dns_server_list = var.DNS
  domain      = var.DOMAIN
  vmgateway   = var.GATEWAY

  enable_logging  = true
  # ### Does not pass cloud-init currently
  # extra_config    = {
  #   "guestinfo.userdata" = base64encode(file("${path.root}/cloudinit/user-data")),
  #   "guestinfo.userdata.encoding" = "base64",
  # }
}


# create Ansible hosts file
resource "local_file" "ansible_hosts" {
  depends_on = [module.controllers, module.workers]
  content = templatefile("./templates/inventory.tmpl",
    {
      controller_hostnames = module.controllers.VM,
      controller_ips       = module.controllers.ip,
      worker_hostnames     = module.workers.VM,
      worker_ips           = module.workers.ip,
      node_user            = var.NODE_USER,
      kube_vip             = var.KUBE_VIP
    }
  )
  filename = "./ansible/inventory/cluster/host.ini"
}


# provision k3s with ansible
resource "null_resource" "null" {
  # depends_on = [module.controllers, module.workers, local_file.ansible_hosts]
  depends_on = [local_file.ansible_hosts]
  provisioner "local-exec" {
      command = <<EOF
        sleep 15

        # update ubuntu
        ansible-playbook -i ${var.ANSIBLE_HOSTS_FILE} ${var.ANSIBLE_PLAYBOOK_DIR}/ubuntu/ubuntu-prepare.yml
        ansible-playbook -i ${var.ANSIBLE_HOSTS_FILE} ${var.ANSIBLE_PLAYBOOK_DIR}/ubuntu/ubuntu-upgrade.yml

        # install k3s
        ansible-playbook -i ${var.ANSIBLE_HOSTS_FILE} ${var.ANSIBLE_PLAYBOOK_DIR}/kubernetes/k3s-install.yml
        cp -f /tmp/kubeconfig ./kubeconfig
        EOF
      environment = {}
  }
}
