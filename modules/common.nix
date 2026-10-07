# NixOS settings shared by the physical hosts, melpomene and kalliope.
# Everything not tied to hardware is in base.nix.
{ pkgs, ... }:

{
  imports = [ ./base.nix ];

  # ------------------------------------------------------------------
  # Hardware — both hosts are Intel.
  # ------------------------------------------------------------------
  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  environment.systemPackages = with pkgs; [
    smartmontools
    pciutils usbutils
  ];
}
