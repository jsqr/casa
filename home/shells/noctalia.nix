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

  # v5 replaced v4's `ipc call <target> <function>` with flat `msg <verb>`
  # subcommands; `noctalia msg --help` lists them. Panel ids come from
  # `noctalia msg panel-toggle` with an unknown id, which prints the valid set.
  msg = args: ''spawn "noctalia" "msg" ${lib.concatMapStringsSep " " (a: ''"${a}"'') args};'';
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

  # niri refuses to start on an unresolvable include, and Noctalia only writes
  # noctalia.kdl once it is running -- which needs niri. Create an empty file
  # if it is absent so the first login can get far enough to break the cycle.
  # Not home.file: Noctalia must be able to write it.
  home.activation.noctaliaKdlStub = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    d="${config.xdg.configHome}/niri"
    run mkdir -p "$d"
    [ -e "$d/noctalia.kdl" ] || run touch "$d/noctalia.kdl"
  '';

  # Noctalia's included KDL supplies focus-ring.
  kalliope.niri.focusRing = false;

  # Media and brightness keys go through Noctalia rather than wpctl,
  # brightnessctl and playerctl, so its OSD overlays appear.
  kalliope.niri.binds = ''
    Mod+D { ${msg [ "panel-toggle" "launcher" ]} }
    Mod+Shift+C { ${msg [ "panel-toggle" "clipboard" ]} }
    Mod+Alt+L { ${msg [ "session" "lock" ]} }
    Mod+Escape { ${msg [ "panel-toggle" "session" ]} }
    Mod+N { ${msg [ "panel-toggle" "control-center" "notifications" ]} }
    Mod+Comma { ${msg [ "settings-toggle" ]} }
    Mod+Ctrl+Space { ${msg [ "panel-toggle" "control-center" ]} }

    XF86AudioRaiseVolume allow-when-locked=true { ${msg [ "volume-up" ]} }
    XF86AudioLowerVolume allow-when-locked=true { ${msg [ "volume-down" ]} }
    XF86AudioMute        allow-when-locked=true { ${msg [ "volume-mute" ]} }
    XF86AudioMicMute     allow-when-locked=true { ${msg [ "mic-mute" ]} }

    XF86MonBrightnessUp   allow-when-locked=true { ${msg [ "brightness-up" ]} }
    XF86MonBrightnessDown allow-when-locked=true { ${msg [ "brightness-down" ]} }

    XF86AudioPlay allow-when-locked=true { ${msg [ "media" "toggle" ]} }
    XF86AudioNext allow-when-locked=true { ${msg [ "media" "next" ]} }
    XF86AudioPrev allow-when-locked=true { ${msg [ "media" "previous" ]} }
  '';
}
