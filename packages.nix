{ pkgs, unstable }:

with pkgs; [
  # CLI tools
  aspell
  aspellDicts.en
  btop
  choose
  fastfetch
  gum
  jless
  delta
  duf
  duckdb
  dust
  dvc
  fd
  fortune
  fx
  git-extras
  glow
  gnumake
  harlequin
  htop
  hyperfine
  jq
  just
  llama-cpp
  miller
  mosh
  opencode
  pandoc
  poppler-utils
  procs
  ripgrep
  ruff
  rustlings
  sd
  tealdeer
  tomlq
  typst
  yq
  uv
  visidata
  xh
  # Language servers
  nil
  python3Packages.python-lsp-server
  tinymist
  zls
  # Toolchain managers / runtimes
  julia-bin
  nodejs_22
  python314
  rustup
  zig
] ++ [
  unstable.mistral-vibe
  # unstable.pi-coding-agent
  unstable.pyrefly
]
