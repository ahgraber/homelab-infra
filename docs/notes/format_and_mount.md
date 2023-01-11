# Format and mount new disk

Ref: <https://techguides.yt/guides/how-to-partition-format-and-auto-mount-disk-on-ubuntu-20-04/>

## Steps

1. Get disk identifiers

   ```sh
   sudo fdisk -l
   ```

2. Wipe target disk

   ```sh
   # enter 'gdisk' for disk '/dev/sda'
   sudo gdisk /dev/sda
   # choose delete operation
   d  # delete
   1  # partition 1
   d  # continue
   w  # write / execute the operation to the disk
   ```

3. Create new partition table

   ```sh
   # enter 'gdisk' for disk '/dev/sda'
   sudo gdisk /dev/sda
   n # create new partition
   1 # partition 1
   <enter> <enter> <enter> # accept defaults
   w # write/execute operation to disk
   ```

4. Format the disk

   ```sh
   sudo mkfs.ext4 /dev/sda1
   ```

5. Get disk identifiers

   ```sh
   sudo blkid
   ```

6. Edit `/etc/fstab` with UUID of disk and desired mount point

   ```sh
   sudo nano /etc/fstab
   ...
   /dev/disk/by-uuid/<UUID> /mnt/<MOUNTPOINT> ext4 defaults 0 0
   ```

7. Create mount location

   ```sh
   sudo mkdir /mnt/<MOUNTPOINT>
   ```

8. Mount the drive

   ```sh
   sudo mount -a
   ```

9. Check your work

   ```sh
   sudo fdisk -l
   ls /mnt/<MOUNTPOINT>
   ```
