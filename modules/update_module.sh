#! /bin/bash
VERSIONTAG="v3.2.0"

# check we're in `module` folder
if [[ $(basename $(pwd)) != "module" ]]; then
    cd "$(dirname "$0")"
fi

##############################################################################
### Clean and download terraform-vsphere module                            ###
##############################################################################
# remove current stuff
rm -rf ./*.zip
rm -rf ./terraform-vsphere

# download specified version
wget "https://github.com/Terraform-VMWare-Modules/terraform-vsphere-vm/archive/refs/tags/${VERSIONTAG}.zip"
unzip *${VERSIONTAG}.zip
mv ./terraform-vsphere* terraform-vsphere

##############################################################################
### Insert cloud-init and ansible hooks before "// Advanced options"       ###
##############################################################################
### NOTE: This is unnecessary and already can be included via the module/template
# echo "Adding cloud-init customization ..."
# # insert before "// Advanced options"
# ex ./terraform-vsphere/main.tf <<EOF
# /^// Advanced options/c
# $(cat ../cloudinit/cloudinit_hook)

# // Advanced options
# .
# w!
# q
# EOF

# echo "Adding Ansible provider ..."
# ex ./terraform-vsphere/main.tf <<EOF
# /^// Advanced options/c
# $(cat ../ansible/ansible_hook)

# // Advanced options
# .
# w!
# q
# EOF

##############################################################################
### Add/Update variables file                                              ###
##############################################################################
echo "Adding new variables to `variables.tf`"
cat <<EOF >> ./terraform-vsphere/variables.tf

### User config
variable "username" {
  description = "Username for cloud-init and ansible.  This will create an admin user."
  type        = string
  default     = null
}

variable "password" {
  description = "Password"
  type        = string
  default     = null
}

variable "ssh_key" {
  description = "SSH key for connecting to our instance"
  type        = string
  default     = null
}

variable "ssh_pubkey" {
  description = "Public half of SSH key for connecting to our instance."
  type        = string
  default     = null
}
EOF
