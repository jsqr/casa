{ config, pkgs, lib, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; config.allowUnfree = true; };

  # The NixOS hosts get this INI from services.llama-cpp; there is no
  # home-manager module, so render it with the same generator.
  llamaPresets = pkgs.writeText "llama-models.ini"
    (lib.generators.toINI { } (import ../lib/llama-presets.nix));
in
{
  imports = [ ./common.nix ];

  home.username = "jj";
  home.homeDirectory = "/Users/jj";

  # julia-mono from unstable: nixos-26.05 is still on 0.062.
  home.packages = [ unstable.claude-code pkgs.postgresql_18 unstable.julia-mono ];

  programs.gh.enable = true;

  # llama-server in router mode, matching the two NixOS hosts: same model
  # ids at 127.0.0.1:8080, so scripts/ask.py --local works here too.
  # pkgs.llama-cpp is the Metal build, already installed via packages.nix.
  launchd.agents.llama-cpp = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.llama-cpp}/bin/llama-server"
        "--host"
        "127.0.0.1"
        "--port"
        "8080"
        "--models-preset"
        "${llamaPresets}"
        "--models-max"
        "2"
      ];
      EnvironmentVariables.LLAMA_CACHE =
        "${config.home.homeDirectory}/Library/Caches/llama.cpp";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/llama-cpp.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/llama-cpp.log";
    };
  };

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
