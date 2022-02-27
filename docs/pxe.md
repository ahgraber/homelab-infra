# PXE Boot

## TrueNAS configuration

1. Enable `tftp` service
2. Configure tftp file directory
3. Ensure tftp user has permissions to file directory

## OPNsense configuration

1. Configure DHCP service to direct `tfpt` to TrueNAS FQDN and appropriate file directory

## Image configuration

## Node configuration

1. Enable boot from LAN
2. Set boot from LAN as priority 1; boot from HD as boot priority 2

## References

- [automated 20-04 installation](https://askubuntu.com/questions/1235723/automated-20-04-server-installation-using-pxe-and-live-server-image)
- [pxe boot cloud init ubuntu server](https://www.golinuxcloud.com/pxe-boot-server-cloud-init-ubuntu-20-04/)
- [multi-os pxe booting](https://eerielinux.wordpress.com/2021/02/20/multi-os-pxe-booting-from-freebsd-12-linux-illumos-and-more-pt-4-2/)

- [Ubuntu 20.04.3 autoinstall](https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e)
- [macos setup notes](https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e#gistcomment-3924672)

- [onedr0p](https://github.com/onedr0p/home-ops/tree/05ba831487c9dba87be3b18fca5f2815e5de697a/server/pxe)

## Alternatives

[Ubuntu/Canonical MAAS](https://maas.io) and [MaaS at home](https://ubuntu.com/blog/maas-for-the-home)
[Sidero](https://www.sidero.dev)
[Rackn Digital Rebar Provider](https://rackn.com/rebar/) and [edgelab](https://gitlab.com/rackn/edgelab)
[tinkerbell](https://tinkerbell.org/)
