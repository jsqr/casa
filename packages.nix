{ pkgs, unstable }:

with pkgs; [
  # CLI tools
  # aspellWithDicts wraps the binary so it can find its dictionaries
  (aspellWithDicts (d: [ d.en d.en-computers ]))
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
  htop
  hyperfine
  jq
  just
  llama-cpp
  miller
  mosh
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
  xh
  # Language servers
  haskell-language-server
  nil
  python3Packages.python-lsp-server
  tinymist
  zls
  # Toolchain managers / runtimes
  # Bare ghc: libraries come from cabal per project, not a global package db.
  # HLS's bundled ormolu can't parse cabal-version 3.16, so `cabal init` new
  # projects with --cabal-version=3.12 or format-on-save errors.
  cabal-install
  ghc
  hlint
  julia-bin
  nodejs_22
  python314
  rustup
  zig
] ++ [
  # test_stdio_server_uses_the_same_json_rpc_lifecycle fails on darwin with
  # IndexError: list index out of range.
  (unstable.mistral-vibe.overridePythonAttrs (old: {
    disabledTests = old.disabledTests ++ [
      "test_stdio_server_uses_the_same_json_rpc_lifecycle"
    ];
  }))
  unstable.pi-coding-agent
  unstable.pyrefly
]
