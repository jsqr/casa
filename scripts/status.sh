#!/usr/bin/env bash
# ~/bin/status — one-screen upgrade/system status for melpomene.
# Read-only; every source here is readable, so no sudo needed.
set -u

FLAKE="$HOME/jsqr/casa"

row() { printf '%-18s %s\n' "$1" "$2"; }

current="$(readlink /run/current-system)"
booted="$(readlink /run/booted-system)"
cur_ver="${current##*-nixos-system-melpomene-}"
boot_ver="${booted##*-nixos-system-melpomene-}"

gen="$(readlink /nix/var/nix/profiles/system | sed -E 's/^system-([0-9]+)-link$/\1/')"
# stat without -L: the link's own mtime is the switch time; the store
# path it points at has mtime 0.
gen_date="$(date -d "@$(stat -c %Y /nix/var/nix/profiles/system)" '+%Y-%m-%d')"

running_kernel="$(uname -r)"
staged_kernel="$(ls /run/current-system/kernel-modules/lib/modules)"

pin="$(jq -r '.nodes[.nodes.root.inputs.nixpkgs]
  | .locked.rev[0:7] + "  (" + (.locked.lastModified | strftime("%Y-%m-%d")) + ")"' \
  "$FLAKE/flake.lock")"
lock_commit="$(git -C "$FLAKE" log -1 --format='%h "%s"  (%as)' -- flake.lock)"

upgrade_result="$(systemctl show nixos-upgrade.service -p Result --value)"
upgrade_time="$(systemctl show nixos-upgrade.service -p ExecMainExitTimestamp --value)"
next_run="$(systemctl show nixos-upgrade.timer -p NextElapseUSecRealtime --value)"

echo "melpomene · $(date '+%Y-%m-%d %H:%M')"
printf '─%.0s' {1..60}; echo

row "System (current)" "$cur_ver  (gen $gen, built $gen_date)"
if [[ "$current" == "$booted" ]]; then
  row "System (booted)" "same — ✓ no reboot needed"
else
  row "System (booted)" "$boot_ver  ⚠ reboot pending"
fi
if [[ "$running_kernel" == "$staged_kernel" ]]; then
  row "Kernel" "$running_kernel  ✓ current"
else
  row "Kernel" "running $running_kernel → staged $staged_kernel"
fi
row "nixpkgs pin" "$pin"
row "flake.lock commit" "$lock_commit"
if [[ "$upgrade_result" == "success" ]]; then
  row "Auto-upgrade" "✓ ok at $upgrade_time"
else
  row "Auto-upgrade" "✗ $upgrade_result at $upgrade_time"
fi
row "Next run" "$next_run"
row "Disk /" "$(df -h --output=used,size,pcent / | awk 'NR==2 {print $1" used / "$2"  ("$3")"}')"
