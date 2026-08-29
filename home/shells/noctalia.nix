# Shell layer: Noctalia v5. One program providing the bar, launcher,
# notifications, lock screen, wallpaper, clipboard history, OSDs and control
# centre.
#
# v5 merges every *.toml in ~/.config/noctalia, which Nix controls and makes
# read-only, with runtime overrides in $XDG_STATE_HOME/noctalia/settings.toml.
#
# v5 is 5.0.0-beta.x and only in nixpkgs-unstable, so this layer is not
# pinned to 26.05 like the rest of the system.
{ config, pkgs, lib, inputs, ... }:

let
  c = import ../../lib/kanagawa-dragon.nix;
  cfg = config.kalliope;

  pkgsUnstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  # Noctalia's palette JSON uses Material 3 names. The mapping is specific to
  # this consumer, so it stays here rather than in lib/kanagawa-dragon.nix.
  # Omitting `light` uses the dark variant for both modes.
  #
  # Noctalia's bundled "Kanagawa" scheme is wave (mSurface #1f1f28), not
  # dragon.
  palette = {
    dark = {
      mSurface = c.dragonBlack3;
      mOnSurface = c.dragonWhite;
      mSurfaceVariant = c.dragonBlack4;
      mOnSurfaceVariant = c.dragonAsh;
      mPrimary = c.dragonBlue2;
      mOnPrimary = c.dragonBlack3;
      mSecondary = c.dragonGreen;
      mOnSecondary = c.dragonBlack3;
      mTertiary = c.dragonYellow;
      mOnTertiary = c.dragonBlack3;
      mError = c.dragonRed;
      mOnError = c.dragonBlack3;
      mOutline = c.dragonBlack5;
      mShadow = c.dragonBlack0;
      mHover = c.dragonBlue2;
      mOnHover = c.dragonBlack3;

      terminal = {
        background = c.dragonBlack3;
        foreground = c.dragonWhite;
        cursor = c.dragonWhite;
        cursorText = c.dragonBlack3;
        selectionBg = c.dragonBlack4;
        selectionFg = c.dragonWhite;
        normal = {
          black = c.ansi.black;
          red = c.ansi.red;
          green = c.ansi.green;
          yellow = c.ansi.yellow;
          blue = c.ansi.blue;
          magenta = c.ansi.magenta;
          cyan = c.ansi.cyan;
          white = c.ansi.white;
        };
        bright = {
          black = c.ansi.brightBlack;
          red = c.ansi.brightRed;
          green = c.ansi.brightGreen;
          yellow = c.ansi.brightYellow;
          blue = c.ansi.brightBlue;
          magenta = c.ansi.brightMagenta;
          cyan = c.ansi.brightCyan;
          white = c.ansi.brightWhite;
        };
      };
    };
  };

  # UNVERIFIED: the invocation form is taken from v4, which inherited it from
  # Quickshell (`noctalia-shell ipc call <target> <function>`). v5 has its own
  # client in src/ipc/cli.cpp. Check `noctalia ipc --help` on the machine.
  # The target and function names below are confirmed.
  ipc = target: fn: ''spawn "noctalia" "ipc" "call" "${target}" "${fn}";'';
in
lib.mkIf (cfg.shell == "noctalia") {

  programs.noctalia = {
    enable = true;

    # inputs.noctalia's homeModules.default sets this with mkDefault,
    # pointing at its own flake's package. A plain assignment takes priority,
    # and the module system does not evaluate the losing definition, so that
    # package is never built. This uses the cached nixpkgs-unstable build
    # instead.
    package = pkgsUnstable.noctalia;

    systemd.enable = true;

    # Runs `noctalia config validate` at build time.
    checkConfig = true;

    customPalettes.kanagawa-dragon = palette;

    settings = {
      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "kanagawa-dragon";
      };
      shell.font = "JuliaMono";
    };
  };

  # Contributed to home/niri.nix. No spawn-at-startup entries; the systemd
  # user service above starts it.
  kalliope.niri.startup = [ ];

  # Noctalia writes ~/.config/niri/noctalia.kdl from its palette, covering
  # focus-ring, border, tab-indicator, insert-hint and recent-windows. niri
  # 26.04 supports `include`.
  #
  # Do not run Noctalia's assets/templates/niri/apply.sh: it edits config.kdl
  # in place, and home-manager owns that file. This include line replaces it.
  kalliope.niri.extraConfig = ''
    include "noctalia.kdl"
  '';

  # Noctalia's included KDL supplies focus-ring.
  kalliope.niri.focusRing = false;

  # Media and brightness keys go through Noctalia rather than wpctl,
  # brightnessctl and playerctl, so its OSD overlays appear.
  kalliope.niri.binds = ''
    Mod+D { ${ipc "launcher" "toggle"} }
    Mod+Shift+C { ${ipc "launcher" "clipboard"} }
    Mod+Alt+L { ${ipc "lockScreen" "lock"} }
    Mod+Escape { ${ipc "sessionMenu" "toggle"} }
    Mod+N { ${ipc "notifications" "toggleHistory"} }
    Mod+Comma { ${ipc "settings" "toggle"} }
    Mod+Ctrl+Space { ${ipc "controlCenter" "toggle"} }

    XF86AudioRaiseVolume allow-when-locked=true { ${ipc "volume" "increase"} }
    XF86AudioLowerVolume allow-when-locked=true { ${ipc "volume" "decrease"} }
    XF86AudioMute        allow-when-locked=true { ${ipc "volume" "muteOutput"} }
    XF86AudioMicMute     allow-when-locked=true { ${ipc "volume" "muteInput"} }

    XF86MonBrightnessUp   allow-when-locked=true { ${ipc "brightness" "increase"} }
    XF86MonBrightnessDown allow-when-locked=true { ${ipc "brightness" "decrease"} }

    XF86AudioPlay allow-when-locked=true { ${ipc "media" "playPause"} }
    XF86AudioNext allow-when-locked=true { ${ipc "media" "next"} }
    XF86AudioPrev allow-when-locked=true { ${ipc "media" "previous"} }
  '';
}
