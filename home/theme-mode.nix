# A state file holds "dark" or "light". Absent means dark, which
# is how melpomene stays on piste with no writer. Writers are per host --
# Noctalia's theme_mode_changed hook on kalliope, a dark-mode-notify launchd
# agent on thalia -- and they all call the same switcher.
#
# Applications contribute to casa.themeMode.env and .reload rather than being
# named here.
{ config, pkgs, lib, ... }:

let
  cfg = config.casa.themeMode;

  modes = [ "dark" "light" ];

  # Cleared before export: a key set in one mode only would otherwise linger.
  envKeys = lib.unique
    (lib.concatMap (m: lib.attrNames (cfg.env.${m} or { })) modes);

  exportsFor = m: lib.concatStringsSep "\n"
    (lib.mapAttrsToList (k: v: "      export ${k}=${lib.escapeShellArg v}")
      (cfg.env.${m} or { }));

  switcher = pkgs.writeShellApplication {
    name = "casa-theme-mode";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      state=${lib.escapeShellArg cfg.stateFile}

      # Most authoritative first. Falling through to the state file is what
      # makes a bare invocation re-apply the current mode, as at login.
      mode=""
      case "''${1:-}" in
        dark | light) mode="$1" ;;
        "") ;;
        *)
          echo "usage: casa-theme-mode [dark|light]   (or DARKMODE=1|0)" >&2
          exit 2
          ;;
      esac

      if [ -z "$mode" ]; then
        case "''${DARKMODE:-}" in
          1) mode="dark" ;;
          0) mode="light" ;;
        esac
      fi
      ${lib.optionalString (cfg.detect != "") ''

      if [ -z "$mode" ]; then
        detected="$(
      ${cfg.detect}
        )" || detected=""
        case "$detected" in
          dark | light) mode="$detected" ;;
        esac
      fi
      ''}
      if [ -z "$mode" ] && [ -r "$state" ]; then
        mode="$(cat "$state")"
      fi

      case "$mode" in
        dark | light) ;;
        *) mode=${cfg.default} ;;
      esac
      mkdir -p "$(dirname "$state")"
      tmp="$(mktemp "$state.XXXXXX")"
      printf '%s\n' "$mode" >"$tmp"
      mv -f "$tmp" "$state"

      ${cfg.reload}
    '';
  };

in
{
  options.casa.themeMode = {
    default = lib.mkOption {
      type = lib.types.enum modes;
      default = "dark";
      description = "Mode when the state file is absent, and for anything fixed at startup.";
    };

    stateFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.stateHome}/casa/theme-mode";
      description = "Holds the current mode, one word.";
    };

    env = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { dark = { }; light = { }; };
      description = "Per-mode environment, exported from a zsh precmd.";
    };

    detect = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Shell fragment printing the mode, asked when given none.";
    };

    reload = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Shell fragment run by the switcher, $mode in scope. Guard each action:
        a tool that is not running must not fail the switch.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = switcher;
      description = "The switcher, for a host's writer to invoke.";
    };
  };

  config = {
    home.packages = [ switcher ];

    # precmd, not a login-time export: a change has to reach open shells.
    programs.zsh.initContent = ''
      casa_theme_mode_apply() {
        local f=${lib.escapeShellArg cfg.stateFile} m=${cfg.default}
        [[ -r $f ]] && m="$(<$f)"
        [[ $m == dark || $m == light ]] || m=${cfg.default}
        [[ $m == "''${casa_theme_mode_current-}" ]] && return
        casa_theme_mode_current=$m

        ${lib.optionalString (envKeys != [ ]) "unset ${lib.concatStringsSep " " envKeys}"}
        case $m in
          dark)
      ${exportsFor "dark"}
            ;;
          light)
      ${exportsFor "light"}
            ;;
        esac
      }
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd casa_theme_mode_apply
      casa_theme_mode_apply
    '';
  };
}
