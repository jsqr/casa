{ inputs, lib, ... }:

let
  sites = {
    "groundloop.law" = inputs.groundloop;
    "munchingsquares.com" = inputs.munchingsquares;
  };

  vhosts = domain: root: {
    ${domain}.extraConfig = ''
      root * ${root}
      file_server
    '';
    "www.${domain}".extraConfig = ''
      redir https://${domain}{uri} permanent
    '';
  };
in
{
  services.caddy = {
    enable = true;
    email = "jj@jsqr.org";
    virtualHosts = lib.mkMerge (lib.mapAttrsToList vhosts sites);
  };

  # UDP 443 is HTTP/3.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
