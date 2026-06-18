{ lib, ... }:

# NVMe-only disko layout for the initial install.
#
# The SATA disk (/dev/sda) is intentionally NOT declared here — it still
# holds the live /krater data when this config first runs. It gets wiped and
# reformatted as the /backup target in Phase 4 of the migration, after the
# data has been copied onto the NVMe and verified.

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
              "@krater" = {
                mountpoint = "/krater";
                mountOptions = [ "compress=zstd:3" "noatime" ];
              };
              "@data" = {
                mountpoint = "/data";
                mountOptions = [ "compress=zstd:3" "noatime" ];
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
