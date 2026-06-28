{ config, pkgs, lib, inputs, ... }:

let
  unfreePkgs = import inputs.nixpkgs-unstable { inherit (pkgs) system; config.allowUnfree = true; };
in
{
  imports = [ ./common.nix ];

  home.username = "jj";
  home.homeDirectory = "/Users/jj";

  home.packages = [ unfreePkgs.claude-code pkgs.postgresql_18 ];

  programs.gh.enable = true;

  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      # theme = "Monokai Pro";
      # theme = "Gruvbox Dark Hard";  # hard = darker bg (#1d2021)
      theme = "Kanagawa Dragon";
      font-family = "FiraCode Nerd Font Mono";
      keybind = "shift+enter=text:\\x1b\\r";
      shell-integration-features = "ssh-env,ssh-terminfo";
      clipboard-write = "allow";
      term = "xterm-256color";
    };
  };

  programs.zsh.envExtra = lib.mkBefore ''
    export HOMEBREW_PREFIX=/opt/homebrew
    export HOMEBREW_CELLAR=/opt/homebrew/Cellar
    export HOMEBREW_REPOSITORY=/opt/homebrew
  '';

  programs.zsh.profileExtra = ''
    for d in /nix/var/nix/profiles/default/bin "$HOME/.nix-profile/bin"; do
      [[ -d $d ]] && PATH="$d:$PATH"
    done
    for d in /opt/homebrew/bin /opt/homebrew/sbin; do
      [[ -d $d && ":$PATH:" != *":$d:"* ]] && PATH="$PATH:$d"
    done
    export PATH
    typeset -U path
  '';
}
