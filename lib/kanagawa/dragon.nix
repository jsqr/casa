# Dragon role table, from kanagawa-themes.el. Key set must match ./lotus.nix.
# synVariable and pmenuFgSel are nil upstream; resolved here.
p:

{
  fg = p.dragonWhite;
  fgDim = p.oldWhite;
  fgReverse = p.waveBlue1;

  bgDim = p.dragonBlack1;
  bgGutter = p.dragonBlack4;

  bgM3 = p.dragonBlack0;
  bgM2 = p.dragonBlack1;
  bgM1 = p.dragonBlack2;
  bg = p.dragonBlack3;
  bgP1 = p.dragonBlack4;
  bgP2 = p.dragonBlack5;

  special = p.dragonGray3;
  nontext = p.dragonBlack6;
  whitespace = p.dragonBlack6;

  bgVisual = p.waveBlue1;
  bgSearch = p.waveBlue2;

  pmenuFg = p.fujiWhite;
  pmenuFgSel = p.fujiWhite;
  pmenuBg = p.waveBlue1;
  pmenuBgSel = p.waveBlue2;
  pmenuBgSbar = p.waveBlue1;
  pmenuBgThumb = p.waveBlue2;

  floatFg = p.oldWhite;
  floatBg = p.dragonBlack0;
  floatFgBorder = p.sumiInk6;
  floatBgBorder = p.dragonBlack0;

  synString = p.dragonGreen2;
  synVariable = p.dragonWhite;
  synNumber = p.dragonPink;
  synConstant = p.dragonOrange;
  synIdentifier = p.dragonYellow;
  synParameter = p.dragonGray;
  synFun = p.dragonBlue2;
  synStatement = p.dragonViolet;
  synKeyword = p.dragonViolet;
  synOperator = p.dragonRed;
  synPreproc = p.dragonRed;
  synType = p.dragonAqua;
  synRegex = p.dragonRed;
  synDeprecated = p.katanaGray;
  synComment = p.dragonAsh;
  synPunct = p.dragonGray2;
  synSpecial1 = p.dragonTeal;
  synSpecial2 = p.dragonRed;
  synSpecial3 = p.dragonRed;

  vcsAdded = p.autumnGreen;
  vcsRemoved = p.autumnRed;
  vcsChanged = p.autumnYellow;

  diffAdd = p.winterGreen;
  diffDelete = p.winterRed;
  diffChange = p.winterBlue;
  diffText = p.winterYellow;

  diagOk = p.springGreen;
  diagError = p.samuraiRed;
  diagWarning = p.roninYellow;
  diagInfo = p.dragonBlue;
  diagHint = p.waveAqua1;

  black = p.dragonBlack0;
  red = p.dragonRed;
  green = p.dragonGreen2;
  yellow = p.dragonYellow;
  blue = p.dragonBlue2;
  magenta = p.dragonPink;
  cyan = p.dragonAqua;
  white = p.oldWhite;
  brightBlack = p.dragonGray;
  brightRed = p.waveRed;
  brightGreen = p.dragonGreen;
  brightYellow = p.carpYellow;
  brightBlue = p.springBlue;
  brightMagenta = p.springViolet1;
  brightCyan = p.waveAqua2;
  brightWhite = p.dragonWhite;
  extendColor1 = p.dragonOrange;
  extendColor2 = p.dragonOrange2;
}
