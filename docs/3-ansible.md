# Manage hosts with Ansible

- [Manage hosts with Ansible](#manage-hosts-with-ansible)
  - [Setup](#setup)
  - [Check Ansible connection](#check-ansible-connection)
  - [Send arbitrary commands](#send-arbitrary-commands)
  - [Host management](#host-management)
  - [k3s install](#k3s-install)
  - [use k3s](#use-k3s)
  - [k3s uninstall](#k3s-uninstall)

## Setup

1. Ensure .envrc vars are set

   ```sh
   cat << EOF >> .envrc
   # vars for ansible
   export KUBECONFIG=$(expand_path ./kubeconfig)
   export user="..."
   export domain="..."

   # vars for pxe/ubuntu ansible
   export gateway="10.2.0.1"
   export pxe_server="10.2.1.1"
   export default_pass="..."
   export crypted_pass='...' # docker run --rm -it alpine:latest mkpasswd -m sha512 <password>
   export email="<EXAMPLE@DOMAIN>COM>"
   export ssh_rsa="ssh-rsa ..."
   export ssh_ed25519="ssh-ed25519 ..."

   # vars for k3s
   export kubevip_address="10.2.113.1"
   export calico_node_cidr="10.2.118.0/24"
   EOF
   ```

   ```sh
   direnv allow .
   ```

2. Initialize templates

   ```sh
   # reload all env variables
   direnv allow .

   ### running from repo root
   # create SOPS hook for secret encryption
   envsubst < ./templates/ubuntu_vars.yaml.tmpl >! ./ansible/inventory/group_vars/ubuntu/ubuntu_vars.sops.yaml
   envsubst < ./templates/k8s_vars.yaml.tmpl >! ./ansible/inventory/group_vars/kubernetes/k8s_vars.sops.yaml

   export GPG_TTY=$(tty)
   # Encrypt SOPS secrets
   sops --encrypt --in-place ./ansible/inventory/group_vars/ubuntu/ubuntu_vars.sops.yaml
   sops --encrypt --in-place ./ansible/inventory/group_vars/kubernetes/k8s_vars.sops.yaml
   ```

## Check Ansible connection

The Terraform build will generate an [ansible hosts file](../ansible/inventory/cluster/hosts-terraform.yaml)

```sh
### paths assume running from /ansible dir
# list hosts
ansible all -i ./inventory --list-hosts
# list groups
ansible-inventory -i ./inventory --graph

# ping hosts
ansible all -i ./inventory --one-line -m 'ping'
ansible all -i ./inventory --one-line -m 'ping' -vvv # for debugging
```

## Send arbitrary commands

```sh
ansible <groupname> -m ansible.builtin.shell -a "apt upgrade -y" --become
```

## Host management

```sh
### paths assume running from /ansible dir
cd ./ansible/

### install external roles
ansible-galaxy install -r requirements.yaml --force
ansible-galaxy collection install -r requirements.yaml  --force

### assuming we're using 'ubuntu' as group identifier
ansible-playbook -i ./inventory -l ubuntu ./playbooks/ubuntu/reboot.yaml --become
ansible-playbook -i ./inventory -l ubuntu ./playbooks/ubuntu/shutdown.yaml --become

# Ubuntu setup
ansible-playbook -i ./inventory -l ubuntu ./playbooks/ubuntu/os-init.yaml --become --ask-become-pass

# Ubuntu/apt upgrade
ansible-playbook -i ./inventory -l ubuntu ./playbooks/ubuntu/apt-update.yaml

# Crowdsec setup
ansible-playbook -i ./inventory -l crowdsec ./playbooks/crowdsec/cs-install.yaml --become
ansible-playbook -i ./inventory -l crowdsec ./playbooks/crowdsec/cs-update.yaml --become

# Ubuntu OS upgrade
ansible-playbook -i ./inventory -l ubuntu ./playbooks/ubuntu/os-upgrade.yaml

# ...

# Install additional packages on TrueNas Scale
ansible-playbook -i ./inventory -l nas ./playbooks/truenas/packages.yaml --become
```

## k3s install

```sh
### paths assume running from ansible/ dir
cd ./ansible/

### assuming we're using 'kubernetes' as group identifier
# prep
ansible-playbook -i ./inventory -l kubernetes ./playbooks/kubernetes/k3s-prep.yaml --become # --ask-become-pass
# install -- this may take 2 runs to complete without error
ansible-playbook -i ./inventory -l kubernetes ./playbooks/kubernetes/k3s-install.yaml --become # --ask-become-pass
# copy kubeconfig to homelab-gitops-k3s

# rollout-reboot
ansible-playbook -i ./inventory -l kubernetes ./playbooks/kubernetes/k3s-reboot.yaml --become
# hard reboot
ansible-playbook -i ./inventory -l kubernetes ./playbooks/kubernetes/k3s-hardreboot.yaml --become
```

## use k3s

```sh
kubectl --kubeconfig=${KUBECONFIG} get nodes -o wide
kubectl --kubeconfig=${KUBECONFIG} get pods -A -o wide
```

See [homelab-gitops-k3s](https://github.com/ahgraber/homelab-gitops-k3s)

## k3s uninstall

```sh
# uninstall
ansible kubernetes -m ansible.builtin.systemd -a "name=k3s state=stopped" --become
ansible-playbook -i ./inventory -l kubernetes ./playbooks/kubernetes/k3s-nuke.yaml --become # --ask-become-pass
# clean up rook-ceph
ansible-playbook -i ./inventory -l kubernetes ./playbooks/kubernetes/rook-ceph-cleanup.yaml --become # --ask-become-pass
# hard reboot
ansible-playbook -i ./inventory -l kubernetes ./playbooks/ubuntu/reboot.yaml --become
```
