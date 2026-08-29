#!/usr/bin/env bash
# ~/bin/update — interactive update helper for thalia and kalliope.
#
# melpomene is excluded: it upgrades itself nightly via system.autoUpgrade
# (hosts/melpomene/configuration.nix), and refreshes rustup and uv from a
# systemd user timer (the toolchain-update unit in home/melpomene.nix).
set -u

HOST="$(hostname -s)"
FLAKE="$HOME/jsqr/casa"

if [[ "$HOST" == melpomene ]]; then
  echo "update.sh does not run on melpomene — it upgrades via system.autoUpgrade." >&2
  exit 0
fi

case "$(uname -s)" in
  Darwin) PLATFORM=darwin ;;
  Linux)  PLATFORM=nixos ;;
  *) echo "unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

if [[ "$PLATFORM" == darwin ]]; then
  echo "=== Homebrew ==="
  brew update
  brew outdated

  echo -e "\n=== Home Manager generations ==="
  home-manager generations | head -3
else
  echo "=== System generations ==="
  nixos-rebuild list-generations 2>/dev/null | head -4 \
    || sudo nix-env --list-generations -p /nix/var/nix/profiles/system | tail -3
fi

echo -e "\n=== Rustup ==="
rustup check

echo -e "\n=== UV tools ==="
uv tool list

# melpomene pushes a lock bump most nights, so this checkout is usually
# behind. Preview the remote repo before the ff-only merge happens below.
echo -e "\n=== casa repo ==="
git -C "$FLAKE" fetch origin --quiet || echo "fetch failed" >&2
git -C "$FLAKE" status -sb | head -1

echo
read -p "Run updates? (y/n) " -n 1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 0

# Run the steps as a single &&-chain so a failure aborts the rest and the
# success line only prints if every step succeeded. nix flake update leaves
# flake.lock modified for manual review and commit.
if [[ "$PLATFORM" == darwin ]]; then
  build_step() {
    brew upgrade \
      && ( cd "$FLAKE" && git merge --ff-only '@{u}' && nix flake update ) \
      && home-manager switch --flake "$FLAKE#$HOST"
  }
else
  build_step() {
    ( cd "$FLAKE" && git merge --ff-only '@{u}' && nix flake update ) \
      && sudo nixos-rebuild switch --flake "$FLAKE#$HOST"
  }
fi

if build_step && rustup update && uv tool upgrade --all; then
  echo "✓ $HOST updated (flake.lock left modified — commit when ready)"
else
  echo "✗ update failed (see above); flake.lock may be modified" >&2
  exit 1
fi
