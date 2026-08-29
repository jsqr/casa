{ ... }:

# Partition layout for kalliope: GPT, 1 GiB ESP, and a LUKS2 container
# holding one btrfs filesystem.
#
# WARNING: running disko against this file destroys the target disk. Check
# the device path on the machine with `lsblk -o NAME,SIZE,MODEL` before
# running it; /dev/nvme0n1 below is an assumption.

{
  disko.devices.disk.nvme = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings = {
              # Required for TRIM to reach the SSD through dm-crypt.
              allowDiscards = true;
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "nixos" "-f" ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
                "@var-log" = {
                  mountpoint = "/var/log";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
                # Postgres cluster, at the same mount point as melpomene.
                # nodatacow avoids CoW fragmentation from in-place page
                # rewrites. It must be set at mount time: new files inherit
                # NOCOW from the mount, and chattr +C only works on an empty
                # directory. nodatacow also disables compression, so no
                # compress= here.
                "@data" = {
                  mountpoint = "/data";
                  mountOptions = [ "nodatacow" "noatime" ];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
