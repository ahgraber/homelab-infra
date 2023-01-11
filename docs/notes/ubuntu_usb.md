# Make bootable USB

Note: instructions will operate from current working directory
and will extract to a directory called `iso2usb`

1. Download ISO Installer:

   ```sh
   version=20.04.4
   wget "https://releases.ubuntu.com/20.04/ubuntu-$version-live-server-amd64.iso"
   ```

2. Extract ISO using xorriso and fix permissions

   ```sh
   xorriso -osirrox on -indev "./ubuntu-${version}-live-server-amd64.iso" -extract / ./iso2usb
   chmod -R +w ./iso2usb
   ```

3. Set up local cloud-init (or see pxe setup to use webserver from pxe)

   ```sh
   mkdir -p ./iso2usb/nocloud
   touch ./iso2usb/nocloud/meta-data
   cp user-data ./iso2usb/nocloud/user-data
   ```

4. Update boot flags with cloud-init autoinstall:

   ```sh
   # Should look similar to this: initrd=/casper/initrd quiet autoinstall ds=nocloud;s=/cdrom/nocloud/ ---
   sed -i '' 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' ./iso2usb/boot/grub/grub.cfg
   sed -i '' 's|---|autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' ./iso2usb/isolinux/txt.cfg
   ```

   or, if we have a webserver hosting cloudinit images:

   ```sh
   sed -i '' 's|---|autoinstall ds="nocloud-net;seedfrom=https://nas.domain.com:8081/pxeboot/cloud-init"---|g' ./iso2usb/boot/grub/grub.cfg
   sed -i '' 's|---|autoinstall ds="nocloud-net;seedfrom=https://nas.domain.com:8081/pxeboot/cloud-init"---|g' ./iso2usb/isolinux/txt.cfg
   ```

5. Disable mandatory md5 checksum on boot:

   ```sh
   md5sum iso2usb/.disk/info >! ./iso2usb/md5sum.txt
   sed -i '' 's|iso2usb/|./|g' ./iso2usb/md5sum.txt
   ```

   <!-- markdownlint-disable -->
   > [Optional] Regenerate md5:
   >
   > ```sh
   > # find will warn 'File system loop detected' and return non-zero exit status on the 'ubuntu' symlink to '.'
   > # To avoid that, temporarily move it out of the way
   > mv iso2usb/ubuntu .
   > cd ./iso2usb; find '!' -name "md5sum.txt" '!' -path "./isolinux/*" -follow -type f -exec "$(which md5sum)" {} \; > ../md5sum.txt)
   > mv md5sum.txt ./iso2usb
   > mv ubuntu ./iso2usb
   > ```
   <!-- markdownlint-enable -->

6. Find/extract `isohdpfx.bin` from source iso

   ```sh
   # note: extracts to current working directory
   dd if="./iso/ubuntu-20.04.4-live-server-amd64.iso" bs=1 count=432 of="isohdpfx.bin"
   ```

7. Create Install ISO from extracted dir:

   ```sh
   xorriso -as mkisofs -r \
     -V Ubuntu\ custom\ amd64 \
     -o "ubuntu-$version-live-server-amd64-autoinstall.iso" \
     -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
     -boot-load-size 4 -boot-info-table \
     -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
     -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
     -isohybrid-mbr ./isohdpfx.bin  \
     iso2usb/boot iso2usb
   ```

8. Flash iso to usb drive with BalenaEtcher or equivalent

## References

<!-- markdownlint-disable -->
 - https://nekodaemon.com/2022/01/16/Unattended-Ubuntu-20-04-Server-Offline-Installation/
 - https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e
 - https://wiki.ubuntu.com/FoundationsTeam/AutomatedServerInstalls
 - https://wiki.ubuntu.com/FoundationsTeam/AutomatedServerInstalls/ConfigReference
 - https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html
 - https://discourse.ubuntu.com/t/please-test-autoinstalls-for-20-04/15250/53
 - https://gist.github.com/dbkinghorn/c236aea31d76028b2b6ccdf6d3c6f07e
<!-- markdownlint-enable -->
