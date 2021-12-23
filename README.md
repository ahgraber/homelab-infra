# Bootstrap k3s cluster hosts with vSphere and Terraform

See: <https://github.com/Terraform-VMWare-Modules/terraform-vsphere-vm>

Use Terraform to provision VMs in vsphere and call ansible to configure hosts.
The second half of this project (deploying a k3s cluster via gitops) is [here](https://github.com/ahgraber/homelab-gitops-k3s)

## [Preparation](docs/1%20-%20prerequisites.md)

## [Customization & Use](docs/2%20-%20terraform.md)

## Bootstrap

Once customization is complete:

```sh
terraform init
terraform plan
terraform apply  # -auto-approve
```

> In OPNsense, set Unbound DNS overrides to IP address and node name of terraform'd nodes

## Update

> _Note:_ Terraform expects it will be used to manage all infrastructure changes.
> To update currently 'managed' deployment, update `main.tf`.

```sh
# 'plan' will warn if the change will require destroying/reprovisioning a replacement host
terraform plan
terraform apply  # -auto-approve
```

## Destroy

To tear down terraform-managed infra, run:

```sh
terraform destroy  # -auto-approve
```

## References

- <https://github.com/blackjid/homelab-infra>
- <https://floating.io/2019/04/iaas-terraform-and-vsphere/>
- <https://github.com/reschouw/terraform-vsphere>
- <https://garyflynn.com/technology/hashicorp/create-your-first-vsphere-terraform-configuration/>

- <https://www.hashicorp.com/resources/ansible-terraform-better-together>
- <https://github.com/scarolan/ansible-terraform>
