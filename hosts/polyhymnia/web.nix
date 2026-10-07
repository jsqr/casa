{ ... }:

let
  domain = "groundloop.law";
in
{
  services.caddy = {
    enable = true;
    email = "jj@jsqr.org";
    virtualHosts.${domain}.extraConfig = ''
      root * ${./www}
      file_server
    '';
    virtualHosts."www.${domain}".extraConfig = ''
      redir https://${domain}{uri} permanent
    '';
  };

  # UDP 443 is HTTP/3.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
