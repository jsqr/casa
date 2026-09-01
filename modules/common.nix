# NixOS settings shared by melpomene and kalliope.
# Boot, networking, filesystems, power and per-host services stay in
# hosts/<name>/configuration.nix.
{ config, pkgs, lib, inputs, ... }:

{
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

  # ------------------------------------------------------------------
  # Users — UID/GID are pinned to match the pre-NixOS Debian system on
  # melpomene so files on /krater and /data keep their owner without a
  # recursive chown.
  # ------------------------------------------------------------------
  users.mutableUsers = false;
  users.users.jj = {
    isNormalUser = true;
    uid = 1000;
    linger = true; # keep jj's systemd user manager running w/o login session
    description = "Johnathan Jenkins";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    hashedPassword = "$y$j9T$nPiBiBD0ZfpoRilU3WmdT.$22dY3dwc4gsFtsdeYPYpVYsFLddHSzoozdbxsXtni48"; # mkpasswd -m yescrypt
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEx4/uo8PypcHv61UXAmevG4PQyl8nJFaMNCEpnTfgd jj@jsqr.org"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPb1qa4XbT57XCJeCKLrJ/jONoa0n8JECayRt7Ci/Di+ jj@melpomene"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE0J3rdyj727+hwrrtrA5FiZBciz5B8OpLTP3Tp0rNeJ jj@kalliope"
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

  # --ssh goes in extraSetFlags: extraUpFlags only applies when authKeyFile is
  # set. Access is governed by the tailnet SSH policy, not authorizedKeys.
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraSetFlags = [ "--ssh" ];
  };

  # ------------------------------------------------------------------
  # Home Manager (system module). Each host sets home-manager.users.jj.
  # ------------------------------------------------------------------
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
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
