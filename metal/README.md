# Bare-metal

- Ansible renders the configuration file for each bare metal machine (like IP, hostname...)
  and the PXE server from [templates](./roles/pxe_server/templates)
- The tools container creates sibling containers to build a PXE server
  (includes DHCP, TFTP and HTTP server)
- Ansible [wake the machines up](./roles/wake/tasks/main.yml) using Wake on LAN
- The machine start the boot process, the OS get installed (through PXE server)
  and the machine reboots to the new operating system
- Ansible build a Kubernetes cluster based on k3s

## Current State

1. Nodes may require edits to bios:
    - disable c-states
    - enable PCIe wake
    - enable wake-on-lan
    - set boot priority for network
    - disable CSM/legacy boot
2. OPNsense // LAB dhcp4 options
    - enable netboot
    - set VM address as server IP
    - set `grubx64.efi` as default bios filename

Sticking points:

1. `dhcpd.conf.j2` does not render properly.  Ultimate `dhcpd.conf` should not
   have ansible variables {{ varname }} but actual ip addresses / netmasks / etc
    - this is ok, because we're using OPNsense to provide these options
2. `grub.cfg.j2` is currently set up for rocky linux, not Ubuntu.  Need to figure out how to set up for cloud-init

## Prerequisites

### Host / Management machine

- ansible
- docker
- docker-compose
- helm
- kubectl / kubernetes
- kustomize
- python-netaddr
- xorriso

### Nodes

- Netboot enabled
- WakeOnLan enabled

## Create PXE server

```sh
# install ansible packages
ansible-galaxy collection install -r requirements.yml
# ensure docker is running
ansible-playbook docker.yml --ask-become-pass
# compile pxe components, launch server, and boot
ansible-playbook -i ./inventories/prod.yml boot.yml --ask-become-pass
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
