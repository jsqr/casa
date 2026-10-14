# groundloop.law

groundloop.law is a static site. Its files live in the public repo
`github.com/jsqr/groundloop.law` (local checkout `~/jsqr/groundloop.law`).
It's served from polyhymnia with Caddy.

## Getting the site to polyhymnia

1. `flake.nix` input `groundloop`
   (`github:jsqr/groundloop.law`, `flake = false`); `flake.lock` pin.
2. Nix fetches commits from polyhymnia builds into `/nix/store`.
3. `hosts/polyhymnia/web.nix` sets Caddy's document root for groundloop.law
   to that store path. `www.groundloop.law` redirects to `groundloop.law`.

The repo holds only site files; it's public so root on polyhymnia can fetch
it without a key.

## Publishing a change

Commit and push in `~/jsqr/groundloop.law`. Then either:

- Wait. melpomene runs `nix flake update` nightly between 04:00 and 04:45
  and pushes the new lock. polyhymnia pulls casa and rebuilds between 05:30
  and 06:00.
- Don't wait. In casa, run `just groundloop` (updates only the
  `groundloop` lock entry), commit and push `flake.lock`. Then on
  polyhymnia, pull casa and run `just switch`.

## Rolling back

Revert the commit in `groundloop.law` and publish as above. Pinning an
older revision in `flake.lock` alone does not hold: the nightly
`nix flake update` moves it back to the head of `main`.
