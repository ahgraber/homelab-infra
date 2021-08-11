# VM Templates with Packer

1. [Install packer](https://learn.hashicorp.com/tutorials/packer/getting-started-install)

2. Clone/download packer for ESXi repo:

   ```sh
   git clone https://github.com/David-VTUK/Rancher-Packer
   ```

3. Edit/update _variables.json_ and _ubuntu-##.json_ with info for local ESXi

   - Consider editing `Rancher-Packer/vSphere/ubuntu_2004/customisation_scripts/script-cloudinit-guestinfo.sh` to add fix for missing NIC connection (Ref [1](https://github.com/vmware/open-vm-tools/issues/240#issuecomment-395652692), [2](https://github.com/hashicorp/terraform-provider-vsphere/issues/388), [3](https://github.com/hashicorp/terraform-provider-vsphere/issues/951))

     ```sh
     # Add fix for missing NIC connection
     #
     cat >> /lib/systemd/system/open-vm-tools.service << EOF
     After=dbus.service
     EOF
     ```

     ```sh
     # Add fix for missing NIC connection
     #
     sed -i '/^\n[Service]/i After=dbus.service/' /lib/systemd/system/open-vm-tools.service
     ```

   - [GOVC](https://github.com/vmware/govmomi/tree/master/govc) can help identify names

     ```sh
     export GOVC_URL='https://username:password@vsphere-ip-or-hostname/sdk'
     export GOVC_DATACENTER=Homelab
     export GOVC_INSECURE=true
     # usage: https://github.com/vmware/govmomi/blob/master/govc/USAGE.md
     # `govc find -type n` to find networks
     # `govc find -type p` to find resource pool path
     # `govc find -type s` to find datastore
     ```

4. Build image (auto push to ESXi vSphere):

   ```sh
   packer build -var-file=variables.json ubuntu-{VERSION}.json
   ```

   - If error, may have to edit _ubuntu-##.json_ with current MD5/SHAsum and iso URL

5. Delete Rancher-Packer repo

## VM Setup (generic)

1. Deploy VM from packerbuilt template_cloudinit
<!-- 2. Configure networking from dhcp to static ip -->
2. Use `copy_to_host.sh` to copy utility scripts to vm
3. Add new user, remove packerbuilt user
4. Run setup scripts
5. Install docker & docker-compose

   1. Add user to docker group: `sudo usermod -a -G docker $USER`
   2. Start docker

   ```sh
   sudo systemctl enable docker # Auto-start on boot
   sudo systemctl start docker  # Start right now
   ```

6. Add ssh keys to host: from other admin devices we want to ahve access, run

   ```sh
   ssh-copy-id -i ~/.ssh/id_rsa.pub <user>@<new_vm_ip>
   ```

### cloud-init / cloud-config references:

- https://cloudinit.readthedocs.io/en/latest/topics/examples.html
- https://stackoverflow.com/questions/6475374/how-do-i-make-cloud-init-startup-scripts-run-every-time-my-ec2-instance-boots
- https://github.com/vmware/cloud-init-vmware-guestinfo
- https://blah.cloud/infrastructure/using-cloud-init-for-vm-templating-on-vsphere/
