{ config, pkgs, lib, inputs, ... }:

let
  unfreePkgs = import inputs.nixpkgs-unstable { inherit (pkgs) system; config.allowUnfree = true; };

  # Imperative toolchain managers (rustup, uv) manage their own state under $HOME.
  # system.autoUpgrade only bumps the rustup/uv binaries. On thalia these are
  # refreshed interactively by scripts/update.sh; melpomene is headless and
  # self-updating, so it runs the same refresh on a nightly user timer instead.
  # Each step is allowed to fail independently.
  toolchainUpdate = pkgs.writeShellScript "toolchain-update" ''
    set -u
    echo "=== rustup update ==="
    ${pkgs.rustup}/bin/rustup update || echo "rustup update failed" >&2
    echo "=== uv tool upgrade --all ==="
    ${pkgs.uv}/bin/uv tool upgrade --all || echo "uv tool upgrade failed" >&2
  '';
in
{
  imports = [ ./common.nix ];

  home.username = "jj";
  home.homeDirectory = "/home/jj";

  targets.genericLinux.enable = true;

  services.ollama.enable = true;

  home.packages = [ pkgs.code-server unfreePkgs.claude-code ];

  # NixOS-only (reads /run/current-system, systemctl), so wired here
  # rather than in common.nix alongside the other bin/ scripts.
  home.file."bin/status" = {
    source = ../scripts/status.sh;
    executable = true;
  };

  systemd.user.services.toolchain-update = {
    Unit.Description = "Update imperative toolchain managers (rustup, uv tools)";
    Service = {
      Type = "oneshot";
      ExecStart = "${toolchainUpdate}";
      # git/coreutils on PATH for any build backends uv shells out to while
      # rebuilding a tool's environment; the script itself uses absolute paths.
      Environment = [ "PATH=${lib.makeBinPath [ pkgs.rustup pkgs.uv pkgs.git pkgs.coreutils ]}" ];
    };
  };

  systemd.user.timers.toolchain-update = {
    Unit.Description = "Nightly rustup/uv tool update";
    Timer = {
      # 05:00 leaves room after system.autoUpgrade (04:00 + up to 45min jitter)
      # so the two don't run on top of each other. Persistent catches up after
      # the box has been off.
      OnCalendar = "05:00";
      RandomizedDelaySec = "30min";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [ "https://github.com" ];
    };
  };

}
