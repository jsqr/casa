# Shell layer built from separate programs. The default.
#
# Every component has a home-manager module in release-26.05 and is pinned to
# the same nixpkgs as the rest of the system.
{ config, pkgs, lib, ... }:

let
  c = import ../../lib/kanagawa-dragon.nix;
  cfg = config.kalliope;
in
lib.mkIf (cfg.shell == "alacarte") {

  # nixpkgs 26.05 builds waybar 0.15 with niriSupport enabled by default, so
  # the niri/workspaces, niri/window and niri/language modules are available.
  programs.waybar = {
    enable = true;
    systemd.enable = false; # started by niri, see kalliope.niri.startup
    settings.main = {
      layer = "top";
      position = "top";
      height = 30;
      modules-left = [ "niri/workspaces" "niri/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      "niri/workspaces".format = "{icon}";
      "niri/window".max-length = 60;
      clock.format = "{:%a %d %b  %H:%M}";
      battery = {
        format = "{capacity}% {icon}";
        format-icons = [ "" "" "" "" "" ];
        states.warning = 25;
        states.critical = 10;
      };
      network = {
        format-wifi = "{essid} ";
        format-ethernet = "";
        format-disconnected = "";
      };
      pulseaudio = {
        format = "{volume}% {icon}";
        format-muted = "";
        format-icons.default = [ "" "" "" ];
      };
    };

    style = ''
      * {
        font-family: "FiraCode Nerd Font Mono", monospace;
        font-size: 12px;
      }
      window#waybar {
        background-color: ${c.bg};
        color: ${c.fg};
      }
      #workspaces button {
        color: ${c.fgDim};
        padding: 0 8px;
        background: transparent;
        border-bottom: 2px solid transparent;
      }
      #workspaces button.active {
        color: ${c.fg};
        border-bottom: 2px solid ${c.accent};
      }
      #workspaces button.urgent {
        color: ${c.urgent};
      }
      #window, #clock, #battery, #network, #pulseaudio, #tray {
        padding: 0 10px;
      }
      #battery.warning { color: ${c.warning}; }
      #battery.critical { color: ${c.urgent}; }
    '';
  };

  # Launcher
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JuliaMono:size=12";
        terminal = "${lib.getExe pkgs.ghostty} -e";
        layer = "overlay";
        width = 45;
      };
      colors = {
        background = "${lib.removePrefix "#" c.bg}ee";
        text = "${lib.removePrefix "#" c.fg}ff";
        match = "${lib.removePrefix "#" c.accent}ff";
        selection = "${lib.removePrefix "#" c.bgAlt}ff";
        selection-text = "${lib.removePrefix "#" c.fg}ff";
        selection-match = "${lib.removePrefix "#" c.accent}ff";
        border = "${lib.removePrefix "#" c.border}ff";
      };
      border.radius = 4;
    };
  };

  # Notifications. Provides its own systemd user service.
  services.mako = {
    enable = true;
    settings = {
      font = "JuliaMono 11";
      background-color = c.bg;
      text-color = c.fg;
      border-color = c.border;
      border-size = 2;
      border-radius = 4;
      default-timeout = 6000;
      "urgency=critical" = {
        border-color = c.urgent;
        default-timeout = 0;
      };
    };
  };

  # Idle and lock. swayidle also provides a systemd user service.
  programs.swaylock = {
    enable = true;
    settings = {
      color = lib.removePrefix "#" c.bg;
      ring-color = lib.removePrefix "#" c.accent;
      key-hl-color = lib.removePrefix "#" c.success;
      text-color = lib.removePrefix "#" c.fg;
      inside-color = lib.removePrefix "#" c.bgDim;
      line-color = lib.removePrefix "#" c.border;
      indicator-radius = 90;
      show-failed-attempts = true;
    };
  };

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "${lib.getExe pkgs.swaylock} -f";
      lock = "${lib.getExe pkgs.swaylock} -f";
    };
    timeouts = [
      { timeout = 300; command = "${lib.getExe pkgs.swaylock} -f"; }
      {
        timeout = 600;
        command = "${lib.getExe' pkgs.niri "niri"} msg action power-off-monitors";
      }
    ];
  };

  home.packages = [ pkgs.swaybg ];

  # Contributed to home/niri.nix.
  kalliope.niri.startup = [
    [ "waybar" ]
    [ "swaybg" "-c" c.bgDim "-m" "solid_color" ]
  ];

  kalliope.niri.binds = ''
    Mod+D { spawn "fuzzel"; }
    Mod+Alt+L { spawn "swaylock" "-f"; }

    XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; }
    XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
    XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

    XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

    XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
    XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
    XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
  '';
}
