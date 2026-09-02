# Graphical session: niri, greetd, audio, fonts, portals, power, printing.
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

  # ------------------------------------------------------------------
  # Printing and scanning — HP LaserJet MFP M426fdw on the LAN.
  #
  # The queue is driverless. The printer reports ipp-features-supported =
  # airprint-1.4 and lists application/pdf in document-format-supported, so
  # CUPS forwards PDF untouched.
  #
  # avahi resolves but does not publish. kalliope roams, so it answers no
  # mDNS queries of its own; nssmdns4 is only what makes NPI2DA1C3.local
  # resolve, for the queue below and for sane-airscan's discovery.
  # ------------------------------------------------------------------
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.printing = {
    enable = true;
    # browsed.enable defaults to services.avahi.enable. cupsd does its own
    # DNS-SD browsing, so browsed would only add a second, auto-named queue
    # beside the declared one.
    browsed.enable = false;
  };

  # lpadmin -m everywhere fetches the printer's IPP attributes, so the first
  # run of ensure-printers must happen on the printer's LAN. The queue then
  # persists in /var/lib/cups. SuccessExitStatus keeps later rebuilds away
  # from home — where the query cannot succeed and does not need to — from
  # reporting a failed unit.
  hardware.printers = {
    ensureDefaultPrinter = "laserjet";
    ensurePrinters = [{
      name = "laserjet";
      description = "HP LaserJet MFP M426fdw";
      deviceUri = "ipp://NPI2DA1C3.local:631/ipp/print";
      model = "everywhere";
      # The duplexer is installed and the printer is mono-only.
      ppdOptions = {
        PageSize = "Letter";
        Duplex = "DuplexNoTumble";
      };
    }];
  };
  systemd.services.ensure-printers.serviceConfig.SuccessExitStatus = "1";

  # Scanning over eSCL, which the printer serves at /eSCL. sane's own escl
  # backend is disabled so airscan does not list the scanner twice.
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
    disabledDefaultBackends = [ "escl" ];
  };

  # sane grants access through the scanner group, or lp when the device is
  # also a printer. Neither is needed for a network scanner, but a USB one
  # would want them.
  users.users.jj.extraGroups = [ "scanner" "lp" ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    wl-clipboard
    playerctl
  ];
}
