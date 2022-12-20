# TrueNAS SCALE

- [TrueNAS SCALE](#truenas-scale)
  - [Specs](#specs)
  - [Setup](#setup)
    - [Prerequisites](#prerequisites)
    - [Networking](#networking)
    - [Storage Pool](#storage-pool)
      - [SMART and SCRUB tasks](#smart-and-scrub-tasks)
      - [iSCSI shares](#iscsi-shares)
      - [NFS shares](#nfs-shares)
      - [SMB share / Time Machine volume](#smb-share--time-machine-volume)
      - [Enable WebDav share to host files](#enable-webdav-share-to-host-files)
  - [Troubleshooting](#troubleshooting)
    - [SMART test controls](#smart-test-controls)
  - [QOL Changes](#qol-changes)
  - [Expanding VM Disk](#expanding-vm-disk)
    - [Useful commands](#useful-commands)

## Specs

- MOBO: Asus Pro WS X570 ACE
- CPU: Ryzen 5900x
- RAM: 32 GB
- BOOT: Samsung 970 EVO 250 GB
- NIC: Intel X520
- GPU: NVidia Titan X

## Setup

### Prerequisites

1. Create iSCSI VLANs (21, 22) on switch.  Set SFP+ port to TAGGED for LAB, iSCSI_1, iSCSI_2
2. Set up gateway on switch for vlan21 and vlan22
3. Set up default routes on switch for vlan21 and vlan22

### Networking

1. Set up basic networking for Web console on `enp8s0`: 10.2.1.1/16
2. Assuming standard 1G Ethernet `enp8s0` and Intel x520-1 10G NIC `enp4s0` ([ref](https://www.truenas.com/community/threads/how-to-setup-vlans-within-freenas-11-3.81633/)):
   - define Static Routes:
     - 10.2.0.0/16 to 10.2.0.1 (to OPNsense LAB interface)
     - 10.21.21.0/24 to 10.21.21.1 (to iSCSI gateway on 10G switch)
     - 10.22.22.0/24 to 10.22.22.1 (to iSCSI gateway on 10G switch)
   - `enp8s0`: this is the standard interface we created in step 1 above
   - `enp9s0f1`: connect to LAN as pseudo 'iPMI' interface; assign IP in LAN/MGMT subnet (or do not assign in TrueNAS)
   - `enp4s0`: do not assign IP
3. add `systemctl restart ix-netif.service` as post-init command in Data Protection > Init/Shutdown Scripts so that manual reconfig is not required every reboot (v20.12)
4. create VLAN interfaces:
   - vlan21 for iSCSI_1; assign IP in 10.21.21.0/24
   - vlan22 for iSCSI_2; assign IP in 10.22.22.0/24
<!-- 5. create Bridges
   - bridge21 for vlan21; do not assign IP
   - bridge 22 for vlan22; do not assign IP -->

### Storage Pool

1. In console, run `geom disk list` to see names/ids of all identified disks
2. Set up zpool
3. (OPTIONAL)[Set NVME ssd as L2ARC](https://blog.programster.org/zfs-add-l2arc) with **`zpool add <pool_name> cache /dev/<drive_id>`**
4. Set OPTANE as SLOG with **`zpool add <pool_name> log /dev/<drive_id>`**
   - First [Overprovision](https://www.ixsystems.com/community/threads/how-to-resize-slog-ssd.40071/#post-250692) drive] with [`disk_resize <device> <size>`](https://www.ixsystems.com/documentation/truenas/11.3-U4.1/storage.html#overprovisioning)

#### SMART and SCRUB tasks

1. [Follow instructions](https://www.servethehome.com/building-a-lab-part-3-configuring-vmware-esxi-and-truenas-core/)

#### iSCSI shares

1. Follow wizard:
   2. Select appropriate zvol; configure for VMWare
   3. For Portal, set IP addresses to addressess assigned to iSCSI vlans
   4. For Initiators, set authorized networks to 10.2.0.0/20, 10.21.21.0/24, and 10.22.22.0/24

Refs:
<!-- markdownlint-disable MD034 -->
- https://www.servethehome.com/building-a-lab-part-3-configuring-vmware-esxi-and-truenas-core/
   [democratic-csi/README.md](https://github.com/ahgraber/homelab-gitops-k3s/blob/main/cluster/core/democratic-csi/README.md)
<!-- markdownlint-enable -->

#### NFS shares

1. Create Dataset in Storage for appropriate pool
2. Create share in Shares > NFS
   1. Ensure mapall user and mapall group are `root`
   2. Ensure permissions are allowed for internal networks

#### SMB share / Time Machine volume

1. Create `timemachine` user and group
2. Create dataset for share
3. Grant "timemachine" group _full control_ of timemachine dataset through the ACL editor
   1. `View Permissions`
   2. Update owner to `timemachine`
   3. `Set ACL` -> Use ACL Preset `POSIX - Restricted`
4. Create `SMB` share pointing to `timemachine` dataset; set as `multi-user time machine` share
5. Restart SMB server

Refs:
<!-- markdownlint-disable MD034 -->
- https://www.truenas.com/community/threads/multi-user-time-machine-purpose.99276/#post-684995
- https://www.reddit.com/r/MacOS/comments/lh0yjc/configure_a_truenas_core_share_as_a_time_machine/
<!-- markdownlint-enable -->

#### Enable WebDav share to host files

> PXEboot server
> See [pxe.md](pxe.md)
>
> 1. Create `pxeboot` dataset
> 2. Create `webdav` share for `pxeboot` dataset

## Troubleshooting

[HD troubleshooting](https://www.truenas.com/community/resources/hard-drive-troubleshooting-guide-all-versions-of-freenas.17/)

### SMART test controls

Assuming drive named 'sdb'
`smartctl -a /dev/sdb` (show all smart attributes)
`smartctl -t short /dev/sdb` (perform short smart check)
`smartctl -t long /dev/sdb` (perform long smart check)
`smartctl -c /dev/sdb` (show how long tests would take, not entirely accurate)
`smartctl -l selftest /dev/sdb` (show only test results versus smartctl -a which shows everything)
`smartctl -X /dev/sdb` (stops test in progress.)

_Hint: if results are too long to scroll, append `| more` to the end of the command to paginate_

Here's a loop to keep the drive spun up if you use a USB dock that puts the drive to sleep after a period of time.
Use Ctrl-C to break. (not necessarily FreeNAS related)

```sh
while true; do clear; smartctl -l selftest /dev/sdb; sleep 300; done
```

Read multiple smart reports using "save_smartctl.sh":

```sh
#!/bin/bash
### call script with "save_smartctl.sh /path/to/outfile"

# Declare a string array with type
declare -a DiskArray=("sda" "sdb" "sdc" "sdd" "sde" "sdf" "sdg" "sdh" "sdi" "skj" "sdk" "sdl" "sdm")

# Read the array values with space
for val in "${DiskArray[@]}"; do
  smartctl -a /dev/${val} >> $1
done
```

## QOL Changes

- [Change timeout for session](https://github.com/lietu/truenas-tools/blob/main/truenas-scale-logout-timeout-patch.sh)
- Allow `apt` install: `chmod +x /bin/apt*`
- Install [Eternal Terminal](https://eternalterminal.dev/download/)

## Expanding VM Disk

If you have a Linux VM, which uses the LLVM filesystem, you can easily increase the disk space available to the VM.

[Linux Logical Volume Manager](https://packetpushers.net/ubuntu-extend-your-default-lvm-space/) allows you to have
logical volumes (LV) on top of logical volume groups (VG) on top of physical volumes (PV) (ie partitions).

This is conceptually similar to zvols on pools on vdevs in zfs.

**NOTE:** These commands may require root or 'sudo' access

### Useful commands

```sh
pvs # list physical volumes
lvs # list logical volumes
lvdisplay # logical volume display
pvdisplay # physical volume display
df # disk free space
```

1. Get current status

   ```sh
   df -h  # get human-readable disks
   lvs  # view logical volumes
   pvs  # view physical volumes
   ```

   > In this example, we assume the `ubuntu-lv` LV is on the `ubuntu-vg` VG is on the PV `/dev/sda3`
   > (that's partition 3 of device sda)

2. Shutdown the VM.

3. Edit the ZVOL in TrueNAS to change the size.

4. Restart the VM.

5. In the VM, run `parted` with the device id, repair the GPT information and resize the partition, as per below.

   ```sh
   parted /dev/sda

   ###   in 'parted'   ###
   # show partitions
   print

   # parted will offer to fix the GPT. Run fix with
   f

   # resize the partition (we use 3 because '/dev/sda3')
   resizepart 3 100%

      # exit 'parted'
   ```

6. Now that the partition table has been resized, we have to resize the physical volume

   ```sh
   pvdisplay # get current status
   pvresize /dev/sda3 # resize
   pvdisplay # check work
   ```

7. Use 'lvextend' to resize the LV and resize the the filesystem over the resized Physical Volume.

   ```sh
   lvextend --resizefs ubuntu-vg/ubuntu-lv /dev/sda3
   ```

8. Finally... you can check the freespace again.

   ```sh
   df -h
   ```
