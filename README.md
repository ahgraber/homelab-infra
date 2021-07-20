# **Bootstrap k3s cluster hosts with vSphere, Terraform, and Ansible**
See: https://github.com/Terraform-VMWare-Modules/terraform-vsphere-vm

Use Terraform to provision VMs in vsphere and call ansible to configure hosts.
The second half of this project (deploying a k3s cluster via gitops) is [here](https://github.com/ahgraber/homelab-gitops-k3s)

### References
* https://github.com/blackjid/homelab-infra
* https://floating.io/2019/04/iaas-terraform-and-vsphere/
* https://github.com/reschouw/terraform-vsphere
* https://garyflynn.com/technology/hashicorp/create-your-first-vsphere-terraform-configuration/

* https://www.hashicorp.com/resources/ansible-terraform-better-together
* https://github.com/scarolan/ansible-terraform

# Preparation
1. [Create VM Images](https://github.com/ahgraber/homelab-packer)
   1. [with Packer](https://github.com/ahgraber/homelab-packer)
   2. [with cloud-init](./images/vmware%20templates%20with%cloud-init.md)


2. [Download vSphere Terraform module](https://github.com/Terraform-VMWare-Modules/)
_A convenience script `update_module.sh` is included for use_
   * Downloads and and unzips into ./module/terraform-vsphere.
   * Updates `./module/terraform-vsphere/main.tf` to include coud-init and ansible hooks
   * Updates `./module/terraform-vsphere/variables.tf' to include new variables
```
bash ./module/update_module.sh
```

# Customization
1. Create `./main.tf` from [examples](https://github.com/Terraform-VMWare-Modules/) and configure to point to vSphere instance and customize the VM image

2. Update `./cloud-init/userdata.yaml` if needed

<!-- ### 3. Update `./ansible/playbook.yml` if needed -->
> [GOVC](https://github.com/vmware/govmomi/tree/master/govc) can help identify names for vSphere resources
> ```
> export GOVC_URL='https://username:password@vsphere-ip-or-hostname/sdk'
> export GOVC_DATACENTER=Homelab
> export GOVC_INSECURE=true
> # usage: https://github.com/vmware/govmomi/blob/master/govc/USAGE.md
> # `govc find -type n` to find networks
> # `govc find -type p` to find resource pool path
> # `govc find -type s` to find datastore
> ```

# Bootstrap
1. Run terraform commands
```
terraform init
terraform plan
terraform apply
```

_**NOTE**_: Terraform expects it will be used to manage all infrastructure changes.
To update currently 'managed' deployment:
1. Run `terraform plan` against the updated `main.tf` file.  _`plan` will warn if the change will require destroying/reprovisioning a replacement host_
2. Run `terraform apply` to execute
