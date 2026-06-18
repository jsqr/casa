#!/usr/bin/env bash
# ~/bin/update — interactive update helper (thalia only).
# melpomene upgrades itself nightly via system.autoUpgrade; see
# hosts/melpomene/configuration.nix.
set -u

HOST="$(hostname -s)"
FLAKE="$HOME/jsqr/casa"

if [[ "$HOST" != thalia ]]; then
  echo "update.sh is thalia-only — $HOST upgrades via system.autoUpgrade." >&2
  exit 0
fi

echo "=== Homebrew ==="
brew update
brew outdated

echo -e "\n=== Home Manager generations ==="
home-manager generations | head -3

echo -e "\n=== Rustup ==="
rustup check

echo -e "\n=== UV tools ==="
uv tool list

echo
read -p "Run updates? (y/n) " -n 1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 0

# Run the steps as a single &&-chain so a failure aborts the rest and the
# success line only prints if every step succeeded. nix flake update leaves
# flake.lock modified for you to review and commit yourself.
if brew upgrade \
    && ( cd "$FLAKE" && nix flake update ) \
    && home-manager switch --flake "$FLAKE#thalia" \
    && rustup update \
    && uv tool upgrade --all; then
  echo "✓ thalia updated (flake.lock left modified — commit when ready)"
else
  echo "✗ update failed (see above); flake.lock may be modified" >&2
  exit 1
fi
