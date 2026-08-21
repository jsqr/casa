{ config, pkgs, lib, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; config.allowUnfree = true; };
in
{
  imports = [ ./common.nix ];

  home.username = "jj";
  home.homeDirectory = "/Users/jj";

  # julia-mono from unstable: nixos-26.05 is still on 0.062.
  home.packages = [ unstable.claude-code pkgs.postgresql_18 unstable.julia-mono ];

  programs.gh.enable = true;

  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      # theme = "Monokai Pro";
      # theme = "Gruvbox Dark Hard";  # hard = darker bg (#1d2021)
      theme = "Kanagawa Dragon";
      # JuliaMono has no Nerd glyphs; Fira Code (brew cask) is the fallback
      font-family = [ "JuliaMono" "FiraCode Nerd Font Mono" ];
      # ss01 = single-story g, zero = slashed zero
      font-feature = [ "ss01" "zero" ];
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
