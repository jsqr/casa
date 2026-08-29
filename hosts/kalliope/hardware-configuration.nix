# Placeholder. Declares the platform only, so the flake evaluates before
# the machine exists. It has no kernel modules and no filesystems, and will
# not boot.
#
# Replace with the output of, run on the machine:
#
#   nixos-generate-config --no-filesystems --root /mnt
#
# --no-filesystems because ./disko.nix declares fileSystems.*.
{ ... }:

{
  nixpkgs.hostPlatform = "x86_64-linux";
}
