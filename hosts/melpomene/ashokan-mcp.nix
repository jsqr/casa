# For casa/hosts/melpomene/configuration.nix: the ashokan MCP server, the
# servers/mcp member of the ashokan repo, as a system service. It reads
# the local postgres as ashokan_reader over the socket, by peer identity,
# and answers on 127.0.0.1:8011. The Funnel on 443 publishes it beside
# whatever serves `/` there (flex-testing on 8004 today): two path
# handlers, one for the MCP endpoint and one for the OAuth discovery
# document clients fetch at the origin, set by a oneshot below. Callers
# sign in through Descope and the tools answer the ones on the allowlist
# (see the repo's README, "The MCP server").
#
# Everything here is declared except what is private, which this public
# repo cannot hold. Two files in jj's home reach the service as systemd
# credentials: ~/.secrets, from which the start script takes only the
# key that embeds queries (ASHOKAN_OPENROUTER_API_KEY), and
# ~/.config/ashokan/mcp-allowlist, the callers the tools answer, one
# email or Descope subject id per line, `#` for a comment. To let someone
# in, add them there and restart the service.
#
# The postgres funnel on 10000 can be turned off (tailscale funnel
# --tcp=10000 off) once nothing off the machine reads the database.
{ config, lib, pkgs, inputs, ... }:
let
  publicUrl = "https://melpomene.xantu-ghost.ts.net";
  allowlistPath = "/home/jj/.config/ashokan/mcp-allowlist";
  # The Descope project's MCP server entry, whose discovery document is
  # the one that advertises client registration.
  descopeConfigUrl = "https://api.descope.com/v1/apps/agentic/P3JLNBkECdLJGLMMD9r4Lbyq6n8p/RS3JN78uhexnrg87WRtNbBkY8v4dX/.well-known/openid-configuration";
  # The ashokan workspace from its uv.lock, wheels preferred, and a
  # virtualenv holding the ashokan-mcp member with its dependencies.
  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = inputs.ashokan;
  };
  pythonSet =
    (pkgs.callPackage inputs.pyproject-nix.build.packages {
      python = pkgs.python313;
    }).overrideScope (lib.composeManyExtensions [
      inputs.pyproject-build-systems.overlays.wheel
      (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
    ]);
  venv = pythonSet.mkVirtualEnv "ashokan-mcp-env" { ashokan-mcp = [ ]; };

  # The ashokan config the server reads. data_root is required by the
  # config loader and never opened by this server.
  ashokanToml = pkgs.writeText "ashokan-mcp.toml" ''
    data_root = "/var/empty"
    [postgres]
    url = "postgresql:///ashokan?host=/run/postgresql&user=ashokan_reader"
  '';
  # Only the one line the service needs leaves the secrets file; the rest
  # of it never enters the environment.
  start = pkgs.writeShellScript "ashokan-mcp-start" ''
    set -euo pipefail
    eval "$(${pkgs.gnugrep}/bin/grep -E '^export ASHOKAN_OPENROUTER_API_KEY=' \
      "$CREDENTIALS_DIRECTORY/secrets")"
    export OPENROUTER_API_KEY="$ASHOKAN_OPENROUTER_API_KEY"
    exec ${venv}/bin/python -m ashokan_mcp.server
  '';
in
{
  users.users.ashokan-mcp = {
    isSystemUser = true;
    group = "ashokan-mcp";
  };
  users.groups.ashokan-mcp = { };

  services.postgresql.identMap = ''
    mcpmap     ashokan-mcp      ashokan_reader
  '';

  systemd.services.ashokan-mcp = {
    description = "ashokan MCP server";
    after = [ "network-online.target" "postgresql.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = [ "/home/jj/.secrets" allowlistPath ];
    environment = {
      ASHOKAN_CONFIG = ashokanToml;
      ASHOKAN_MCP_AUTH = "descope";
      ASHOKAN_MCP_BIND = "127.0.0.1";
      ASHOKAN_MCP_PORT = "8011";
      ASHOKAN_MCP_BASE_URL = publicUrl;
      DESCOPE_CONFIG_URL = descopeConfigUrl;
      # %d is the credentials directory.
      ASHOKAN_MCP_ALLOWLIST = "%d/allowlist";
    };
    serviceConfig = {
      User = "ashokan-mcp";
      Group = "ashokan-mcp";
      LoadCredential = [
        "secrets:/home/jj/.secrets"
        "allowlist:${allowlistPath}"
      ];
      ExecStart = start;
      Restart = "on-failure";
      RestartSec = 5;
      # It talks to postgres over its socket and to the embedding
      # provider; nothing else. A read-only root would refuse the socket
      # connect, hence the one writable path.
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/run/postgresql" ];
    };
  };

  # The two funnel handlers. `tailscale funnel --bg` records them in
  # tailscaled's state, so running this again is a no-op; the `/` handler
  # already there is left alone. The funnel strips a handler's mount path
  # from the request and the path on the backend url puts it back, so the
  # server sees the paths it serves.
  systemd.services.ashokan-mcp-funnel = {
    description = "Tailscale funnel handlers for the ashokan MCP server";
    after = [ "tailscaled.service" "ashokan-mcp.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.tailscale ];
    script = ''
      set -euo pipefail
      tailscale funnel --bg --set-path=/mcp http://127.0.0.1:8011/mcp
      tailscale funnel --bg --set-path=/.well-known/oauth-protected-resource \
        http://127.0.0.1:8011/.well-known/oauth-protected-resource
    '';
  };
}
