{ config, pkgs, lib, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ./common.nix
    ./niri.nix
    ./shells
  ];

  # Selects the shell layer. Both are configured; see home/shells/.
  kalliope.shell = "alacarte";

  home.username = "jj";
  home.homeDirectory = "/home/jj";

  # home.stateVersion is inherited from common.nix at 24.11, so all three
  # hosts get the same home-manager defaults.
  #
  # No targets.genericLinux.enable; melpomene sets it, but it has no effect
  # under the home-manager NixOS module.

  # julia-mono from unstable: nixos-26.05 is still on 0.062, as on thalia.
  home.packages = [
    unstable.claude-code
    unstable.julia-mono
    pkgs.grim
    pkgs.slurp
    pkgs.wl-clipboard
    pkgs.brightnessctl
    pkgs.playerctl
    pkgs.firefox
  ];

  # thalia sets package = null because ghostty comes from Homebrew there.
  # Settings otherwise match.
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Kanagawa Dragon";
      font-family = [ "JuliaMono" "FiraCode Nerd Font Mono" ];
      font-feature = [ "ss01" "zero" ];
      keybind = "shift+enter=text:\\x1b\\r";
      shell-integration-features = "ssh-env,ssh-terminfo";
      clipboard-write = "allow";
      term = "xterm-256color";
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [ "https://github.com" ];
    };
  };

  # NixOS-only; reads /run/current-system and systemctl. Same as melpomene.
  home.file."bin/status" = {
    source = ../scripts/status.sh;
    executable = true;
  };
}
