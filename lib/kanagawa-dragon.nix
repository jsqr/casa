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
}
