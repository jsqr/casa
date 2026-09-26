# { dragon, lotus, raw }. Role names come from kanagawa-themes.el, so both
# variants expose the same set and a consumer switches by which one it is handed.
let
  palette = import ./palette.nix;

  variants = {
    dragon = import ./dragon.nix palette;
    lotus = import ./lotus.nix palette;
  };

  onlyIn = a: b: builtins.filter (k: !(builtins.elem k (builtins.attrNames b)))
    (builtins.attrNames a);
  diverged = onlyIn variants.dragon variants.lotus
    ++ onlyIn variants.lotus variants.dragon;

  # Upstream's table has no slot for the window colours or the selection pair.
  withTerm = r: r // {
    term = {
      inherit (r)
        black red green yellow blue magenta cyan white
        brightBlack brightRed brightGreen brightYellow
        brightBlue brightMagenta brightCyan brightWhite;

      extended0 = r.extendColor1;
      extended1 = r.extendColor2;

      background = r.bg;
      foreground = r.fg;
      cursor = r.fg;
      cursorText = r.bg;
      selectionFg = r.fgDim;
      selectionBg = r.bgSearch;
    };
  };
in

if diverged != [ ] then
  throw "lib/kanagawa: dragon and lotus role sets differ in ${toString diverged}"
else
{
  dragon = withTerm variants.dragon;
  lotus = withTerm variants.lotus;
  raw = palette;
}
