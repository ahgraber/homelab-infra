# Bootstrap a cluster with Terraform

## Customization

1. Add terraform files to `.gitignore`

   ```sh
   cat << EOF >> .gitignore
   .terraform/
   *.tfstate*
   *.lock.hcl
   *.zip
   *.ova
   .env
   .envrc

   modules/terraform-vsphere/
   archive/

   main.tf
   govcvars.sh
   EOF
   ```

2. Review `./main.tf.template` and [module examples](https://github.com/Terraform-VMWare-Modules/) and customize configuration as needed. Remember that we'll substitute secret environmental variables in.

3. Update `.envrc` with secrets

   ```sh
   # these variables should be known from VCSA installation
   cat << EOF >> .envrc
   # vars for govc
   export GOVC_URL="vsphere-ip-or-hostname"
   export GOVC_USERNAME="administrator@example.com"
   export GOVC_PASSWORD="changeme"
   export GOVC_DATACENTER=Homelab
   export GOVC_INSECURE=true

   # vars for 'main.tf'
   export VSPHERE_USER="user@example.com"
   export VSPHERE_USER_PASS="changeme!"
   export VSPHERE_SERVER="vsphere.example.com"
   export VSPHERE_DC="Homelab"
   export VSPHERE_VMRP="Cluster/Resources/RG"
   export VSPHERE_VMFOLDER="vms"
   export VSPHERE_DATASTORE="datastore/vms"
   # export VSPHERE_VMTEMPLATE="template_ubuntu2004_nodhcp"
   export VSPHERE_PORTGROUP="DPortGroup"

   export DNS="['1.1.1.1', '8.8.8.8']"
   export DOMAIN="example.com"
   # export GATEWAY="10.2.0.1"

   export NODE_USER="user"
   export NODE_PASS="changeme"
   export NODE_SSHKEY="ssh-rsa ImAnSSHKey123== ahgraber@ninerealmlabs.com"

   EOF
   ```

4. Update `main.tf.template` template file with non-secret info (machine specs, IP addresses. etc)

5. Substitute environmental variables into template

   ```zsh
   # reload all env variables
   direnv allow .

   # substitute environmental variables
   # ">!" allows overwrite on zsh
   envsubst < ./main.tf.template >! ./main.tf
   ```

6. Update `./cloud-init/userdata.yaml` if needed

## Bootstrap

1. Run terraform commands

   ```sh
   terraform init
   terraform plan
   terraform apply # accept with `yes`
   ```

## Update

_**NOTE**_: Terraform expects it will be used to manage all infrastructure changes.
To update currently 'managed' deployment:

1. Run `terraform plan` against the updated `main.tf` file. _`plan` will warn if the change will require destroying/reprovisioning a replacement host_
2. Run `terraform apply` to execute

## Destroy

To tear down terraform-managed infra, run:

```sh
terraform destroy # accept with `yes`
```
