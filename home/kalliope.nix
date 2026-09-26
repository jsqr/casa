{ config, pkgs, lib, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  k = import ../lib/kanagawa;
  # foot wants RRGGBB with no prefix; the palette stores #RRGGBB.
  hex = lib.removePrefix "#";
  # programs.firefox.configPath is relative to $HOME.
  xdgConfigRel = lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome;

  mode = config.casa.themeMode;

  # foot reads its config only at startup, so both sections are always present
  # and the switcher picks between them with a signal.
  footColors = c: {
    background = hex c.term.background;
    foreground = hex c.term.foreground;

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

  zathuraOptions = c: {
    font = "JuliaMono 10";
    selection-clipboard = "clipboard";

    default-bg = c.bg;
    default-fg = c.fg;
    statusbar-bg = c.bgP1;
    statusbar-fg = c.fg;
    inputbar-bg = c.bg;
    inputbar-fg = c.fg;
    notification-bg = c.bgP1;
    notification-fg = c.fg;
    notification-error-bg = c.bgP1;
    notification-error-fg = c.red;
    notification-warning-bg = c.bgP1;
    notification-warning-fg = c.synIdentifier;
    completion-bg = c.bgP1;
    completion-fg = c.fg;
    completion-highlight-bg = c.synFun;
    completion-highlight-fg = c.bg;
    index-bg = c.bg;
    index-fg = c.fg;
    index-active-bg = c.synFun;
    index-active-fg = c.bg;
    highlight-color = c.synIdentifier;
    highlight-active-color = c.synFun;

    # Only used when recolor is toggled with Ctrl+R; off by default, since
    # for authoring you want the document as it will print.
    recolor-lightcolor = c.bg;
    recolor-darkcolor = c.fg;
  };

  # No trailing newline: the module adds one after extraConfig.
  zathuraRc = c: lib.concatStringsSep "\n"
    (lib.mapAttrsToList (n: v: "set ${n}\t\"${toString v}\"") (zathuraOptions c));

  # No include directive and no reload, so the mode picks a config dir at launch.
  # Already-open windows keep their colours.
  zathuraCasa = pkgs.writeShellApplication {
    name = "zathura-casa";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      dir=${config.xdg.configHome}/zathura
      if [ "$(cat ${mode.stateFile} 2>/dev/null)" = light ]; then
        dir=${config.xdg.configHome}/zathura-light
      fi
      exec ${config.programs.zathura.package}/bin/zathura --config-dir "$dir" "$@"
    '';
  };
in
{
  imports = [
    ./common.nix
    ./niri.nix
    ./shells
  ];

  home.username = "jj";
  home.homeDirectory = "/home/jj";

  # home.stateVersion is inherited from common.nix at 24.11, so all three
  # hosts get the same home-manager defaults.
  #
  # No targets.genericLinux.enable; melpomene sets it, but it has no effect
  # under the home-manager NixOS module.

  home.packages = [
    unstable.claude-code
    unstable.julia-mono
    unstable.darktable
    unstable.gimp
    pkgs.grim
    pkgs.slurp
    pkgs.wl-clipboard
    pkgs.brightnessctl
    pkgs.playerctl
    pkgs.proton-pass
    # Stable, not unstable: a Zotero major version migrates zotero.sqlite in
    # place, and generation rollback does not undo that.
    pkgs.zotero
    pkgs.qobuz-player
    # GNOME Document Scanner; talks to the M426fdw over eSCL via sane-airscan.
    pkgs.simple-scan
    pkgs.signal-desktop
    zathuraCasa
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

  programs.zathura = {
    enable = true;
    # extraConfig, not options, so one renderer serves both modes.
    extraConfig = zathuraRc k.dragon;
  };

  xdg.configFile."zathura-light/zathurarc".text = zathuraRc k.lotus + "\n";

  # xdg.mimeApps names a desktop file; zathura's own runs the binary directly.
  xdg.desktopEntries.zathura-casa = {
    name = "Zathura (casa)";
    genericName = "Document Viewer";
    exec = "${lib.getExe zathuraCasa} %U";
    terminal = false;
    type = "Application";
    mimeType = [ "application/pdf" ];
    noDisplay = true;
  };

  casa.themeMode.reload = ''
    # Signalling the server carries every current and future client.
    case "$mode" in
      dark) sig=USR1 ;;
      light) sig=USR2 ;;
    esac
    ${pkgs.procps}/bin/pkill -"$sig" -x foot || true
  '';

  # The hook only fires on a change, so a session starting in the other mode
  # would stay wrong until the next toggle.
  systemd.user.services.casa-theme-mode = {
    Unit = {
      Description = "Apply the current theme mode to running applications";
      After = [ config.wayland.systemd.target "foot.service" ];
      PartOf = [ config.wayland.systemd.target ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe config.casa.themeMode.package;
    };
    Install.WantedBy = [ config.wayland.systemd.target ];
  };

  # Pins XDG_PICTURES_DIR at the photo subvolume. Without a user-dirs.dirs
  # anything asking for it falls back to the spec default ~/Pictures, which is
  # how that directory kept reappearing. Unused dirs are null, so they are
  # omitted rather than created.
  xdg.userDirs = {
    enable = true;
    # noctalia reads getenv("XDG_PICTURES_DIR"), so the session variables have
    # to be exported, not just written to user-dirs.dirs.
    setSessionVariables = true;
    pictures = "/pictures";
    download = "${config.home.homeDirectory}/Downloads";
    desktop = null;
    documents = null;
    music = null;
    projects = null;
    publicShare = null;
    templates = null;
    videos = null;
  };

  # Otherwise these come from whichever application registers first: PDFs had
  # landed on GIMP, which broke the typst and LaTeX preview loops.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "zathura-casa.desktop";
      "text/plain" = "emacsclient.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      "x-scheme-handler/zotero" = "zotero.desktop";
    };
  };

  # Mount removable media at /run/media/jj. Noctalia should display tray icon.
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto"; # icon only while a device is present
  };

  # thalia sets package = null because ghostty comes from Homebrew there.
  # Settings otherwise match.
  programs.ghostty = {
    enable = true;
    settings = {
      # theme (a light:/dark: pair) and the two theme files come from
      # home/common.nix, shared with thalia.
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
        # Which of the two colour sections a fresh server starts on. The
        # casa-theme-mode unit corrects it if the session began in the other
        # mode, and from then on the signal keeps it right.
        initial-color-theme = mode.default;
      };

      scrollback.lines = 10000;

      colors-dark = footColors k.dragon;
      colors-light = footColors k.lotus;

      # sequence = key combination, in that order.
      text-bindings."\\x1b\\x0d" = "Shift+Return";
    };
  };

  # The TUI (as of v. 0.9) seems to be re-encoding the album cover into
  # terminal graphics on every redraw, on the same task that reads the keyboard.
  programs.zsh.shellAliases.qobuz = "qobuz-player open --disable-tui-album-cover";

  # pgtk, not the default X11 build, for Wayland/Niri
  programs.emacs.package = pkgs.emacs-pgtk;

  # No colorScheme: it writes color-scheme='prefer-dark' into hm-dconf.ini and
  # reapplies it on every activation, which would revert a runtime switch.
  # Noctalia's gtk template owns that key instead -- see home/shells/noctalia.nix.
  gtk.enable = true;

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
