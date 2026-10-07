{ ... }:

{
  imports = [ ./common.nix ];

  home.username = "jj";
  home.homeDirectory = "/home/jj";

  targets.genericLinux.enable = true;

  # NixOS-only (reads /run/current-system, systemctl), so wired here
  # rather than in common.nix alongside the other bin/ scripts.
  home.file."bin/status" = {
    source = ../scripts/status.sh;
    executable = true;
  };
}
