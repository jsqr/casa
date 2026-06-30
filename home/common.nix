{ config, pkgs, lib, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable { inherit (pkgs) system; config.allowUnfree = true; };

  # Tree-sitter grammars for the *-ts-mode major modes in dotfiles/emacs.
  # Version-sensitive native .so's, so pin them via Nix rather than building
  # them at runtime (M-x treesit-install-language-grammar / *-install-grammar).
  # Symlinked into ~/.emacs.d/tree-sitter below, where Emacs searches by default.
  emacsTreesitGrammars =
    pkgs.emacsPackages.treesit-grammars.with-grammars (g: with g; [
      tree-sitter-python
      tree-sitter-rust
      tree-sitter-c
      tree-sitter-julia
      tree-sitter-zig
      tree-sitter-typst
    ]);
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

  programs.fzf.enable = true;
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
    };
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Kanagawa Dragon";
    };
    # Kanagawa Dragon isn't a bat built-in; ship the tmTheme and let
    # home-manager rebuild the cache. delta reads the same theme DB.
    themes."Kanagawa Dragon" = {
      src = ../dotfiles/bat;
      file = "Kanagawa Dragon.tmTheme";
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
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
      gruvbox-theme
      kanagawa-themes
    ];
  };
  services.emacs.enable = true;

  # services.ollama.enable = true;

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

      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g set-clipboard on

      set -g pane-border-style "fg=colour238"
      # highlight accent: #c4746e (Kanagawa dragonRed); was colour166 (gruvbox orange)
      set -g pane-active-border-style "fg=#c4746e,bold"
      set -g pane-border-indicators arrows

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      set -g status-style "bg=colour235,fg=colour248"
      set -g status-left "#[fg=#c4746e,bold] #S "
      set -g status-right "#[fg=colour248] %Y-%m-%d %H:%M "
      set -g status-left-length 20
      setw -g window-status-current-style "fg=#c4746e,bold"
      setw -g window-status-current-format " #I:#W "
      setw -g window-status-format " #I:#W "
    '';
  };
}
