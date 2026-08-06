{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  # ------------------------------------------------------------------
  # Nix
  # ------------------------------------------------------------------
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "jj" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  system.autoUpgrade = {
    enable = true;
    flake = "/home/jj/jsqr/casa#melpomene";
    flags = [ "--update-input" "nixpkgs" "--commit-lock-file" "-L" ];
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };

  # ------------------------------------------------------------------
  # Boot
  # ------------------------------------------------------------------
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # ESP is mounted at /boot directly, so the
    # default efiSysMountPoint of /boot is correct — no override.
    supportedFilesystems = [ "btrfs" ];
  };

  # ------------------------------------------------------------------
  # Networking — wired ethernet only.
  # useDHCP is set to false explicitly because with networkd it
  # otherwise defaults to true and would run DHCP on top of the static
  # address declared below. Firewall is left to defaults; openssh and
  # samba both open their own ports via `openFirewall = true`.
  # ------------------------------------------------------------------
  networking = {
    hostName = "melpomene";
    domain = "jsqr.org";
    useNetworkd = true;
    useDHCP = false;
    defaultGateway = { address = "192.168.1.1"; interface = "enp86s0"; };
    nameservers = [ "192.168.1.1" "1.1.1.1" "8.8.8.8" ];
    interfaces.enp86s0.ipv4.addresses = [
      { address = "192.168.1.2"; prefixLength = 24; }
    ];
  };

  # ------------------------------------------------------------------
  # Users — pin UID/GID to match the existing Debian system so files
  # on /krater and /data keep their owner without a recursive chown.
  # ------------------------------------------------------------------
  users.mutableUsers = false;
  users.users.jj = {
    isNormalUser = true;
    uid = 1000;
    description = "Johnathan Jenkins";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    hashedPassword = "$y$j9T$nPiBiBD0ZfpoRilU3WmdT.$22dY3dwc4gsFtsdeYPYpVYsFLddHSzoozdbxsXtni48"; # mkpasswd -m yescrypt
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEx4/uo8PypcHv61UXAmevG4PQyl8nJFaMNCEpnTfgd jj@jsqr.org"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIrNADL8XrXMblYMuWEMHkYl8hf+m7SwvN3t/G9DIXH6 ShellFish@iPad-14022026"
    ];
  };
  users.groups.jj.gid = 1000;

  # Required if shell = zsh is set on a user
  programs.zsh.enable = true;

  # ------------------------------------------------------------------
  # nix-ld — install the runtime-loader ABI shim system-wide so the
  # stub-ld at /lib64/ld-linux-x86-64.so.2 is replaced with a real
  # nix-ld binary that reads NIX_LD / NIX_LD_LIBRARY_PATH from the
  # environment. Library policy (which libs each project gets) lives in
  # that project's flake.nix devShell, not here -- this enables the
  # *mechanism*, not the *libs*.
  # ------------------------------------------------------------------
  programs.nix-ld.enable = true;

  # ------------------------------------------------------------------
  # Hardware
  # ------------------------------------------------------------------
  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics.enable = true;
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ------------------------------------------------------------------
  # Security
  # ------------------------------------------------------------------
  security = {
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
    rtkit.enable = true;
  };

  # ------------------------------------------------------------------
  # Memory: zram instead of an on-disk swapfile.
  # 50% of 64 GB RAM with zstd ≈ 32 GB compressed swap, typically
  # 3-4x effective due to compression.
  # ------------------------------------------------------------------
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # ------------------------------------------------------------------
  # Services
  # ------------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # ------------------------------------------------------------------
  # PostgreSQL — cluster lives on the @data btrfs subvolume so the
  # existing btrbk hourly snapshot pipeline covers it. /data is mounted
  # nodatacow (see hardware-configuration.nix) to avoid CoW fragmentation
  # on in-place page rewrites; the module's `environment.systemPackages`
  # default exposes psql / pg_ctl / initdb / createdb / dropdb / pg_dump /
  # pg_restore on the user PATH automatically.
  # ------------------------------------------------------------------
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;

    dataDir = "/data/18";

    extraPlugins = ps: with ps; [ pgvector ];

    # Bind everywhere; firewall below restricts reachability to tailscale0.
    # listen_addresses takes IPs/hostnames, not interface names, so this
    # is the standard pattern for "tailnet-only" Postgres on NixOS.
    enableTCPIP = true;
    settings.listen_addresses = lib.mkForce "*";

    ensureDatabases = [ "jj" ];
    ensureUsers = [{
      name = "jj";
      ensureDBOwnership = true;
    }];

    # ensureUsers cannot grant SUPERUSER. initialScript runs once at
    # cluster init; if `jj` ever needs re-promoting, do it manually with
    # `ALTER ROLE jj SUPERUSER;` — rebuilds won't re-run this script.
    initialScript = pkgs.writeText "pg-init.sql" ''
      CREATE ROLE jj WITH LOGIN SUPERUSER;
    '';

    authentication = lib.mkOverride 10 ''
      # TYPE  DATABASE  USER  ADDRESS         METHOD
      local   all       all                   peer map=jjmap
      host    all       all   127.0.0.1/32    scram-sha-256
      host    all       all   ::1/128         scram-sha-256
      host    all       all   100.64.0.0/10   scram-sha-256
    '';

    # 100.64.0.0/10 is the Tailscale CGNAT range (RFC 6598).
    identMap = ''
      # MAPNAME  SYSTEM-USERNAME  PG-USERNAME
      jjmap      jj               jj
      jjmap      postgres         postgres
      jjmap      root             postgres
    '';
  };

  # The module sets `users.users.postgres.home = dataDir` but does not
  # createHome, and its unit uses ReadWritePaths=${dataDir} — which makes
  # systemd's mount-namespace setup fail (status=226/NAMESPACE) if the
  # path doesn't exist yet. tmpfiles materializes it before activation.
  #
  # /root/.gitconfig: nixos-upgrade runs as root with no SUDO_UID, so Nix's
  # libgit2 fetcher refuses the jj-owned flake repo ("repository path is not
  # owned by current user"), and --commit-lock-file additionally needs a git
  # identity to author the lock-bump commit. A store-symlinked gitconfig
  # provides both.
  systemd.tmpfiles.rules = [
    "d /data/18 0700 postgres postgres -"
    "L+ /root/.gitconfig - - - - ${pkgs.writeText "root-gitconfig" ''
      [safe]
          directory = /home/jj/jsqr/casa
      [user]
          name = melpomene autoupgrade
          email = root@melpomene.jsqr.org
    ''}"
  ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5432 ];

  # ------------------------------------------------------------------
  # llama.cpp embedding server.
  # modelsPreset is rendered to an INI file and passed via --models-preset
  # ------------------------------------------------------------------
  services.llama-cpp = {
    enable = true;

    # Router LRU cap: at most 2 of the 3 presets resident at once
    extraFlags = [ "--models-max" "2" ];

    modelsPreset = {
      "Qwen3-Embedding-8B" = {
        hf-repo = "Qwen/Qwen3-Embedding-8B-GGUF";
        hf-file = "Qwen3-Embedding-8B-Q5_K_M.gguf";
        alias = "Qwen/Qwen3-Embedding-8B";
        embedding = "true";
        pooling = "last";
        ctx-size = "4096";
      };

      # MoE chat models; 3-4B params are active per token
      # UD-Q4_K_XL is unsloth's dynamic 4-bit (important layers upcast to
      # 8/16-bit). jinja = "on" uses each model's built-in chat template.
      # sleep-idle-seconds: unload this model's weights + KV cache after 10 min idle
      "gemma-4-26B-A4B" = {
        hf-repo = "unsloth/gemma-4-26B-A4B-it-GGUF";
        hf-file = "gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf";
        alias = "unsloth/gemma-4-26B-A4B-it";
        jinja = "on";
        ctx-size = "32768";
        sleep-idle-seconds = "600";
      };

      "Qwen3.5-35B-A3B" = {
        hf-repo = "unsloth/Qwen3.5-35B-A3B-GGUF";
        hf-file = "Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf";
        alias = "unsloth/Qwen3.5-35B-A3B";
        jinja = "on";
        ctx-size = "32768";
        sleep-idle-seconds = "600";
      };
    };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "melpomene";
        "security" = "user";
        "map to guest" = "never";
      };
      krater = {
        "path" = "/krater";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "jj";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  # exim defaults to local-only delivery; add a `config = ''...''` block
  # later if you actually need outbound mail.
  services.exim.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
    };
  };

  # ------------------------------------------------------------------
  # Snapshots + backup to SATA via btrbk.
  #
  # The /backup mount uses `nofail` so the system still boots before
  # the SATA disk has been wiped and reformatted (Phase 4). Once
  # /backup is live, btrbk's hourly timer takes snapshots locally and
  # sends them to the SATA.
  # ------------------------------------------------------------------
  fileSystems."/backup" = {
    device = "/dev/disk/by-label/backup";
    fsType = "btrfs";
    options = [ "compress=zstd:3" "noatime" "nofail" "x-systemd.device-timeout=5s" ];
  };

  services.btrbk = {
    instances.local = {
      onCalendar = "hourly";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "2d";
        snapshot_preserve = "14d 8w";
        target_preserve_min = "no";
        target_preserve = "30d 24w 24m";
        snapshot_dir = ".snapshots";
        volume."/" = {
          subvolume = {
            "home"   = { target = "/backup/home"; };
            "krater" = { target = "/backup/krater"; };
            "data"   = { target = "/backup/data"; };
          };
        };
      };
    };
  };
  # btrbk should not run before /backup is mounted
  systemd.services.btrbk-local = {
    after = [ "backup.mount" ];
    requires = [ "backup.mount" ];
  };

  # ------------------------------------------------------------------
  # Home Manager (system module) — reuses your existing per-user file.
  # ------------------------------------------------------------------
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
    users.jj = import ../../home/melpomene.nix;
  };

  # ------------------------------------------------------------------
  # System packages (kept lean — most tools come via Home Manager)
  # ------------------------------------------------------------------
  # nano is enabled by default via `programs.nano.enable`, so a fallback
  # editor is always available without listing one here.
  environment.systemPackages = with pkgs; [
    curl wget git
    htop btop lsof strace ncdu
    btrfs-progs compsize
    pciutils usbutils
  ];
}
