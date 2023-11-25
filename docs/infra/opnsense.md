# OPNsense

## VLANs

0. LAN
1. HOME
2. LAB
3. IOT

## DNS

Unbound is used as forwarding DNS resolver.
AdGuard Home is used for adblocking on HOME and IOT VLANs.

### Unbound

> Critical settings listed below.  
> If a setting is not mentioned, it does not necessarily mean the setting is disabled/ignored; Try with system defaults.

<!-- markdownlint-disable MD033 -->
| Sidebar | Setting | Value |
| :--- | :--- | :--- |
| General | Enabled | [x] |
| General | Port | 53 |
| General | Register DHCP Leases | [x] |
| General | Register DHCP Static Mappings | [x] |
| Advanced | Private Domains | <private domains> |
| Access Lists | Access Control List | RFC1918 alias |
| Query Forwarding | Custom Forwarding | _direct <external_domain> to <k8s_gateway_ip>_ |
| DNS over TLS | Custom Forwarding | Address: 9.9.9.9 <br>Port: 853 <br>Hostname: dns.quad9.net |
| DNS over TLS | Custom Forwarding | Address: 149.112.112.112 <br>Port: 853 <br>Hostname: dns.quad9.net |
| DNS over TLS | Custom Forwarding | Address: 2620:fe::fe <br>Port: 853 <br>Hostname: dns.quad9.net |
| DNS over TLS | Custom Forwarding | Address: 2620:fe::9 <br>Port: 853 <br>Hostname: dns.quad9.net |
<!-- markdownlint-enable -->

Configure each VLAN/subnet to use Unbound by setting the subnet IP address as the DNS server in DHCP services configuration

### AdGuard Home

[Ref](https://0x2142.com/how-to-set-up-adguard-on-opnsense/)

1. Add `mimugmail` repo

   ```sh
   # add repo
   fetch -o /usr/local/etc/pkg/repos/mimugmail.conf https://www.routerperformance.net/mimugmail.conf
   # update pkg list
   pkg update
   ```

2. Install `os-adguardhome-maxit` package from OPNsense GUI: System > Firmware > Packages

3. Enable AdGuard Home service in OPNsense GUI: Services > Adguardhome > General

4. Configure AdGuard Home.  Navigate to <OPNSENSE_IP>:3000

   > IMPORTANT!  Configure DNS service to be available on port `53530` (not `53`) so it does not collide with Unbound!

   <!-- markdownlint-disable MD033 -->
   | Settings Menu | Setting | Value |
   | :--- | :--- | :--- |
   | DNS Settings | Upstream DNS servers | 127.0.0.1:53 (OPNsense Unbound) |
   | DNS Settings | Bootstrap DNS servers | 127.0.0.1:53 (OPNsense Unbound) |
   | DNS Settings | Private reverse DNS servers | 127.0.0.1:53 (OPNsense Unbound) <br>10.2.118.2 (k8s_gateway IP) |
   | DNS Settings | Use private reverse DNS resolvers  | [x] |
   | DNS Settings | Enable reverse resolving of client IP addresses | [x] |
   | Encryption Settings | Enable Encryption | [x] |
   | Encryption Settings | Server Name | <OPNsense FQDN> |
   | Encryption Settings | Redirect to HTTPS Automatically | [x] |
   | Encryption Settings | HTTPS Port | 44353 |
   | Encryption Settings | DNS-over-TLS Port | 853 |
   | Encryption Settings | DNS-over-QUIC Port | 784 |
   | Encryption Settings | Certificates path | /var/etc/acme-client/home/<ACME cert dir>/fullchain.cer |
   | Encryption Settings | Private key path | /var/etc/acme-client/home/<ACME cert dir>/<domain>.key |
   <!-- markdownlint-enable -->

5. Add filter lists (see [filterlists.com](https://filterlists.com/))

### DNS Redirects with NAT

In order to force devices to use AdGuard Home for blocking, we can intercept and redirect DNS queries with NAT port forwarding.

<!-- markdownlint-disable MD033 -->
| Interface | Proto | Src Address | Src Ports | Dst Address | Dst Ports | NAT IP | NAT Ports | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **No Redirect** <br>All Interfaces | TCP/UDP | This Firewall | * | * | 53 (DNS) |  | * | NAT/DNS: Do not redirect DNS for OPNsense |
| Home | TCP/UDP | ! This Firewall | * | ! HOSTS_k8s_gateway | 53 (DNS) | 10.1.0.1 | 53530 (Adguard Home) | NAT/DNS: Redirect DNS to Adguard (HOME) |
| IoT | TCP/UDP | ! This Firewall | * | ! HOSTS_k8s_gateway | 53 (DNS) | 10.3.0.1 | 53530 (Adguard Home) | NAT/DNS: Redirect DNS to Adguard (IoT) |
<!-- markdownlint-enable -->
