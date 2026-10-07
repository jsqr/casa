{ ... }:

# Partition layout for polyhymnia (Hetzner Cloud, x86): GPT with a BIOS
# boot partition for GRUB, a 512 MiB ESP, and one btrfs filesystem. No
# LUKS: a passphrase would need the Hetzner web console on every reboot.
#
# WARNING: running disko against this file destroys the target disk. Check
# the device path on the machine with `lsblk -o NAME,SIZE,MODEL` before
# running it; /dev/sda below is an assumption.

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        # Hetzner Cloud x86 boots SeaBIOS; GRUB embeds its core image here.
        boot = {
          size = "1M";
          type = "EF02";
        };
        # Unused under SeaBIOS; keeps the disk bootable if the server is
        # switched to UEFI.
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
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
              # Application data (duckdb). nodatacow avoids CoW fragmentation
              # from in-place page rewrites; see kalliope's @data.
              "@srv" = {
                mountpoint = "/srv";
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
}
