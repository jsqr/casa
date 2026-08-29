# Graphical session: niri, greetd, audio, fonts, portals, power.
# Imported by graphical hosts only.
{ config, pkgs, lib, ... }:

{
  # ------------------------------------------------------------------
  # Compositor.
  #
  # The nixpkgs module passes enableXWayland = false, so XWayland comes from
  # xwayland-satellite, started by niri. See home/niri.nix.
  #
  # useNautilus = false routes the FileChooser portal to
  # xdg-desktop-portal-gtk. niri requires xdg-desktop-portal-gnome for
  # screencast, and since version 47 that portal serves FileChooser by
  # delegating to Nautilus; without Nautilus installed the dialog fails
  # silently. The gtk portal is already present via
  # config.niri.default = [ "gnome" "gtk" ].
  # ------------------------------------------------------------------
  programs.niri = {
    enable = true;
    useNautilus = false;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ------------------------------------------------------------------
  # Display manager
  # ------------------------------------------------------------------
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd niri-session";
      user = "greeter";
    };
  };

  # Kernel console output on tty1 makes the greetd prompt unreadable.
  systemd.services.greetd.serviceConfig.Type = "idle";
  boot.kernelParams = [ "quiet" ];

  # Audio. security.rtkit comes from modules/common.nix.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  hardware.graphics.enable = true;

  # JuliaMono is the terminal face, matching ghostty on thalia. The Nerd
  # Font supplies glyphs for the shell prompt and bar.
  fonts = {
    packages = with pkgs; [
      julia-mono
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JuliaMono" "FiraCode Nerd Font Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # NetworkManager rather than melpomene's networkd + static address.
  networking.networkmanager.enable = true;

  # nixos-hardware enables power-profiles-daemon only on its AMD Framework
  # branch, so Intel hosts must set it here.
  #
  # thermald is the usual Intel default. Reported Panther Lake testing needed
  # a workaround for it to reach expected sustained wattage, so check measured
  # draw before assuming it helps.
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  services.upower.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    wl-clipboard
    playerctl
  ];
}
