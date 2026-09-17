# For casa/hosts/melpomene/configuration.nix: postgres terminates TLS with
# the node's Tailscale certificate, so a client on the tailnet verifies it
# against the public CAs (sslmode=verify-full). The MCP server on this
# host reads over the socket instead (ashokan-mcp.nix).
#
# After the rebuild, once:
#     ashokan db init          # creates ashokan_reader
#     psql -d ashokan -c "ALTER ROLE ashokan_reader PASSWORD '...'"
{ config, lib, pkgs, ... }:
{
  services.postgresql = {
    settings = {
      ssl = true;
      ssl_cert_file = "/data/tls/melpomene.crt";
      ssl_key_file = "/data/tls/melpomene.key";
      # TLS 1.3 only; libpq 17+ speaks it.
      ssl_min_protocol_version = "TLSv1.3";
    };

    # The reader role reaches one database: over the socket by peer
    # identity for the MCP service on this host (ashokan-mcp.nix maps its
    # user), over TLS with a password from the tailnet for the servers run
    # on kalliope, and is rejected everywhere else. The existing lines
    # stay for jj.
    authentication = lib.mkOverride 10 ''
      # TYPE     DATABASE  USER            ADDRESS         METHOD
      local      ashokan   ashokan_reader                  peer map=mcpmap
      hostssl    ashokan   ashokan_reader  100.64.0.0/10   scram-sha-256
      host       all       ashokan_reader  all             reject
      local      all       all                             peer map=jjmap
      host       all       all             127.0.0.1/32    scram-sha-256
      host       all       all             ::1/128         scram-sha-256
      host       all       all             100.64.0.0/10   scram-sha-256
    '';
  };

  # Renew the certificate. Let's Encrypt issues for ninety days and
  # `tailscale cert` renews when it is due, so a weekly run is enough.
  systemd.services.postgres-tailscale-cert = {
    description = "Tailscale certificate for postgres TLS";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.tailscale pkgs.coreutils pkgs.systemd ];
    script = ''
      set -euo pipefail
      mkdir -p /data/tls
      tailscale cert --cert-file /data/tls/melpomene.crt --key-file /data/tls/melpomene.key \
        melpomene.xantu-ghost.ts.net
      chown -R postgres:postgres /data/tls
      chmod 600 /data/tls/melpomene.key
      systemctl reload postgresql.service
    '';
  };
  systemd.timers.postgres-tailscale-cert = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
