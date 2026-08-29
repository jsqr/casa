# Options selecting between the two shell layers in this directory.
#
# Both modules are always imported. Each wraps its config in mkIf on
# kalliope.shell, so only one defines anything at a time.
#
# A shell layer provides the bar, launcher, notifications, lock screen and
# wallpaper, and the niri keybinds that invoke them. The kalliope.niri.*
# options let each module supply its own spawn-at-startup entries and KDL
# fragment, so changing kalliope.shell updates the compositor config too.
{ lib, ... }:

{
  imports = [
    ./alacarte.nix
    ./noctalia.nix
  ];

  options.kalliope = {
    shell = lib.mkOption {
      type = lib.types.enum [ "alacarte" "noctalia" ];
      default = "alacarte";
      description = "Which shell layer to use.";
    };

    niri = {
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

      focusRing = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether home/niri.nix emits a layout.focus-ring block. Noctalia
          supplies one in its own included KDL and sets this false.
        '';
      };
    };
  };
}
