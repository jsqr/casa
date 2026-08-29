{ config, pkgs, lib, inputs, ... }:

let
  c = import ../lib/kanagawa-dragon.nix;

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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  programs.fzf = {
    enable = true;
    # Kanagawa Dragon. bg/gutter = -1 keeps popups transparent to the
    # terminal background; accents (pointer/marker/prompt) use KD hues.
    colors = {
      "fg" = c.dragonWhite;
      "bg" = "-1";
      "hl" = c.dragonRed;
      "fg+" = c.dragonWhite;
      "bg+" = c.dragonBlack4;
      "hl+" = c.dragonRed;
      "info" = c.dragonGreen2;
      "border" = c.dragonBlack6;
      "prompt" = c.dragonBlue2;
      "pointer" = c.dragonRed;
      "marker" = c.dragonGreen;
      "spinner" = c.dragonOrange;
      "header" = c.dragonViolet;
      "gutter" = "-1";
    };
  };
  programs.zoxide.enable = true;

  programs.atuin = {
    enable = true;
    package = unstable.atuin;
    enableZshIntegration = true;
    settings = {
      auto_sync = false;
      update_check = false;
      style = "compact";
      inline_height = 20;
      keymap_mode = "emacs";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "session";
      theme.name = "kanagawa-dragon";
    };
    # Kanagawa Dragon theme, written to ~/.config/atuin/themes/.
    themes."kanagawa-dragon" = {
      theme.name = "kanagawa-dragon";
      colors = {
        Base = c.dragonWhite;
        Title = c.dragonRed;
        Important = c.dragonOrange;
        Guidance = c.dragonBlue2;
        Annotation = c.dragonAsh;
        AlertInfo = c.dragonGreen2;
        AlertWarn = c.dragonYellow;
        AlertError = c.dragonRed;
      };
    };
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Kanagawa Dragon";
    };
    # delta and bat read the same theme DB.
    themes."Kanagawa Dragon" = {
      src = ../dotfiles/bat;
      file = "Kanagawa Dragon.tmTheme";
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    # No icons: JuliaMono carries no Nerd Font glyphs.
    # Kanagawa Dragon, written to ~/.config/eza/theme.yml. Omitted keys fall
    # back to eza's built-in defaults; only foregrounds are pinned to KD hues.
    theme = {
      filekinds = {
        normal.foreground = c.dragonWhite;
        directory.foreground = c.dragonBlue2;
        symlink.foreground = c.dragonAqua;
        pipe.foreground = c.dragonAsh;
        block_device.foreground = c.dragonOrange;
        char_device.foreground = c.dragonOrange;
        socket.foreground = c.dragonAsh;
        special.foreground = c.dragonPink;
        executable.foreground = c.dragonGreen;
        mount_point.foreground = c.dragonBlue2;
      };
      perms = {
        user_read.foreground = c.dragonWhite;
        user_write.foreground = c.dragonYellow;
        user_execute_file.foreground = c.dragonGreen;
        user_execute_other.foreground = c.dragonGreen;
        group_read.foreground = c.dragonGray;
        group_write.foreground = c.dragonYellow;
        group_execute.foreground = c.dragonGreen;
        other_read.foreground = c.dragonAsh;
        other_write.foreground = c.dragonYellow;
        other_execute.foreground = c.dragonGreen;
        special_user_file.foreground = c.dragonPink;
        special_other.foreground = c.dragonAsh;
        attribute.foreground = c.dragonAsh;
      };
      size = {
        major.foreground = c.dragonWhite;
        minor.foreground = c.dragonAqua;
        number_byte.foreground = c.dragonWhite;
        number_kilo.foreground = c.dragonWhite;
        number_mega.foreground = c.dragonBlue2;
        number_giga.foreground = c.dragonPink;
        number_huge.foreground = c.dragonPink;
        unit_byte.foreground = c.dragonAsh;
        unit_kilo.foreground = c.dragonBlue2;
        unit_mega.foreground = c.dragonBlue2;
        unit_giga.foreground = c.dragonPink;
        unit_huge.foreground = c.dragonYellow;
      };
      users = {
        user_you.foreground = c.dragonWhite;
        user_root.foreground = c.dragonRed;
        user_other.foreground = c.dragonPink;
        group_yours.foreground = c.dragonGray;
        group_other.foreground = c.dragonAsh;
        group_root.foreground = c.dragonRed;
      };
      links = {
        normal.foreground = c.dragonAqua;
        multi_link_file.foreground = c.dragonYellow;
      };
      git = {
        new.foreground = c.dragonGreen;
        modified.foreground = c.dragonYellow;
        deleted.foreground = c.dragonRed;
        renamed.foreground = c.dragonAqua;
        typechange.foreground = c.dragonPink;
        ignored.foreground = c.dragonAsh;
        conflicted.foreground = c.dragonRed;
      };
      git_repo = {
        branch_main.foreground = c.dragonWhite;
        branch_other.foreground = c.dragonPink;
        git_clean.foreground = c.dragonGreen;
        git_dirty.foreground = c.dragonRed;
      };
      punctuation.foreground = c.dragonBlack6;
      date.foreground = c.dragonGreen2;
      inode.foreground = c.dragonAsh;
      header.foreground = c.dragonGray;
    };
  };

  programs.emacs = {
    enable = true;
    # Packages are pinned via Nix instead of installed at runtime from MELPA.
    # The elisp config (dotfiles/emacs) drops :ensure/:vc and just requires
    # these off the load-path. Built-ins (eglot, org, which-key, use-package)
    # are not listed. Tree-sitter grammars are provided separately, above.
    extraPackages = epkgs: with epkgs; [
      envrc
      denote
      org-appear
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
      minuet
      kanagawa-themes
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
      syntax-theme = "Kanagawa Dragon";

      # keep syntax-highlighted text; only tint the background so
      # added/removed lines stay legible under Kanagawa Dragon.
      minus-style = ''syntax "${c.diff.delete}"'';
      minus-non-emph-style = ''syntax "${c.diff.delete}"'';
      minus-emph-style = ''syntax "${c.diff.deleteEmph}"'';
      minus-empty-line-marker-style = ''normal "${c.diff.delete}"'';

      plus-style = ''syntax "${c.diff.add}"'';
      plus-non-emph-style = ''syntax "${c.diff.add}"'';
      plus-emph-style = ''syntax "${c.diff.addEmph}"'';
      plus-empty-line-marker-style = ''normal "${c.diff.add}"'';

      # muted grays/blues for gutter + hunk headers (KD-native)
      line-numbers-minus-style = c.dragonRed;
      line-numbers-plus-style = c.dragonGreen;
      line-numbers-zero-style = c.dragonBlack6;
      line-numbers-left-style = c.dragonBlack6;
      line-numbers-right-style = c.dragonBlack6;
      hunk-header-decoration-style = "${c.dragonBlack6} box";
      hunk-header-file-style = c.dragonBlue2;
      hunk-header-line-number-style = c.dragonYellow;
      file-style = "${c.dragonWhite} bold";
      file-decoration-style = "${c.dragonBlack6} ul";
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
      alias = {
        pi     = "!git commit --trailer 'Assisted-By: Pi (qwen3.7-plus)'";
        vibe   = "!git commit --trailer 'Assisted-By: Mistral Vibe'";
        claude = "!git commit --trailer 'Assisted-By: Claude Code'";
      };
    };
  };

  home.file.".gitignore".source = ../dotfiles/gitignore;
  home.file.".emacs".source = ../dotfiles/emacs;
  home.file.".julia/config/startup.jl".source = ../dotfiles/julia/startup.jl;
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

  xdg.configFile."zsh/themes/jsqr.zsh-theme".source =
    ../dotfiles/zsh/themes/jsqr.zsh-theme;

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

      # Kanagawa Dragon: dim border dragonBlack5, active accent dragonRed;
      # was colour238/colour166 (gruvbox era).
      set -g pane-border-style "fg=${c.dragonBlack5}"
      set -g pane-active-border-style "fg=${c.dragonRed},bold"
      set -g pane-border-indicators arrows

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Kanagawa Dragon: status bg dragonBlack3, fg dragonGray.
      set -g status-style "bg=${c.dragonBlack3},fg=${c.dragonGray}"
      set -g status-left "#[fg=${c.dragonRed},bold] #S "
      set -g status-right "#[fg=${c.dragonGray}] %Y-%m-%d %H:%M "
      set -g status-left-length 20
      setw -g window-status-current-style "fg=${c.dragonRed},bold"
      setw -g window-status-current-format " #I:#W "
      setw -g window-status-format " #I:#W "
    '';
  };
}
