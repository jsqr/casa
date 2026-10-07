{ config, pkgs, lib, inputs, ... }:

let
  # Fast-forward the checkout as jj before the nightly rebuild. melpomene
  # bumps the lock and pushes; polyhymnia only pulls.
  casaPull = pkgs.writeShellScript "casa-pull" ''
    set -euo pipefail
    exec ${pkgs.util-linux}/bin/runuser -u jj -- ${pkgs.bash}/bin/bash -euo pipefail -c '
      cd /home/jj/jsqr/casa
      ${pkgs.git}/bin/git fetch origin
      ${pkgs.git}/bin/git merge --ff-only @{u}
    '
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/base.nix
    ./web.nix
  ];

  system.stateVersion = "26.05";

  networking.hostName = "polyhymnia";

  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    tmp.cleanOnBoot = true;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Hetzner Cloud hands out IPv4 by DHCP but not IPv6; the /64 is routed to
  # the server and the gateway is always fe80::1.
  networking.useNetworkd = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "ipv4";
    address = [ "2a01:4f9:c010:d64e::1/64" ];
    routes = [ { Gateway = "fe80::1"; } ];
  };

  # SSH over the tailnet only; the Hetzner web console is the fallback.
  services.openssh.openFirewall = false;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
  services.tailscale.openFirewall = true;

  system.autoUpgrade = {
    enable = true;
    flake = "/home/jj/jsqr/casa#polyhymnia";
    flags = [ "-L" ];
    # After melpomene's 04:00 (+45min) lock bump has been pushed.
    dates = "05:30";
    randomizedDelaySec = "30min";
    allowReboot = false;
  };
  systemd.services.nixos-upgrade.serviceConfig.ExecStartPre = "${casaPull}";

  # Root fetches the private ashokan input with a GitHub deploy key at
  # /root/.ssh/id_ed25519.
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  home-manager.users.jj = import ../../home/polyhymnia.nix;
}
