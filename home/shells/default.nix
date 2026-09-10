# The seam between the compositor config and the shell layer.
#
# A shell layer provides the bar, launcher, notifications, lock screen and
# wallpaper, and the niri keybinds that invoke them. noctalia.nix is the only
# one, but it contributes through these options rather than editing
# home/niri.nix, so the compositor config stays shell-agnostic and a second
# shell would only have to define its own values.
{ lib, ... }:

{
  imports = [
    ./noctalia.nix
  ];

  options.kalliope.niri = {
    startup = lib.mkOption {
      type = lib.types.listOf (lib.types.listOf lib.types.str);
      default = [ ];
      description = "spawn-at-startup entries, each given as an argv list.";
    };

    binds = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "KDL fragment spliced into niri's binds block.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "KDL spliced in at top level, outside any block.";
    };
  };
}
