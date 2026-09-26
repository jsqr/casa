# Lotus role table, from kanagawa-themes.el. Key set must match ./dragon.nix.
# synVariable and pmenuFgSel are nil upstream; resolved here.
p:

{
  fg = p.lotusInk1;
  fgDim = p.lotusInk2;
  fgReverse = p.lotusGray;

  bgDim = p.lotusWhite1;
  bgGutter = p.lotusWhite4;

  bgM3 = p.lotusWhite0;
  bgM2 = p.lotusWhite1;
  bgM1 = p.lotusWhite2;
  bg = p.lotusWhite3;
  bgP1 = p.lotusWhite4;
  bgP2 = p.lotusWhite5;

  special = p.lotusViolet2;
  nontext = p.lotusViolet1;
  whitespace = p.lotusViolet1;

  bgVisual = p.lotusViolet3;
  bgSearch = p.lotusBlue2;

  pmenuFg = p.lotusInk2;
  pmenuFgSel = p.lotusInk2;
  pmenuBg = p.lotusBlue1;
  pmenuBgSel = p.lotusBlue3;
  pmenuBgSbar = p.lotusBlue1;
  pmenuBgThumb = p.lotusBlue2;

  floatFg = p.lotusInk2;
  floatBg = p.lotusWhite0;
  floatFgBorder = p.lotusGray2;
  floatBgBorder = p.lotusWhite0;

  synString = p.lotusGreen;
  synVariable = p.lotusInk1;
  synNumber = p.lotusPink;
  synConstant = p.lotusOrange;
  synIdentifier = p.lotusYellow;
  synParameter = p.lotusBlue5;
  synFun = p.lotusBlue4;
  synStatement = p.lotusViolet4;
  synKeyword = p.lotusViolet4;
  synOperator = p.lotusYellow2;
  synPreproc = p.lotusRed;
  synType = p.lotusAqua;
  synRegex = p.lotusYellow2;
  synDeprecated = p.lotusGray3;
  synComment = p.lotusGray3;
  synPunct = p.lotusTeal1;
  synSpecial1 = p.lotusTeal2;
  synSpecial2 = p.lotusRed;
  synSpecial3 = p.peachRed;

  vcsAdded = p.lotusGreen2;
  vcsRemoved = p.lotusRed2;
  vcsChanged = p.lotusYellow3;

  diffAdd = p.lotusGreen3;
  diffDelete = p.lotusRed4;
  diffChange = p.lotusCyan;
  diffText = p.lotusYellow4;

  diagOk = p.lotusGreen;
  diagError = p.lotusRed3;
  diagWarning = p.lotusOrange2;
  diagInfo = p.lotusTeal3;
  diagHint = p.lotusAqua2;

  black = p.sumiInk3; # ANSI 0 stays dark on a light background
  red = p.lotusRed;
  green = p.lotusGreen;
  yellow = p.lotusYellow;
  blue = p.lotusBlue4;
  magenta = p.lotusPink;
  cyan = p.lotusAqua;
  white = p.lotusInk1;
  brightBlack = p.lotusGray3;
  brightRed = p.lotusRed2;
  brightGreen = p.lotusGreen2;
  brightYellow = p.lotusYellow2;
  brightBlue = p.lotusTeal2;
  brightMagenta = p.lotusViolet4;
  brightCyan = p.lotusAqua2;
  brightWhite = p.lotusInk2;
  extendColor1 = p.lotusOrange2;
  extendColor2 = p.lotusRed3;
}
