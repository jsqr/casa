{ config, pkgs, lib, inputs, ... }:

let
  # Literal system, not pkgs.stdenv.hostPlatform: the overlay below feeds
  # pkgs, so reading it back here would recurse.
  unstable = import inputs.nixpkgs-unstable { system = "x86_64-linux"; };
in
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

  # kalliope is a laptop, so sshd shouln't pick up the phone on random networks
  services.openssh.openFirewall = false;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  # No system.autoUpgrade; kalliope is updated by hand via ~/bin/update.

  # systemd initrd unlocks the LUKS container declared in disko.nix, and is
  # required for a later TPM2 enrolment via systemd-cryptenroll.
  boot = {
    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 10;
    loader.efi.canTouchEfiVariables = true;
    # No cmdline editor. Doesn't matter while LUKS prompts for a passphrase, but
    # after TPM2 enrolment `e` would then be a root shell on decrypted data.
    loader.systemd-boot.editor = false;
    initrd.systemd.enable = true;
    supportedFilesystems = [ "btrfs" ];
    tmp.cleanOnBoot = true;

    # kernels 7.1, 7.2 improve performance under Panther Lake (kalliope)
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

  # Not the HybridSleep default: there is no swap, only zram, so hibernation
  # cannot work and the default action silently does nothing.
  services.upower.criticalPowerAction = "PowerOff";

  services.fwupd.enable = true;

  systemd.services.battery-charge-threshold = {
    description = "Limit battery charge to 80%";
    wantedBy = [ "local-fs.target" "suspend.target" "suspend-then-hibernate.target" "hibernate.target" ];
    after = [ "local-fs.target" "suspend.target" "suspend-then-hibernate.target" "hibernate.target" ];
    startLimitBurst = 5;
    startLimitIntervalSec = 1;
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      ExecStart = "${pkgs.runtimeShell} -c 'echo 80 > /sys/class/power_supply/BAT?/charge_control_end_threshold'";
    };
  };

  # ------------------------------------------------------------------
  # Backup. Snapshots locally, then sends to melpomene over the tailnet.
  # Retention is split: a short local window, with the depth kept on the
  # target. snapshot_preserve_min = latest is load-bearing — it keeps the
  # parent an incremental send needs, however long this machine is offline.
  #
  # @data is deliberately absent: it is nodatacow for Postgres, snapshotting
  # would force CoW on it, and the cluster is regenerable anyway.
  # ------------------------------------------------------------------
  services.btrbk.instances.kalliope = {
    onCalendar = "hourly";
    settings = {
      timestamp_format = "long";
      snapshot_dir = ".snapshots";
      ssh_user = "btrbk";
      ssh_identity = "/var/lib/btrbk/.ssh/id_ed25519";

      snapshot_preserve_min = "latest";
      snapshot_preserve = "48h 7d";
      target_preserve_min = "no";
      target_preserve = "30d 24w 24m";

      volume."/" = {
        subvolume = {
          "home" = { target = "ssh://melpomene/backup/kalliope/home"; };
          "pictures" = { target = "ssh://melpomene/backup/kalliope/pictures"; };
        };
      };
    };
  };

  # ExecStartPost only runs on success, so this timestamps the last run that
  # actually reached melpomene rather than the last run that merely snapshotted.
  # It lives outside /var/lib/btrbk, which tmpfiles enforces at 0750, so that
  # ~/bin/status can stat it as an ordinary user.
  systemd.services.btrbk-kalliope.serviceConfig.ExecStartPost =
    "${pkgs.coreutils}/bin/touch /var/lib/btrbk-last-success";

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
    "f /var/lib/btrbk-last-success 0644 btrbk btrbk -"
  ];

  # ------------------------------------------------------------------
  # llama.cpp — same router setup as melpomene, but on the Arc B390 iGPU
  # and localhost-only. packages.nix ships llama-cpp to every host, so the
  # overlay redirects that one attribute rather than adding a second copy:
  # it gives the service, llama-cli and llama-bench the same Vulkan build.
  # ------------------------------------------------------------------
  nixpkgs.overlays = [ (_: _: { llama-cpp = unstable.llama-cpp-vulkan; }) ];

  services.llama-cpp = {
    enable = true;

    # Router LRU cap, as on melpomene. No -ngl: --fit sizes offload to the
    # Vulkan heap, which is shared system RAM here.
    extraFlags = [ "--models-max" "2" ];

    # Preset keys are long CLI flags minus the dashes. The shared pair
    # (E4B, embeddinggemma) is in lib/llama-presets.nix; the 12B is local.
    modelsPreset = (import ../../lib/llama-presets.nix) // {
      "gemma-4-12B" = {
        hf-repo = "unsloth/gemma-4-12B-it-qat-GGUF";
        hf-file = "gemma-4-12B-it-qat-UD-Q4_K_XL.gguf";
        alias = "unsloth/gemma-4-12B-it";
        jinja = "on";
        ctx-size = "8192";
        sleep-idle-seconds = "600";
      };
    };
  };

  # The unit runs with HOME=/, so mesa gives up on its pipeline cache and
  # recompiles shaders on every model load. CacheDirectory= is writable.
  systemd.services.llama-cpp.environment.MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp";

  home-manager.users.jj = import ../../home/kalliope.nix;
}
