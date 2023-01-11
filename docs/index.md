# Homelab infrastructure managment with Ansible and Terraform

This repo helps manage homelab infra with pxe, ansible, and/or terraform

_With inspiration from the k8s-at-home community, especially [onedr0p's cluster template](https://github.com/onedr0p/flux-cluster-template)_

## Overview

<!-- no toc -->
- [📝 Prerequisites](./1-prerequisites.md)
- [📡 Provision with Terraform](./2-terraform.md)
- [🧚 Provision with PXE](./pxe.md)
- [🤖 Manage with Ansible](./3-ansible.md)
- Infra
  - [TrueNAS SCALE](./infra/truenas.md)
  - [UPS](./infra/ups.md)
- Notes
  - [Crowdsec](./notes/crowdsec.md)
  - [Format and Mount Drives](./notes/format_and_mount.md)
  - [Bootable Ubuntu USB](./notes/ubuntu_usb.md)
