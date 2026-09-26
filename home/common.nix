{ config, pkgs, lib, inputs, ... }:

let
  k = import ../lib/kanagawa;

  # role names come from lib/kanagawa, which takes them from upstream
  variant = { dark = k.dragon; light = k.lotus; };
  themeName = { dark = "Kanagawa Dragon"; light = "Kanagawa Lotus"; };
  featureName = { dark = "kanagawa-dragon"; light = "kanagawa-lotus"; };

  yamlFormat = pkgs.formats.yaml { };
  tomlFormat = pkgs.formats.toml { };

  roleStrings = lib.filterAttrs (_: v: lib.isString v);

  # Two formats can't reference a palette: bat's tmTheme and Julia's startup.jl.
  fillTemplate = src: subs:
    let
      filled = builtins.replaceStrings
        (map (n: "@${n}@") (builtins.attrNames subs))
        (builtins.attrValues subs)
        (builtins.readFile src);
      unfilled = lib.filter (l: builtins.match ".*@[a-zA-Z0-9]+@.*" l != null)
        (lib.splitString "\n" filled);
    in
    lib.throwIf (unfilled != [ ])
      "${builtins.baseNameOf src}: unfilled placeholders in ${toString unfilled}"
      filled;

  # darkSynComment, lightBg, ...; `f` adapts the value to the format.
  prefixed = prefix: f: c: lib.mapAttrs'
    (n: v: lib.nameValuePair
      (prefix + lib.toUpper (builtins.substring 0 1 n)
        + builtins.substring 1 (builtins.stringLength n) n)
      (f v))
    (roleStrings c);

  batTheme = mode: fillTemplate ../dotfiles/bat/kanagawa.tmTheme.in
    (roleStrings variant.${mode} // {
      themeName = themeName.${mode};
      themeClass = "theme.kanagawa.${if mode == "dark" then "dragon" else "lotus"}";
      # syntect keys its theme cache on the uuid, so the two must differ.
      uuid = if mode == "dark"
        then "a9c43be948c5cabd56ef2bacffb77cdaa5ee"
        else "b1d5cf0a37e6ab4ce8fa1cbdffa88de6b71f";
    });

  # ---- per-application colour, one function per app ------------------
  # Roles are chosen so the dark rendering is identical to what we had before
  # the role layer existed. Blame upstream for weird naming.

  fzfColors = c: {
    # bg/gutter = -1 keeps popups transparent to the terminal background.
    "fg" = c.fg;
    "bg" = "-1";
    "hl" = c.red;
    "fg+" = c.fg;
    "bg+" = c.bgP1;
    "hl+" = c.red;
    "info" = c.synString;
    "border" = c.nontext;
    "prompt" = c.synFun;
    "pointer" = c.red;
    "marker" = c.brightGreen;
    "spinner" = c.extendColor1;
    "header" = c.synKeyword;
    "gutter" = "-1";
  };
  fzfOpts = c: lib.concatStringsSep " "
    (lib.mapAttrsToList (n: v: "--color=${n}:${v}") (fzfColors c));

  atuinThemeName = { dark = "kanagawa-dragon"; light = "kanagawa-lotus"; };
  atuinTheme = mode:
    let c = variant.${mode}; in
    {
      theme.name = atuinThemeName.${mode};
      colors = {
        Base = c.fg;
        Title = c.red;
        Important = c.synConstant;
        Guidance = c.synFun;
        Annotation = c.synComment;
        AlertInfo = c.synString;
        AlertWarn = c.synIdentifier;
        AlertError = c.red;
      };
    };
  atuinSettings = mode: {
    auto_sync = false;
    update_check = false;
    style = "compact";
    inline_height = 20;
    keymap_mode = "emacs";
    filter_mode = "global";
    filter_mode_shell_up_key_binding = "session";
    theme.name = atuinThemeName.${mode};
  };

  # Omitted keys fall back to eza's defaults. The git columns use syntax roles,
  # not vcs-*, so the dark rendering is unchanged.
  ezaTheme = c: {
    filekinds = {
      normal.foreground = c.fg;
      directory.foreground = c.synFun;
      symlink.foreground = c.synType;
      pipe.foreground = c.synComment;
      block_device.foreground = c.synConstant;
      char_device.foreground = c.synConstant;
      socket.foreground = c.synComment;
      special.foreground = c.synNumber;
      executable.foreground = c.brightGreen;
      mount_point.foreground = c.synFun;
    };
    perms = {
      user_read.foreground = c.fg;
      user_write.foreground = c.synIdentifier;
      user_execute_file.foreground = c.brightGreen;
      user_execute_other.foreground = c.brightGreen;
      group_read.foreground = c.synParameter;
      group_write.foreground = c.synIdentifier;
      group_execute.foreground = c.brightGreen;
      other_read.foreground = c.synComment;
      other_write.foreground = c.synIdentifier;
      other_execute.foreground = c.brightGreen;
      special_user_file.foreground = c.synNumber;
      special_other.foreground = c.synComment;
      attribute.foreground = c.synComment;
    };
    size = {
      major.foreground = c.fg;
      minor.foreground = c.synType;
      number_byte.foreground = c.fg;
      number_kilo.foreground = c.fg;
      number_mega.foreground = c.synFun;
      number_giga.foreground = c.synNumber;
      number_huge.foreground = c.synNumber;
      unit_byte.foreground = c.synComment;
      unit_kilo.foreground = c.synFun;
      unit_mega.foreground = c.synFun;
      unit_giga.foreground = c.synNumber;
      unit_huge.foreground = c.synIdentifier;
    };
    users = {
      user_you.foreground = c.fg;
      user_root.foreground = c.red;
      user_other.foreground = c.synNumber;
      group_yours.foreground = c.synParameter;
      group_other.foreground = c.synComment;
      group_root.foreground = c.red;
    };
    links = {
      normal.foreground = c.synType;
      multi_link_file.foreground = c.synIdentifier;
    };
    git = {
      new.foreground = c.brightGreen;
      modified.foreground = c.synIdentifier;
      deleted.foreground = c.red;
      renamed.foreground = c.synType;
      typechange.foreground = c.synNumber;
      ignored.foreground = c.synComment;
      conflicted.foreground = c.red;
    };
    git_repo = {
      branch_main.foreground = c.fg;
      branch_other.foreground = c.synNumber;
      git_clean.foreground = c.brightGreen;
      git_dirty.foreground = c.red;
    };
    punctuation.foreground = c.nontext;
    date.foreground = c.synString;
    inode.foreground = c.synComment;
    header.foreground = c.synParameter;
  };

  # A delta feature per mode, selected by DELTA_FEATURES from the zsh precmd.
  deltaFeature = mode:
    let c = variant.${mode}; in
    {
      syntax-theme = themeName.${mode};

      # Only tint the background, so highlighted text stays legible. diffText is
      # upstream's within-line emphasis for both directions.
      minus-style = ''syntax "${c.diffDelete}"'';
      minus-non-emph-style = ''syntax "${c.diffDelete}"'';
      minus-emph-style = ''syntax "${c.diffText}"'';
      minus-empty-line-marker-style = ''normal "${c.diffDelete}"'';

      plus-style = ''syntax "${c.diffAdd}"'';
      plus-non-emph-style = ''syntax "${c.diffAdd}"'';
      plus-emph-style = ''syntax "${c.diffText}"'';
      plus-empty-line-marker-style = ''normal "${c.diffAdd}"'';

      line-numbers-minus-style = c.red;
      line-numbers-plus-style = c.brightGreen;
      line-numbers-zero-style = c.nontext;
      line-numbers-left-style = c.nontext;
      line-numbers-right-style = c.nontext;
      hunk-header-decoration-style = "${c.nontext} box";
      hunk-header-file-style = c.synFun;
      hunk-header-line-number-style = c.synIdentifier;
      file-style = "${c.fg} bold";
      file-decoration-style = "${c.nontext} ul";
    };

  # Server-global, so re-sourcing one file covers every session.
  tmuxColors = c: ''
    set -g pane-border-style "fg=${c.bgP2}"
    set -g pane-active-border-style "fg=${c.red},bold"

    set -g status-style "bg=${c.bg},fg=${c.synParameter}"
    set -g status-left "#[fg=${c.red},bold] #S "
    set -g status-right "#[fg=${c.synParameter}] %Y-%m-%d %H:%M "
    setw -g window-status-current-style "fg=${c.red},bold"
  '';

  # Generated, not ghostty's own Kanagawa builtins: those differ from foot in
  # the selection pair and carry no 16/17.
  ghosttyTheme = c: ''
    palette = 0=${c.term.black}
    palette = 1=${c.term.red}
    palette = 2=${c.term.green}
    palette = 3=${c.term.yellow}
    palette = 4=${c.term.blue}
    palette = 5=${c.term.magenta}
    palette = 6=${c.term.cyan}
    palette = 7=${c.term.white}
    palette = 8=${c.term.brightBlack}
    palette = 9=${c.term.brightRed}
    palette = 10=${c.term.brightGreen}
    palette = 11=${c.term.brightYellow}
    palette = 12=${c.term.brightBlue}
    palette = 13=${c.term.brightMagenta}
    palette = 14=${c.term.brightCyan}
    palette = 15=${c.term.brightWhite}
    palette = 16=${c.term.extended0}
    palette = 17=${c.term.extended1}
    background = ${c.term.background}
    foreground = ${c.term.foreground}
    cursor-color = ${c.term.cursor}
    cursor-text = ${c.term.cursorText}
    selection-background = ${c.term.selectionBg}
    selection-foreground = ${c.term.selectionFg}
  '';

  # Both variants in one file, so a REPL can pick at startup.
  juliaStartup = fillTemplate ../dotfiles/julia/startup.jl.in (
    prefixed "dark" (lib.removePrefix "#") k.dragon
    // prefixed "light" (lib.removePrefix "#") k.lotus
    // {
      stateFile = config.casa.themeMode.stateFile;
      defaultMode = config.casa.themeMode.default;
    });

  # Read by jj/theme-mode in dotfiles/emacs.
  emacsFaces = c: ''(
      (tab-line              "${c.bgM3}" "${c.special}")
      (tab-line-tab          "${c.bg}"   "${c.fg}")
      (tab-line-tab-current  "${c.bg}"   "${c.fg}")
      (tab-line-tab-inactive "${c.bgM3}" "${c.special}")
      (tab-line-highlight    "${c.bgP1}" "${c.fg}"))'';

  emacsKanagawa = pkgs.writeText "casa-kanagawa.el" ''
    ;;; casa-kanagawa.el --- kanagawa data for both variants  -*- lexical-binding: t; -*-
    ;;; Commentary:
    ;; Generated by home/common.nix from lib/kanagawa. Carries the mode contract
    ;; and the face values kanagawa-themes leaves unset. Do not edit.
    ;;; Code:

    (defconst casa-kanagawa-state-file "${config.casa.themeMode.stateFile}")
    (defconst casa-kanagawa-default-mode '${config.casa.themeMode.default})

    (defconst casa-kanagawa-themes
      '((dark . kanagawa-dragon)
        (light . kanagawa-lotus)))

    ;; (face background foreground)
    (defconst casa-kanagawa-faces
      '((dark . ${emacsFaces k.dragon})
        (light . ${emacsFaces k.lotus})))

    (defconst casa-kanagawa-inlay-hint
      '((dark . "${k.dragon.special}")
        (light . "${k.lotus.special}")))

    (provide 'casa-kanagawa)
    ;;; casa-kanagawa.el ends here
  '';

  unstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; config.allowUnfree = true; };

  # Tree-sitter grammars for the *-ts-mode major modes in dotfiles/emacs.
  # Native .so's are version-sensitive, so pin them via Nix rather than building
  # at runtime (M-x treesit-install-language-grammar / *-install-grammar).
  # Symlinked into ~/.emacs.d/tree-sitter.
  emacsTreesitGrammars =
    let
      base = pkgs.emacsPackages.treesit-grammars.with-grammars (g: with g; [
        tree-sitter-python
        tree-sitter-rust
        tree-sitter-c
        tree-sitter-julia
        tree-sitter-typst
        tree-sitter-haskell
      ]);
      # zig-ts-mode requires the tree-sitter-grammars zig grammar, not the one
      # in treesit-grammars.
      zig = unstable.tree-sitter-grammars.tree-sitter-zig;
      dylib = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
    in
    pkgs.runCommand "emacs-treesit-grammars" { } ''
      mkdir -p $out/lib
      ln -s ${base}/lib/* $out/lib/
      ln -s ${zig}/parser $out/lib/libtree-sitter-zig${dylib}
    '';
in
{
  imports = [
    ./theme-mode.nix
    inputs.nix-index-database.homeModules.nix-index
  ];

  home.stateVersion = "24.11";

  home.packages = import ../packages.nix { inherit pkgs unstable; };

  home.sessionVariables = {
    EDITOR = "e";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
  ];
  
  programs.home-manager.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Replaces command-not-found, which doesn't work under flakes apparently.
  # The database comes prebuilt from the nix-index-database input
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true; # `, ffmpeg` runs it once

  # Without ServerAlive probes a client whose connection dies waits out the TCP
  # retransmission timeout, which is minutes. 15s x 3 gives up in about 45.
  # enableDefaultConfig would otherwise pin ServerAliveInterval to 0, and it is
  # deprecated besides; its other defaults match OpenSSH's own.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      ServerAliveInterval = 15;
      ServerAliveCountMax = 3;
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # No `colors`: that bakes one palette into FZF_DEFAULT_OPTS at login.
  programs.fzf.enable = true;
  programs.zoxide.enable = true;

  # The theme is set in config.toml with no env override, so light mode needs a
  # whole config directory, named by ATUIN_CONFIG_DIR.
  programs.atuin = {
    enable = true;
    package = unstable.atuin;
    enableZshIntegration = true;
    settings = atuinSettings "dark";
    themes.${atuinThemeName.dark} = atuinTheme "dark";
  };

  programs.bat = {
    enable = true;
    # No `theme`: the default, auto, detects the terminal's own background, so
    # this is right over ssh too. BAT_THEME pins it where the mode is known.
    config = {
      theme-dark = themeName.dark;
      theme-light = themeName.light;
    };
    # delta and bat read the same theme DB.
    themes = {
      ${themeName.dark}.src = pkgs.writeText "kanagawa-dragon.tmTheme" (batTheme "dark");
      ${themeName.light}.src = pkgs.writeText "kanagawa-lotus.tmTheme" (batTheme "light");
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    # No icons: JuliaMono carries no Nerd Font glyphs.
    # No `theme`: it writes one palette to a fixed path. See EZA_CONFIG_DIR.
  };

  programs.emacs = {
    enable = true;
    # Packages are pinned via Nix instead of installed at runtime from MELPA.
    # The elisp config (dotfiles/emacs) drops :ensure/:vc and just requires
    # these off the load-path. Built-ins (eglot, org, which-key, use-package)
    # are not listed. Tree-sitter grammars are provided separately, above.
    extraPackages = epkgs: (with epkgs; [
      envrc
      denote
      diminish
      projectile
      dirvish
      exec-path-from-shell
      julia-mode
      julia-ts-mode
      eglot-jl
      rust-mode
      zig-ts-mode
      haskell-mode
      haskell-ts-mode
      yaml-mode
      toml-mode
      markdown-mode
      nix-mode
      auctex
      typst-ts-mode
      eat
      ruff-format
      magit
      vertico
      orderless
      consult
      kanagawa-themes
      citar
      citar-denote
    ]) ++ [
      # Newer than nixos-26.05's 20260424.430, which mangles FIM indentation.
      # Drop once nixos-26.11 catches up.
      (unstable.emacsPackagesFor config.programs.emacs.package).minuet
    ];
  };
  services.emacs.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    shellAliases = {
      # `e` is provided by the ~/bin/e wrapper (TERM=tmux-direct for truecolor).
      # -a "" auto-starts a daemon if none is running (matches the `e` wrapper).
      egui = "emacsclient -c -a \"\"";
    };

    envExtra = ''
      [[ -f ~/.secrets ]] && source ~/.secrets
      export LIT_DATA_ROOT="/krater/lit"
    '';

    initContent = ''
      fpath=(~/.config/zsh/completions $fpath)
      source ~/.config/zsh/themes/jsqr.zsh-theme
      [[ -f ~/.cargo/env ]] && source ~/.cargo/env
      if [[ -n "$EAT_SHELL_INTEGRATION_DIR" ]]; then
        source "$EAT_SHELL_INTEGRATION_DIR/zsh"
        # Eat doesn't play well with zle plugins that redraw the prompt
        # line (autosuggestions, syntax-highlighting) — disable inside eat.
        (( $+functions[_zsh_autosuggest_disable] )) && _zsh_autosuggest_disable
        ZSH_HIGHLIGHT_HIGHLIGHTERS=()
      fi

      # fastfetch banner on shell start. Restrict to interactive shells with a
      # real terminal: skip non-interactive use (scripts, ssh commands), non-tty
      # stdout (pipes, command substitution), and dumb terminals such as
      # M-x shell / TRAMP where the escape sequences would be garbage.
      if [[ -o interactive && -t 1 && $TERM != dumb ]]; then
        fastfetch
        echo
        fortune
        echo
      fi
    '';
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = true;

      # Fallback for a git run outside a themed shell; DELTA_FEATURES wins.
      features = featureName.${config.casa.themeMode.default};
      ${featureName.dark} = deltaFeature "dark";
      ${featureName.light} = deltaFeature "light";
    };
  };

  programs.git = {
    enable = true;
    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = false;
      format = "ssh";
    };
    settings = {
      user.name = "Johnathan Jenkins";
      user.email = "jj@jsqr.org";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "e";
        excludesFile = "~/.gitignore";
      };
      diff.colorMoved = "default";
      merge.conflictstyle = "zdiff3";
      "gpg \"ssh\"".allowedSignersFile = "~/.ssh/allowed_signers";
    };
  };

  home.file.".gitignore".source = ../dotfiles/gitignore;
  home.file.".emacs".source = ../dotfiles/emacs;
  home.file.".julia/config/startup.jl".text = juliaStartup;
  home.file.".emacs.d/tree-sitter".source = "${emacsTreesitGrammars}/lib";

  # Launch terminal Emacs with TERM=tmux-direct so doom-gruvbox renders in real
  # 24-bit color. tmux's default-terminal stays tmux-256color (keeps the shell's
  # indexed palette correct); tmux forwards the 24-bit Emacs emits out to Ghostty
  # via terminal-features RGB (see programs.tmux). Scoping the direct-color TERM
  # to Emacs avoids breaking indexed-color apps in the shell. EDITOR / core.editor
  # / the `e` alias all go through this.
  home.file."bin/e" = {
    text = ''
      #!/bin/sh
      # Inside tmux the pane's TERM is tmux-256color, whose terminfo lacks the
      # RGB flag, so terminal Emacs drops to 256 colors and approximates the
      # theme. Use tmux-direct (24-bit) for the Emacs frame only. Outside tmux,
      # leave TERM alone — the real terminal (e.g. Ghostty / xterm-ghostty)
      # already advertises truecolor, and forcing tmux-direct there would be
      # wrong (and may not exist in that host's terminfo db).
      [ -n "$TMUX" ] && export TERM=tmux-direct
      exec emacsclient -t -a "" "$@"
    '';
    executable = true;
  };

  home.file."bin/update" = {
    source = ../scripts/update.sh;
    executable = true;
  };
  home.file."bin/git-status" = {
    source = ../scripts/git-status.sh;
    executable = true;
  };
  home.file."bin/ask" = {
    source = ../scripts/ask.py;
    executable = true;
  };

  xdg.configFile = {
    "zsh/themes/jsqr.zsh-theme".source = ../dotfiles/zsh/themes/jsqr.zsh-theme;

    "eza-dark/theme.yml".source =
      yamlFormat.generate "eza-theme-dark.yml" (ezaTheme k.dragon);
    "eza-light/theme.yml".source =
      yamlFormat.generate "eza-theme-light.yml" (ezaTheme k.lotus);

    "tmux/kanagawa-dark.conf".text = tmuxColors k.dragon;
    "tmux/kanagawa-light.conf".text = tmuxColors k.lotus;

    # programs.atuin above writes the dark equivalents into its own directory.
    "atuin-light/config.toml".source =
      tomlFormat.generate "atuin-light-config.toml" (atuinSettings "light");
    "atuin-light/themes/${atuinThemeName.light}.toml".source =
      tomlFormat.generate "atuin-lotus.toml" (atuinTheme "light");
  } // lib.optionalAttrs config.programs.ghostty.enable {
    "ghostty/themes/kanagawa-dragon".text = ghosttyTheme k.dragon;
    "ghostty/themes/kanagawa-lotus".text = ghosttyTheme k.lotus;
  };

  # Set here rather than per host so kalliope and thalia cannot drift; the
  # module is inert on melpomene, which does not enable ghostty.
  programs.ghostty.settings.theme = "light:kanagawa-lotus,dark:kanagawa-dragon";

  # Not on the default load-path, so dotfiles/emacs adds this directory.
  home.file.".emacs.d/casa/casa-kanagawa.el".source = emacsKanagawa;

  casa.themeMode.env = {
    dark = {
      BAT_THEME = themeName.dark;
      DELTA_FEATURES = featureName.dark;
      EZA_CONFIG_DIR = "${config.xdg.configHome}/eza-dark";
      ATUIN_CONFIG_DIR = config.xdg.configHome + "/atuin";
      FZF_DEFAULT_OPTS = fzfOpts k.dragon;
    };
    light = {
      BAT_THEME = themeName.light;
      DELTA_FEATURES = featureName.light;
      EZA_CONFIG_DIR = "${config.xdg.configHome}/eza-light";
      ATUIN_CONFIG_DIR = "${config.xdg.configHome}/atuin-light";
      FZF_DEFAULT_OPTS = fzfOpts k.lotus;
    };
  };

  casa.themeMode.reload = ''
    # tmux holds these as server-global options, so one source-file covers every
    # session and pane.
    tmux=${config.programs.tmux.package}/bin/tmux
    if "$tmux" list-sessions >/dev/null 2>&1; then
      "$tmux" source-file "${config.xdg.configHome}/tmux/kanagawa-$mode.conf" || true
    fi

    # The daemon owns the theme and every frame repaints. With no daemon there
    # is nothing to do: the next one reads the state file as it starts.
    emacsclient=${config.programs.emacs.finalPackage}/bin/emacsclient
    if "$emacsclient" --eval t >/dev/null 2>&1; then
      "$emacsclient" --eval "(jj/theme-mode '$mode)" >/dev/null 2>&1 || true
    fi
  '';

  programs.tmux = {
    enable = true;
    # tmux-256color keeps the shell's indexed palette (zsh-autosuggestions,
    # prompt) rendering correctly. Terminal Emacs gets real 24-bit color via a
    # per-app TERM=tmux-direct override (see the bin/e wrapper above), not by
    # changing this. terminal-features (below) forwards 24-bit out to Ghostty.
    terminal = "tmux-256color";
    mouse = true;
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 10000;
    baseIndex = 1;
    extraConfig = ''
      set -as terminal-features ",xterm-256color:RGB"
      set -as terminal-features ",xterm-ghostty:RGB"

      # Forward modified keys (e.g. Shift/Ctrl+Enter) to apps that ask for
      # them (pi agent warns without this)
      set -g extended-keys on
      set -g extended-keys-format csi-u

      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g set-clipboard on

      set -g pane-border-indicators arrows

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      set -g status-left-length 20
      setw -g window-status-current-format " #I:#W "
      setw -g window-status-format " #I:#W "

      # Colour lives in the two generated files below, one per mode, which the
      # switcher re-sources in place. if-shell chooses the initial one, since
      # the server can start before any shell has read the state file.
      if-shell '[ "$(cat ${config.casa.themeMode.stateFile} 2>/dev/null)" = light ]' 'source-file ${config.xdg.configHome}/tmux/kanagawa-light.conf' 'source-file ${config.xdg.configHome}/tmux/kanagawa-dark.conf'
    '';
  };
}
