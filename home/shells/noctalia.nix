# Shell layer: Noctalia v5. One program providing the bar, launcher,
# notifications, lock screen, wallpaper, clipboard history, OSDs and control
# centre. Contributes its compositor bits through the kalliope.niri.* options
# in ./default.nix.
#
# v5 merges every *.toml in ~/.config/noctalia, which Nix controls and makes
# read-only, with runtime overrides in $XDG_STATE_HOME/noctalia/settings.toml.
#
# v5 is 5.0.0-beta.x and only in nixpkgs-unstable, so this layer is not
# pinned to 26.05 like the rest of the system.
{ config, pkgs, lib, inputs, ... }:

let
  k = import ../../lib/kanagawa;

  pkgsUnstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  # Material 3 names, specific to this consumer. Noctalia's bundled "Kanagawa"
  # is wave/lotus, not dragon.
  paletteMode = c: {
    mSurface = c.bg;
    mOnSurface = c.fg;
    mSurfaceVariant = c.bgP1;
    mOnSurfaceVariant = c.synComment;
    mPrimary = c.synFun;
    mOnPrimary = c.bg;
    mSecondary = c.brightGreen;
    mOnSecondary = c.bg;
    mTertiary = c.synIdentifier;
    mOnTertiary = c.bg;
    mError = c.red;
    mOnError = c.bg;
    mOutline = c.bgP2;
    mShadow = c.bgM3;
    mHover = c.synFun;
    mOnHover = c.bg;

    # c.term, not the UI accents above: bright stays distinct from regular.
    terminal = {
      background = c.term.background;
      foreground = c.term.foreground;
      cursor = c.term.cursor;
      cursorText = c.term.cursorText;
      selectionBg = c.term.selectionBg;
      selectionFg = c.term.selectionFg;
      normal = {
        black = c.term.black;
        red = c.term.red;
        green = c.term.green;
        yellow = c.term.yellow;
        blue = c.term.blue;
        magenta = c.term.magenta;
        cyan = c.term.cyan;
        white = c.term.white;
      };
      bright = {
        black = c.term.brightBlack;
        red = c.term.brightRed;
        green = c.term.brightGreen;
        yellow = c.term.brightYellow;
        blue = c.term.brightBlue;
        magenta = c.term.brightMagenta;
        cyan = c.term.brightCyan;
        white = c.term.brightWhite;
      };
    };
  };

  palette = {
    dark = paletteMode k.dragon;
    light = paletteMode k.lotus;
  };

  # v5 replaced v4's `ipc call <target> <function>` with flat `msg <verb>`
  # subcommands; `noctalia msg --help` lists them. Panel ids come from
  # `noctalia msg panel-toggle` with an unknown id, which prints the valid set.
  msg = args: ''spawn "noctalia" "msg" ${lib.concatMapStringsSep " " (a: ''"${a}"'') args};'';
in
{

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

    # Misnamed now it carries both, but the runtime settings.toml names it and
    # wins, so renaming orphans the selection until it is re-picked in the GUI.
    customPalettes.kanagawa-dragon = palette;

    settings = {
      theme = {
        # Initial value only; theme-mode-toggle persists to settings.toml.
        mode = config.casa.themeMode.default;
        source = "custom";
        custom_palette = "kanagawa-dragon";

        # gtk3/gtk4 write libadwaita colours; niri fills noctalia.kdl. Not
        # foot, ghostty or emacs: each has a better native mechanism.
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [ "gtk3" "gtk4" "niri" "qt" "btop" ];
        };
      };

      # No argument: fireWithEnv unsetenv's NOCTALIA_THEME_MODE before the async
      # hook child starts, so it reads empty. See casa.themeMode.detect below.
      hooks.theme_mode_changed = lib.getExe config.casa.themeMode.package;
      shell.font = "JuliaMono";

      # Both default to empty, which means XDG_PICTURES_DIR — now the photo
      # subvolume, which neither of these belongs in.
      shell.screenshot.directory = "${config.home.homeDirectory}/Screenshots";
      wallpaper.directory = "${config.home.homeDirectory}/Wallpapers";

      # Bar widget placement. start/center/end are the three bar zones; each
      # array replaces the built-in default wholesale, so all three are
      # spelled out even where they match upstream.
      #
      # `media` (now playing) moves to the left zone, after `workspaces`,
      # rather than the head of `end` where it competed with ten status
      # widgets for space.
      bar.default = {
        start = [ "launcher" "wallpaper" "workspaces" "media" ];
        center = [ "clock" ];
        end = [
          "tray"
          "notifications"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "control-center"
          "session"
        ];
      };

      # Default max_length 220 is the cramped part; the left zone has room.
      # title_scroll accepts "none", "on_hover" or "always".
      widget.media = {
        max_length = 320.0;
        title_scroll = "on_hover";
      };
    };
  };

  # The only reliable way to ask; the hook's environment variable is racy.
  casa.themeMode.detect =
    "${lib.getExe' config.programs.noctalia.package "noctalia"} msg theme-mode-get";

  # Contributed to home/niri.nix. No spawn-at-startup entries; the systemd
  # user service above starts it.
  kalliope.niri.startup = [ ];

  # The niri template, enabled above, writes noctalia.kdl from the active
  # palette, covering focus-ring, border, tab-indicator, insert-hint and
  # recent-windows. niri 26.04 supports `include`.
  #
  # Its apply.sh wants to add this include line to config.kdl, which
  # home-manager owns read-only. In 5.1.0 it returns early when a matching
  # include is already present, so declaring it here is what keeps apply.sh
  # off that file. Re-check before bumping the noctalia input.
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
