# Prerequitites & Preparation

A global prerequisite is the existence of a VMWare vSphere ESXi host/cluster managed by a VCSA instance

## direnv

It is advisable to install [direnv](https://github.com/direnv/direnv) to persist
environmental variables to a hidden `.envrc` file.

After direnv is installed, set up on the local repository path:

```sh
# add direnv hooks
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
source ~/.zshrc

# add .envrc and .env to gitignores (global, local)
git config --global core.excludesFile '~/.gitignore'
touch ~/.gitignore
echo '.envrc' >> ~/.gitignore
echo '.env' >> ~/.gitignore
echo '.envrc' >> .gitignore
echo '.env' >> .gitignore

# remove .gitignored files
git ls-files -i --exclude-from=.gitignore | xargs git rm --cached

# set up direnv config to whitelist folders for direnv
mkdir -p ~/.config/direnv
cat > ~/.config/direnv/direnv.toml << EOF
[whitelist]
prefix = [ "/path/to/folders/to/whitelist" ]
exact = [ "/path/to/envrc/to/whitelist" ]
EOF

direnv reload
```

## govmomi/govc

[`govc`](https://github.com/vmware/govmomi/tree/master/govc) is a vSphere CLI built on top of govmomi.

The CLI is designed to be a user friendly CLI alternative to the GUI and well suited for automation tasks.
It also acts as a test harness for the govmomi APIs and provides working examples of how to use the APIs.

We will use it to identify names of vSphere resources

```sh
# these variables should be known from VCSA installation
cat << EOF >> .envrc
export GOVC_URL="vsphere-ip-or-hostname"
export GOVC_USERNAME="administrator@example.com"
export GOVC_PASSWORD="changeme"
export GOVC_DATACENTER=Homelab
export GOVC_INSECURE=true
EOF
```

### Using govc

[See docs for usage](https://github.com/vmware/govmomi/blob/master/govc/USAGE.md)

```sh
# find networks
govc find -type n
# find resource pool path
govc find -type p
# find datastore
govc find -type s
```

## Ansible

1. Install [ansible](https://docs.ansible.com/ansible/latest/index.html)
2. Update Ansible requirements

   ```sh
   ansible-galaxy install -r ./ansible/requirements.yaml --force
   ```

3. Update python requirements

   ```sh
   pip3 install -r ./ansible/requirements.txt
   ```

## [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## [VM Images](https://github.com/ahgraber/homelab-packer)
