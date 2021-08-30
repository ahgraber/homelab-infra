# Manage hosts with Ansible

## Check Ansible connection

The Terraform build will generate an [ansible hosts file](../ansible/inventory/cluster/host.ini)

```sh
cat << EOF >> .envrc
# vars for ansible
export ANSIBLE_HOSTS_FILE="./ansible/inventory/cluster/host.ini"
export ANSIBLE_PLAYBOOK_DIR="./ansible/playbooks"
export KUBECONFIG=$(expand_path ./kubeconfig)

EOF
direnv allow .

# list hosts
ansible all -i ${ANSIBLE_HOSTS_FILE} --list-hosts

# ping hosts
ansible all -i ${ANSIBLE_HOSTS_FILE} --one-line -m 'ping'
```

## Host management

```sh
# reboot hosts
ansible kubernetes -i ${ANSIBLE_HOSTS_FILE} -a '/usr/bin/systemctl reboot' --become

# shutdown hosts
ansible kubernetes -i ${ANSIBLE_HOSTS_FILE} -a '/usr/bin/systemctl poweroff' --become

# Ubuntu setup
ansible-playbook -i ${ANSIBLE_HOSTS_FILE} ${ANSIBLE_PLAYBOOK_DIR}/ubuntu/ubuntu-prepare.yml

# Ubuntu/apt upgrade
ansible-playbook -i ${ANSIBLE_HOSTS_FILE} ${ANSIBLE_PLAYBOOK_DIR}/ubuntu/ubuntu-upgrade.yml
```

## k3s install

```sh
# install
ansible-playbook -i ${ANSIBLE_HOSTS_FILE} ${ANSIBLE_PLAYBOOK_DIR}/kubernetes/k3s-install.yml
# get kubeconfig file
cp /tmp/kubeconfig ./kubeconfig
```

## use k3s

```sh
kubectl --kubeconfig=${KUBECONFIG} get nodes -o wide
kubectl --kubeconfig=${KUBECONFIG} get pods -A
```

See [homelab-gitops-k3s](https://github.com/ahgraber/homelab-gitops-k3s)
