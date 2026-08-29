{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
  ];

  system.stateVersion = "26.05";

  networking.hostName = "kalliope";
  networking.domain = "jsqr.org";

  # No system.autoUpgrade; kalliope is updated by hand via ~/bin/update.

  # systemd initrd unlocks the LUKS container declared in disko.nix, and is
  # required for a later TPM2 enrolment via systemd-cryptenroll.
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.systemd.enable = true;
    supportedFilesystems = [ "btrfs" ];

    # Set explicitly for Panther Lake. nixos-hardware's Framework module
    # forces linuxPackages_latest only when the default kernel is older than
    # 6.17, and nixpkgs 26.05 defaults to 6.18, so importing that module
    # alone leaves this host on 6.18. 6.18 meets the Xe3 minimum, but 7.1
    # enables FRED by default and 7.2 improves Xe3 performance on Core Ultra
    # Series 3.
    #
    # linuxPackages_latest is an alias, so a flake update can change the
    # kernel. Pinning linuxPackages_7_2 instead fails to evaluate once 7.2 is
    # removed at EOL. Roll back by booting the previous generation.
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # 50% of 32 GB with zstd.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # No cpuFreqGovernor: power-profiles-daemon (modules/desktop.nix) manages
  # frequency scaling and the two conflict.
  powerManagement.enable = true;

  services.fwupd.enable = true;

  # ------------------------------------------------------------------
  # PostgreSQL — local development cluster. Same dataDir, version and
  # extensions as melpomene. It serves nothing over the network: no
  # enableTCPIP, no listen_addresses, no tailnet pg_hba entry and no
  # firewall port, so it is reachable over /run/postgresql and localhost
  # only.
  #
  # Per-project clusters in a devShell should use their own PGDATA and a
  # project-local socket directory to avoid colliding with this one.
  # ------------------------------------------------------------------
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    dataDir = "/data/18";
    extensions = ps: with ps; [ pgvector ];

    ensureDatabases = [ "jj" ];
    ensureUsers = [{
      name = "jj";
      ensureDBOwnership = true;
      # pgvector is not a trusted extension, so CREATE EXTENSION vector
      # requires superuser. ensureClauses is reapplied on every rebuild;
      # melpomene's initialScript only runs at cluster init.
      ensureClauses.superuser = true;
    }];
  };

  # With a non-default dataDir the unit's StateDirectory no longer creates
  # the directory, and ReadWritePaths=${dataDir} makes systemd's
  # mount-namespace setup fail (226/NAMESPACE) if it is missing. melpomene
  # needs the same rule.
  systemd.tmpfiles.rules = [
    "d /data/18 0700 postgres postgres -"
  ];

  home-manager.users.jj = import ../../home/kalliope.nix;
}
