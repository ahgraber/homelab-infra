# [**VM Templates with cloud-init**](https://blah.cloud/infrastructure/using-cloud-init-for-vm-templating-on-vsphere/)

`cloud-init` relies, for our purposes, on one file called `user-data` –
It general, it can also include a `meta-data file`, but that is handled in vSphere’s case by the customisation specs.

## References:

- https://blah.cloud/infrastructure/using-cloud-init-for-vm-templating-on-vsphere/
- https://github.com/vmware/cloud-init-vmware-guestinfo
- https://vmsysadmin.wordpress.com/2019/09/20/cloning-ubuntu-18-04-lts-cloud-image-on-vmware-using-cloud-init/
- https://blog.linoproject.net/cloud-init-with-terraform-in-vsphere-environment/

## Instructions

1. Install [GOVC](https://github.com/vmware/govmomi/tree/master/govc)

2. Create `govcvars.sh`

   ```sh
   cat > govcvars.sh << EOF
   export GOVC_INSECURE=1                              # Don't verify SSL certs on vCenter
   export GOVC_URL=10.198.16.4                         # vCenter IP/FQDN
   export GOVC_USERNAME=administrator@vsphere.local    # vCenter username
   export GOVC_PASSWORD=P@ssw0rd                       # vCenter password
   export GOVC_DATACENTER=DC01                         # Default datacenter to deploy to
   export GOVC_NETWORK="Cluster01-LAN-1-Routable"      # Default network to deploy to
   export GOVC_RESOURCE_POOL='cluster01/Resources'     # Default resource pool to deploy to
   export GOVC_DATASTORE=vsanDatastore                 # Default datastore to deploy to
   EOF
   ```

   > Variables can be found with:
   >
   > ```sh
   > export GOVC_URL='https://username:password@vsphere-ip-or-hostname/sdk'
   > export GOVC_DATACENTER=Homelab
   > export GOVC_INSECURE=true
   > # usage: https://github.com/vmware/govmomi/blob/master/govc/USAGE.md
   > govc find -type n # to find networks
   > govc find -type p # to find resource pool path
   > govc find -type s # to find datastore
   > ```

3. Run `source govcvars.sh`

4. Download cloud image

   - [Ubuntu 10.04](https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.ova)
   - [Ubuntu 20.04](https://cloud-images.ubuntu.com/releases/20.04/release/ubuntu-20.04-server-cloudimg-amd64.ova)

5. Extract image (this will output the spec to a file in your current directory called ubuntu.json):

   ```sh
   govc import.spec /PATH/TO/ubuntu-**.**-server-cloudimg-amd64.ova | python -m json.tool > ubuntu.json
   ```

6. Customize the `ubuntu.json` spec:

   - `hostname`
   - `Network` - default network / dportgroup
   - `Name` - template name for vSphere
   - `user-data` - other user data in cloud-init format:

     ```yaml
     ### cloud-init user-data
     groups:
       - docker
     users:
       - default
       - name: ubuntu
         ssh-authorized-keys:
           - ssh-rsa ...
         sudo: ALL=(ALL) NOPASSWD:ALL
         groups: sudo, docker
         shell: /bin/bash

     apt:
     sources:
       kubernetes:
         source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
         keyserver: "hkp://keyserver.ubuntu.com:80"
         keyid: BA07F4FB
       docker:
         arches: amd64
         source: "deb https://download.docker.com/linux/ubuntu bionic stable"
         keyserver: "hkp://keyserver.ubuntu.com:80"
         keyid: 0EBFCD88
     package_upgrade: true
     package_update: true
     packages:
       - curl
       - unzip
       - wget
       -
     ```

7. Deploy the OVA [and optionally apply additional customization]:

   ```sh
   # deploy
   govc import.ova -options=ubuntu.json /PATH/TO/ubuntu-**.**-server-cloudimg-amd64.ova
   # set 4 vCPUs, 4GB RAM, enable diskUUID (for K8s vSphere Cloud Provider)
   govc vm.change -vm {TEMPLATENAME} -c 4 -m 4096 -e="disk.enableUUID=1"
   # relabel disk and set to 20GB disk
   govc vm.disk.change -vm {TEMPLATENAME} -disk.label "disk0" -size 20G
   ```

8. Get VM IP address from vSphere, and SSH in for additional customization/updates

   If no new user account was set, then use default `ubuntu` user

   ```sh
   # update
   sudo apt update
   sudo apt install open-vm-tools -y
   sudo apt upgrade -y
   sudo apt autoremove -y
   
   # cleans out all of the cloud-init cache, disable and remove cloud-init customisations
   sudo cloud-init clean --logs
   sudo touch /etc/cloud/cloud-init.disabled
   sudo rm -rf /etc/netplan/50-cloud-init.yaml
   sudo apt purge cloud-init -y
   sudo apt autoremove -y
   
   # Don't clear /tmp
   sudo sed -i 's/D \/tmp 1777 root root -/#D \/tmp 1777 root root -/g' /usr/lib/tmpfiles.d/tmp.conf
   
   # Remove cloud-init and rely on dbus for open-vm-tools
   sudo sed -i 's/Before=cloud-init-local.service/After=dbus.service/g' /lib/systemd/system/open-vm-tools.service
   
   # cleanup current ssh keys so templated VMs get fresh key
   sudo rm -f /etc/ssh/ssh_host_*
   
   # add check for ssh keys on reboot...regenerate if neccessary
   sudo tee /etc/rc.local > /dev/null << EOL
   #!/bin/sh -e
   #
   # rc.local
   #
   # This script is executed at the end of each multiuser runlevel.
   # Make sure that the script will "" on success or any other
   # value on error.
   #
   # In order to enable or disable this script just change the execution
   # bits.
   #
   
   # By default this script does nothing.
   test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server
   exit 0
   EOL
   
   # make the script executable
   sudo chmod +x /etc/rc.local
   
   # cleanup apt
   sudo apt clean
   
   # reset the machine-id (DHCP leases in 18.04 are generated based on this... not MAC...)
   echo "" | sudo tee /etc/machine-id > /dev/null
   
   # disable swap for K8s
   sudo swapoff --all
   sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
   
   # Apply updates and cleanup Apt cache
   # packer build --var-file=variables.json ubuntu-2004.json
   apt-get update
   apt-get -y dist-upgrade
   apt-get -y autoremove
   apt-get -y clean
   apt-get install docker.io -y
   
   # Disable swap - generally recommended for K8s, but otherwise enable it for other workloads
   echo "Disabling Swap"
   swapoff -a
   sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
   
   # Reset the machine-id value. This has known to cause issues with DHCP
   #
   echo "Reset Machine-ID"
   truncate -s 0 /etc/machine-id
   rm /var/lib/dbus/machine-id
   ln -s /etc/machine-id /var/lib/dbus/machine-id
   
   # Reset any existing cloud-init state
   #
   echo "Reset Cloud-Init"
   rm /etc/cloud/cloud.cfg.d/*.cfg
   cloud-init clean -s -l
   
   # cleanup shell history and shutdown for templating
   history -c
   history -w
   sudo shutdown -h now
   ```

   Mark as template

   ```sh
   govc vm.markastemplate {TEMPLATENAME}
   ```

9. Edit/update _variables.json_ and _ubuntu-##.json_ with info for local ESXi

   ```sh
   export GOVC_URL='https://username:password@vsphere-ip-or-hostname/sdk'
   export GOVC_DATACENTER=Homelab
   export GOVC_INSECURE=true
   # usage: https://github.com/vmware/govmomi/blob/master/govc/USAGE.md
   # `govc find -type n` to find networks
   # `govc find -type p` to find resource pool path
   # `govc find -type s` to find datastore
   ```

10. Build image (auto push to ESXi vSphere):

    ```sh
    packer build -var-file=variables.json ubuntu-##.json
    ```

    - If error, may have to edit _ubuntu-##.json_ with current MD5/SHAsum and iso URL

11. Delete Rancher-Packer repo
