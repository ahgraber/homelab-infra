# Uninterruptible Power Supply (UPS)

## UPS setup

1. Plug devices into critical / noncritical outlet groups, where noncritical outlets get shut down first

## OPNsense as Network UPS Tools (NUT) Server

Refs:
<!-- markdownlint-disable MD034 -->
- https://schnerring.net/blog/configure-nut-for-opnsense-and-truenas-with-the-cyberpower-pr750ert2u-ups/
- https://forum.opnsense.org/index.php?topic=27936.0
<!-- markdownlint-enable MD034 -->

1. Install NUT plugin

2. Restart

3. Configure NUT
   1. General Settings > General Nut Settings
      - _Name_ will be used as address for all netclients
   2. General Settings > Nut Account Settings
      - _Monitor Password_ is password for `monuser` account that will be used for all netclients
   3. UPS Type > USBHID-Driver
      - [x] enable

4. Configure NAT: port forward internal traffic hitting firewall IPs port `3493` to `127.0.0.1:3493`

5. Test

   ```sh
   upsc <UPS_NAME>@<OPNSENSE_IP>:3493
   ```

## TrueNAS integration

1. Ensure NUT configured on OPNsense (acting as NUT server)

2. On TrueNAS, test with:

   ```sh
   upsc <UPS_NAME>@<OPNSENSE_IP>:3493
   ```

3. Find configuration: System Settings > Services > UPS

4. ![TrueNAS config](./images/TrueNAS%20UPS%20config.png)

5. Test that it actually shuts devices down:

   ```sh
   # from server (OPNsense)
   upsmon -c fsd
   ```

## Sample configurations

### nut.conf

```conf
MODE=netclient
```

### upsmon.conf

```conf
MONITOR PR1500RT2U@<opnsense_address>:3493 1 monuser <password> slave
# bsd
; SHUTDOWNCMD "/usr/local/etc/rc.halt"
# linux
SHUTDOWNCMD /sbin/shutdown -h +0
POWERDOWNFLAG /etc/killpower
```
