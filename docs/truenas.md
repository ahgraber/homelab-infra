# TrueNAS SCALE

## TimeMachine backup

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
* https://www.truenas.com/community/threads/multi-user-time-machine-purpose.99276/#post-684995
<!-- markdownlint-enable -->

## iSCSI

See [democratic-csi/README.md](https://github.com/ahgraber/homelab-gitops-k3s/blob/main/cluster/core/democratic-csi/README.md)

## PXEboot server

See [pxe.md](pxe.md)

1. Create `pxeboot` dataset
2. Create `webdav` share for `pxeboot` dataset

## QOL Changes

* [Change timeout for session](https://github.com/lietu/truenas-tools/blob/main/truenas-scale-logout-timeout-patch.sh)
* Allow `apt` install: `chmod +x /bin/apt*`
* Install [Eternal Terminal](https://eternalterminal.dev/download/)
