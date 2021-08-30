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
   export TF_VAR_VSPHERE_USER="administrator@example.com"
   export TF_VAR_VSPHERE_USER_PASS="changeme"
   export TF_VAR_VSPHERE_SERVER="vcenter.example.com"
   export TF_VAR_VSPHERE_DC=""
   export TF_VAR_VSPHERE_VMRP="Cluster/Resources/poolname"
   export TF_VAR_VSPHERE_VMFOLDER="folderna e"
   export TF_VAR_VSPHERE_DATASTORE="datastore/dsname"
   export TF_VAR_VSPHERE_VMTEMPLATE="ubuntu_2004-k8s-nodhcp"
   export TF_VAR_VSPHERE_PORTGROUP="DPortGrp-name"
   export TF_VAR_DNS='["10.42.42.1", "10.42.42.2"]'
   export TF_VAR_DOMAIN="example.com"
   export TF_VAR_GATEWAY="10.42.42.1"

   export TF_VAR_CTRL_IPs='["10.42.42.10", "10.42.42.11", "10.42.42.12"]'
   export TF_VAR_WORK_IPs='["10.42.42.30", "10.42.42.31", "10.42.42.32"]'
   export TF_VAR_KUBE_VIP="10.42.42.42"

   export TF_VAR_NODE_USER="username"
   export TF_VAR_NODE_PASS="changeme"
   export TF_VAR_SSH_ID="ssh-rsa IamANsshKey12345== administrator@example.com

   export TF_VAR_ANSIBLE_HOSTS_FILE="./ansible/inventory/cluster/host.ini"
   export TF_VAR_ANSIBLE_PLAYBOOK_DIR="./ansible/playbooks"
   export TF_VAR_KUBECONFIG=$(expand_path ./kubeconfig)

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

6. Update `./cloud-init/userdata.yaml` to provide additional image customization if needed.

## Bootstrap

1. Run terraform commands

   ```sh
   terraform init
   terraform plan
   terraform apply  # -auto-approve
   ```

## Update

_**NOTE**_: Terraform expects it will be used to manage all infrastructure changes.
To update currently 'managed' deployment:

1. Run `terraform plan` against the updated `main.tf` file. _`plan` will warn if the change will require destroying/reprovisioning a replacement host_
2. Run `terraform apply` to execute

## Destroy

To tear down terraform-managed infra, run:

```sh
terraform destroy  # -auto-approve
```
