# PXE boot

- Ansible renders the configuration files for each bare metal machine (like IP, hostname...) from [templates](./roles/pxe/templates)
- Ansible syncs the configuration files to OPNsense, which has been configured as PXE server
- Hosts that are configured for PXE boot will pull the image from OPNsense and netboot/autoinstall

## Prerequisites

### Host / Management machine

- ansible
- python-netaddr
- xorriso

### OPNsense

OPNsense tftp/netboot will provide the grub efi boot file and config to hand off to a fileserver

- `os-tftp` package installed
- DHCP service on appropriate subnet [Services > DHCPv4 > `<INTERFACE>`] is configured for `network boot`.
  At minimum:

  ```txt
  Set next-server IP:        192.168.1.1  # the TFTP server, aka our OPNsense device's IP
  Set default bios filename: grubx64.efi   # or pxelinux.0 for legacy bios
  ```

### Fileserver

`tftp` is a poor way to transfer a full OS iso.
A local web or NFS server is a much better solution to deliver large files to the pxe machine.

We will use TrueNAS with NFS.

### Nodes

- Configure BIOS:
  - disable c-states
  - enable PCIe wake
  - enable wake-on-lan
  - enable boot from network
  - set boot priority for network
  - disable CSM/legacy boot

> To re/install OS from PXE, the NIC must have boot priority, otherwise the node will boot from disk

## Create PXE server

1. Configure [inventory](./inventories/hosts.yml)

2. From playbook directory, run with ansible:

   ```sh
   # # install ansible packages
   # ansible-galaxy collection install -r requirements.yml
   # compile pxe components, launch server, and boot

   # test render
   ansible-playbook -i ./inventories/hosts.yml build.yml --tags "render" --ask-become-pass

   # copy cloud-config to gist?

   # test push to opnsense
   ansible-playbook -i ./inventories/hosts.yml build.yml --tags "push"

   # full send
   ansible-playbook -i ./inventories/hosts.yml build.yml --ask-become-pass
   ```

## References

- [source - khuedoan](https://github.com/khuedoan/homelab/tree/master/metal)
- [ubuntu docs - netboot](https://ubuntu.com/server/docs/install/netboot-amd64)
- [ubuntu wiki - netboot](https://wiki.ubuntu.com/UEFI/PXE-netboot-install)
- [ubuntu pxe](https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e)
- [ubuntu pxe 2](https://gist.github.com/azhang/d8304d8dd4b4c165b67ab57ae7e1ede0)
- [onedr0p ubuntu pxe](https://github.com/onedr0p/home-ops/tree/05ba831487c9dba87be3b18fca5f2815e5de697a/server/pxe)
  and [readme](https://github.com/onedr0p/home-ops/blob/05ba831487c9dba87be3b18fca5f2815e5de697a/docs/pxe.md)
- [automated install](https://askubuntu.com/questions/1235723/automated-20-04-server-installation-using-pxe-and-live-server-image)
- [opn as pxe server](https://forum.opnsense.org/index.php?topic=25003.0)

- [python package for pxe](https://github.com/dannf/ubuntu-server-netboot)

### grub.cfg

- [Jingella grub pxe boot](https://github.com/Jingella/grub-pxe-boot/)
- [pxe boot with grub](https://github.com/rear/rear/issues/2724)
- [UEFI PXE boot with grub](https://c-nergy.be/blog/?p=13822)

### cloud-config

- [add cloud-init to iso](https://github.com/covertsh/ubuntu-autoinstall-generator/blob/main/ubuntu-autoinstall-generator.sh)
- [add cloud-init to iso 2](https://forums.fogproject.org/topic/15991/ubuntu-20-04-nfs-pxe-autoinstall-automation)

## TODO

- ensure inventory is set as static ips in DHCP
