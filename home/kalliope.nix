{ config, pkgs, lib, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  c = import ../lib/kanagawa-dragon.nix;
  # foot wants RRGGBB with no prefix; the palette stores #RRGGBB.
  hex = lib.removePrefix "#";
  # programs.firefox.configPath is relative to $HOME.
  xdgConfigRel = lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome;
in
{
  imports = [
    ./common.nix
    ./niri.nix
    ./shells
  ];

  # Selects the shell layer. Both are configured; see home/shells/.
  kalliope.shell = "noctalia";

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
    pkgs.proton-pass
  ];

  # From programs.firefox, not home.packages, so the Proton Pass extension can
  # be declared. Only policies are set; they go in the wrapper's
  # distribution/policies.json. No profiles block, so Firefox keeps owning the
  # profile.
  #
  # configPath: home-manager derives its default from home.stateVersion, 24.11
  # here (home/common.nix), giving the pre-26.05 ~/.mozilla/firefox. Firefox 154
  # moved to XDG on its own, so the profile is under ~/.config.
  programs.firefox = {
    enable = true;
    configPath = "${xdgConfigRel}/mozilla/firefox";

    # normal_installed rather than force_installed: the latter also blocks
    # disabling the extension in about:addons. Installed from AMO rather than
    # pinned in flake.lock so it tracks upstream. Key is the AMO GUID.
    policies.ExtensionSettings = {
      "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
        installation_mode = "normal_installed";
        install_url =
          "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
      };
    };
  };

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

  # foot alongside ghostty: Mod+T spawns footclient, Mod+Shift+T ghostty.
  # See home/niri.nix. Settings mirror the ghostty block above.
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        font = "JuliaMono:size=9:fontfeatures=ss01:fontfeatures=zero, FiraCode Nerd Font Mono:size=9";
        term = "xterm-256color";
      };

      scrollback.lines = 10000;

      # kanagawa dragon, from lib/kanagawa-dragon.nix. Mirrors upstream's
      # extras/foot/kanagawa-dragon.ini.
      colors-dark = {
        background = hex c.bg;
        foreground = hex c.fg;

        selection-foreground = hex c.term.selectionFg;
        selection-background = hex c.term.selectionBg;

        regular0 = hex c.term.black;
        regular1 = hex c.term.red;
        regular2 = hex c.term.green;
        regular3 = hex c.term.yellow;
        regular4 = hex c.term.blue;
        regular5 = hex c.term.magenta;
        regular6 = hex c.term.cyan;
        regular7 = hex c.term.white;

        bright0 = hex c.term.brightBlack;
        bright1 = hex c.term.brightRed;
        bright2 = hex c.term.brightGreen;
        bright3 = hex c.term.brightYellow;
        bright4 = hex c.term.brightBlue;
        bright5 = hex c.term.brightMagenta;
        bright6 = hex c.term.brightCyan;
        bright7 = hex c.term.brightWhite;

        "16" = hex c.term.extended0;
        "17" = hex c.term.extended1;
      };

      # sequence = key combination, in that order.
      text-bindings."\\x1b\\x0d" = "Shift+Return";
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
