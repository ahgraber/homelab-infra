# **Bootstrap k3s cluster hosts with vSphere, Terraform, and Ansible**

See: https://github.com/Terraform-VMWare-Modules/terraform-vsphere-vm

Use Terraform to provision VMs in vsphere and call ansible to configure hosts.
The second half of this project (deploying a k3s cluster via gitops) is [here](https://github.com/ahgraber/homelab-gitops-k3s)

## References

- https://github.com/blackjid/homelab-infra
- https://floating.io/2019/04/iaas-terraform-and-vsphere/
- https://github.com/reschouw/terraform-vsphere
- https://garyflynn.com/technology/hashicorp/create-your-first-vsphere-terraform-configuration/

- https://www.hashicorp.com/resources/ansible-terraform-better-together
- https://github.com/scarolan/ansible-terraform

## [Preparation](docs/1%20-%20prerequisites.md)

## [Customization & Use](docs/2%20-%20terraform.md)

## Bootstrap

1. Run terraform commands

   ```sh
   terraform init
   terraform plan
   terraform apply # accept with `yes`
   ```

## Update

_**NOTE**_: Terraform expects it will be used to manage all infrastructure changes.  To update currently 'managed' deployment, update `main.tf`.

   ```sh
   # 'plan' will warn if the change will require destroying/reprovisioning a replacement host
   terraform plan  
   terraform apply
   ```

## Destroy

To tear down terraform-managed infra, run:

```sh
terraform destroy # accept with `yes`
```
