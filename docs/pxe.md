# PXE Boot

- [PXE Boot](#pxe-boot)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
    - [Host / Management machine running config via Ansible](#host--management-machine-running-config-via-ansible)
    - [OPNsense](#opnsense)
    - [Fileserver](#fileserver)
    - [Nodes](#nodes)
  - [Create PXE server](#create-pxe-server)
  - [References](#references)
    - [grub.cfg](#grubcfg)
    - [cloud-config](#cloud-config)
  - [Alternatives](#alternatives)

## Overview

- Ansible renders the configuration files for each bare metal machine (like IP, hostname...) from [templates](./roles/pxe/templates)
- Ansible syncs the configuration files to OPNsense, which has been configured as PXE server
- Hosts that are configured for PXE boot will pull the image from OPNsense and netboot/autoinstall

## Prerequisites

### Host / Management machine running config via Ansible

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
A local web- or NFS- server is a much better solution to deliver large files to the pxe machine.

We will use TrueNAS with webdav http server.

### Nodes

- Configure BIOS:
  - disable c-states
  - enable PCIe wake
  - enable wake-on-lan
  - enable boot from network
  - set boot priority for network
  - disable CSM/legacy boot

> To re/install OS from PXE, the NIC must have boot priority, otherwise the node will boot from disk
> Once the OS is PXE-installed, can set priority to local drive

## Create PXE server

1. Configure [inventory](./inventories/hosts.yaml)

2. From ansible directory, run with ansible:

   ```sh
   # # install ansible packages
   # ansible-galaxy collection install -r requirements.yaml
   # compile pxe components, launch server, and boot

   # test render (use localhost password)
   ansible-playbook -i ./inventory ./playbooks/pxeboot/build.yaml --tags "render" --ask-become-pass

   # copy cloud-config to gist?

   # test push to opnsense
   ansible-playbook -i ./inventory ./playbooks/pxeboot/build.yaml --tags "push"

   # full send
   ansible-playbook -i ./inventory ./playbooks/pxeboot/build.yaml --ask-become-pass
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
- [Boot Ubuntu providing it network config in NoCloud Datasource](https://gist.github.com/smoser/635897f845f7cb56c0a7ac3018a4f476)

### grub.cfg

- [Jingella grub pxe boot](https://github.com/Jingella/grub-pxe-boot/)
- [pxe boot with grub](https://github.com/rear/rear/issues/2724)
- [UEFI PXE boot with grub](https://c-nergy.be/blog/?p=13822)

### cloud-config

- [add cloud-init to iso](https://github.com/covertsh/ubuntu-autoinstall-generator/blob/main/ubuntu-autoinstall-generator.sh)
- [add cloud-init to iso 2](https://forums.fogproject.org/topic/15991/ubuntu-20-04-nfs-pxe-autoinstall-automation)
- [test cloud-init with multipass](https://multipass.run/)

## Alternatives

[Ubuntu/Canonical MAAS](https://maas.io) and [MaaS at home](https://ubuntu.com/blog/maas-for-the-home)
[Sidero](https://www.sidero.dev)
[Rackn Digital Rebar Provider](https://rackn.com/rebar/) and [edgelab](https://gitlab.com/rackn/edgelab)
[tinkerbell](https://tinkerbell.org/)
