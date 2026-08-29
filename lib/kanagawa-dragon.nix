# Kanagawa Dragon palette. Named for the variant: kanagawa is a family of
# wave, dragon and lotus, and dragon is not the default.
#
# The dragon* names are copied from kanagawa.nvim's lua/kanagawa/colors.lua
# so they stay greppable against upstream. The aliases below them are local.
#
# home/common.nix repeats these hex values inline for fzf, atuin, eza, delta
# and tmux. Not changed here; those hosts are working.
rec {
  # ---- upstream names, from kanagawa.nvim ---------------------------
  dragonBlack0 = "#0d0c0c";
  dragonBlack1 = "#12120f";
  dragonBlack2 = "#1D1C19";
  dragonBlack3 = "#181616";
  dragonBlack4 = "#282727";
  dragonBlack5 = "#393836";
  dragonBlack6 = "#625e5a";

  dragonWhite = "#c5c9c5";
  dragonGreen = "#87a987";
  dragonGreen2 = "#8a9a7b";
  dragonPink = "#a292a3";
  dragonOrange = "#b6927b";
  dragonOrange2 = "#b98d7b";
  dragonGray = "#a6a69c";
  dragonGray2 = "#9e9b93";
  dragonGray3 = "#7a8382";
  dragonBlue = "#658594";
  dragonBlue2 = "#8ba4b0";
  dragonViolet = "#8992a7";
  dragonRed = "#c4746e";
  dragonAqua = "#8ea4a2";
  dragonAsh = "#737c73";
  dragonTeal = "#949fb5";
  dragonYellow = "#c4b28a";

  # From the shared palette, not the dragon group. The dragon theme's terminal
  # and diff colours draw on these. Upstream writes them uppercase; lowercased
  # here to match the dragon* names above and the hex the tools emit.
  oldWhite = "#c8c093";
  waveRed = "#e46876";
  winterRed = "#43242b";
  winterGreen = "#2b3328";
  waveAqua2 = "#7aa89f";
  waveBlue2 = "#2d4f67";
  carpYellow = "#e6c384";
  springBlue = "#7fb4ca";
  springViolet1 = "#938aa9";

  # ---- aliases ------------------------------------------------------
  # Chosen to match how home/common.nix already uses these values.
  bg = dragonBlack3; # window / bar background
  bgAlt = dragonBlack4; # selected row, secondary surface
  bgDim = dragonBlack1; # dimmed / inactive surface
  fg = dragonWhite; # primary text
  fgDim = dragonAsh; # comments, annotations, inactive text
  border = dragonBlack5;

  accent = dragonBlue2; # focus ring, prompts, links
  inactive = dragonBlack5; # unfocused ring
  urgent = dragonRed; # urgent window, errors
  warning = dragonYellow;
  success = dragonGreen;
  info = dragonGreen2;

  # ---- 16-colour ANSI set -------------------------------------------
  ansi = {
    black = dragonBlack0;
    red = dragonRed;
    green = dragonGreen;
    yellow = dragonYellow;
    blue = dragonBlue2;
    magenta = dragonPink;
    cyan = dragonAqua;
    white = dragonWhite;

    brightBlack = dragonBlack6;
    brightRed = dragonRed;
    brightGreen = dragonGreen;
    brightYellow = dragonYellow;
    brightBlue = dragonBlue2;
    brightMagenta = dragonPink;
    brightCyan = dragonAqua;
    brightWhite = dragonWhite;
  };

  # ---- diff backgrounds ----------------------------------------------
  # winterRed and winterGreen are upstream; the emph pair is local, each a
  # lightened version of the block colour, for delta's *-emph-style.
  diff = {
    delete = winterRed;
    deleteEmph = "#663639";
    add = winterGreen;
    addEmph = "#405d40";
  };

  # ---- terminal palette ---------------------------------------------
  # The dragon theme's `term` table from kanagawa.nvim's
  # lua/kanagawa/themes.lua, in upstream's order, plus the selection pair
  # its extras/ use. This is the reference for any terminal emulator here.
  #
  # Distinct from `ansi` above, which is the UI-accent set home/common.nix
  # uses: that one collapses six brights onto their regulars, which suits a
  # bar but loses bold/bright in a terminal.
  term = {
    black = dragonBlack0;
    red = dragonRed;
    green = dragonGreen2;
    yellow = dragonYellow;
    blue = dragonBlue2;
    magenta = dragonPink;
    cyan = dragonAqua;
    white = oldWhite;

    brightBlack = dragonGray;
    brightRed = waveRed;
    brightGreen = dragonGreen;
    brightYellow = carpYellow;
    brightBlue = springBlue;
    brightMagenta = springViolet1;
    brightCyan = waveAqua2;
    brightWhite = dragonWhite;

    # Indices 16 and 17; upstream calls them extended colours.
    extended0 = dragonOrange;
    extended1 = dragonOrange2;

    selectionFg = oldWhite;
    selectionBg = waveBlue2;
  };
}
