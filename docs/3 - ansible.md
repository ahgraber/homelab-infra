# Manage hosts with Ansible

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
   export passwd="..."
   export crypted_pass='...' # docker run --rm -it alpine:latest mkpasswd -m sha512 <password>
   export email="ahgraber@ninerealmlabs.com"
   export ssh_rsa="ssh-rsa ..."
   export ssh_ed25519="ssh-ed25519 ..."

   # vars for k3s
   export kubevip_address="10.2.113.1"
   export kubernetes_oidc_issuer="https://keycloak.ninerealmlabs.com/auth/realms/NineRealmLabs"
   export kubernetes_oidc_clientid="kubernetes"

   EOF

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
ansible all -i /path/to/inventory --one-line -m 'ping'
```

## Host management

```sh
### paths assume running from /ansible dir
### assuming we're using 'ubuntu' as group identifier
# reboot hosts
ansible -i ./inventory -l ubuntu -a '/usr/bin/systemctl reboot' --become

# shutdown hosts
ansible -i ./inventory -l ubuntu -a '/usr/bin/systemctl poweroff' --become

# Ubuntu setup
ansible-playbook -i ./inventory -l ubuntu ./playbooks/ubuntu/prepare.yaml

# Ubuntu/apt upgrade
ansible-playbook -i ./inventory -l ubuntu ./playbooks/ubuntu/upgrade.yaml
```

## k3s install

```sh
### paths assume running from /ansible dir
# install external roles
ansible-galaxy install xanmanning.k3s
### assuming we're using 'kubernetes' as group identifier
# install
ansible-playbook -i ./inventory -l kubernetes ./playbooks/kubernetes/k3s-install.yaml
# get kubeconfig file
cp /tmp/kubeconfig ./kubeconfig
```

## use k3s

```sh
kubectl --kubeconfig=${KUBECONFIG} get nodes -o wide
kubectl --kubeconfig=${KUBECONFIG} get pods -A
```

See [homelab-gitops-k3s](https://github.com/ahgraber/homelab-gitops-k3s)
