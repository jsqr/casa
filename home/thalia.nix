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
    # Prepend (not append) so Homebrew beats /usr/bin, which macOS's
    # path_helper front-loads via /etc/zprofile before this runs.
    # Order: Nix ends up first, then Homebrew, then system paths.
    for d in /opt/homebrew/sbin /opt/homebrew/bin; do
      [[ -d $d ]] && PATH="$d:$PATH"
    done
    for d in "$HOME/.nix-profile/bin" /nix/var/nix/profiles/default/bin; do
      [[ -d $d ]] && PATH="$d:$PATH"
    done
    export PATH
    typeset -U path
  '';
}
