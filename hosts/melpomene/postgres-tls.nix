# For casa/hosts/melpomene/configuration.nix: postgres terminates TLS with
# the node's Tailscale certificate, so a raw-TCP Funnel can forward the
# public port 10000 to it and a direct-TLS client (libpq 17+,
# sslnegotiation=direct) verifies the certificate against the public CAs.
# Tested 2026-09-11 with ALTER SYSTEM before this was written down.
#
# After the rebuild, once:
#     tailscale funnel --bg --tcp=10000 tcp://localhost:5432
#     ashokan db init          # creates ashokan_reader
#     psql -d ashokan -c "ALTER ROLE ashokan_reader PASSWORD '...'"
# The funnel config persists in tailscaled's state.
{ config, lib, pkgs, ... }:
{
  services.postgresql = {
    settings = {
      ssl = true;
      ssl_cert_file = "/data/tls/melpomene.crt";
      ssl_key_file = "/data/tls/melpomene.key";
      # TLS 1.3 only for the public port's clients; libpq 17+ speaks it.
      ssl_min_protocol_version = "TLSv1.3";
    };

    # The funnel forwarder connects from 127.0.0.1. The reader role reaches
    # one database over TLS from there and is rejected everywhere else; the
    # existing lines stay for jj.
    authentication = lib.mkOverride 10 ''
      # TYPE     DATABASE  USER            ADDRESS         METHOD
      hostssl    ashokan   ashokan_reader  127.0.0.1/32    scram-sha-256
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
