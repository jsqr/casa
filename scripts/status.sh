#!/usr/bin/env bash
# ~/bin/status — one-screen upgrade/system status for a NixOS host.
# Read-only; every source here is readable, so no sudo needed.
set -u

FLAKE="$HOME/jsqr/casa"
HOST="$(hostname -s)"

row() { printf '%-18s %s\n' "$1" "$2"; }

# Seconds to a single coarse unit; long enough ago is all that matters here.
ago() {
  local s=$1
  if   (( s < 3600 ));  then printf '%dm' $(( s / 60 ))
  elif (( s < 86400 )); then printf '%dh' $(( s / 3600 ))
  else                       printf '%dd' $(( s / 86400 ))
  fi
}

mark() { (( $1 >= $2 )) && printf '⚠' || printf '✓'; }

current="$(readlink /run/current-system)"
booted="$(readlink /run/booted-system)"
cur_ver="${current##*-nixos-system-$HOST-}"
boot_ver="${booted##*-nixos-system-$HOST-}"

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

# system.autoUpgrade runs on melpomene only.
# --no-pager matters: systemctl pipes through a pager, so a caller that closes
# stdout early gets exit 141 (SIGPIPE) even though the unit exists.
if [[ -n "$(systemctl list-unit-files --no-legend --no-pager nixos-upgrade.timer 2>/dev/null)" ]]; then
  has_autoupgrade=1
  upgrade_result="$(systemctl show nixos-upgrade.service -p Result --value)"
  upgrade_time="$(systemctl show nixos-upgrade.service -p ExecMainExitTimestamp --value)"
  next_run="$(systemctl show nixos-upgrade.timer -p NextElapseUSecRealtime --value)"
else
  has_autoupgrade=0
fi

# btrbk instance names differ per host (melpomene "local", kalliope "kalliope"),
# so find the unit rather than hardcoding it.
btrbk_unit="$(systemctl list-unit-files --no-legend --no-pager 'btrbk-*.service' 2>/dev/null \
  | awk '{print $1; exit}')"
if [[ -n "$btrbk_unit" ]]; then
  btrbk_state="$(systemctl show "$btrbk_unit" -p ActiveState --value)"
  btrbk_result="$(systemctl show "$btrbk_unit" -p Result --value)"
  btrbk_next="$(systemctl show "${btrbk_unit%.service}.timer" -p NextElapseUSecRealtime --value)"
  # Written by ExecStartPost, so it marks the last run that actually reached
  # the target — not merely the last one that snapshotted locally. It sits
  # outside /var/lib/btrbk because tmpfiles holds that at 0750.
  stamp=/var/lib/btrbk-last-success
  if [[ -s "$stamp" || ( -r "$stamp" && -n "$(systemctl show "$btrbk_unit" -p ExecMainExitTimestamp --value)" ) ]]; then
    success_ago="$(ago $(( $(date +%s) - $(stat -c %Y "$stamp") )))"
  else
    success_ago=""
    # No stamp (an instance without the ExecStartPost marker): fall back to
    # when the unit last finished, which conflates "ran" with "reached target".
    btrbk_ran="$(systemctl show "$btrbk_unit" -p ExecMainExitTimestamp --value)"
  fi
  snap_count="$(ls -1 /.snapshots 2>/dev/null | wc -l)"
  # Names are <subvol>.YYYYMMDDThhmm (timestamp_format long), and sort
  # chronologically. The span shows whether retention is doing its job.
  oldest_snap="$(ls -1 /.snapshots 2>/dev/null | sort | head -1)"
  if [[ "$oldest_snap" =~ \.([0-9]{8})T([0-9]{4})$ ]]; then
    d="${BASH_REMATCH[1]}" t="${BASH_REMATCH[2]}"
    oldest_age="$(ago $(( $(date +%s) \
      - $(date -d "${d:0:4}-${d:4:2}-${d:6:2} ${t:0:2}:${t:2:2}" +%s) )))"
  else
    oldest_age=""
  fi
fi

echo "$HOST · $(date '+%Y-%m-%d %H:%M')"
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
if [[ "$has_autoupgrade" == 1 ]]; then
  if [[ "$upgrade_result" == "success" ]]; then
    row "Auto-upgrade" "✓ ok at $upgrade_time"
  else
    row "Auto-upgrade" "✗ $upgrade_result at $upgrade_time"
  fi
  row "Next run" "$next_run"
else
  row "Auto-upgrade" "not enabled — update by hand (~/bin/update)"
fi

if [[ -n "$btrbk_unit" ]]; then
  if [[ "$btrbk_state" == "activating" ]]; then
    row "Backup" "running now${success_ago:+  (last success $success_ago ago)}"
  elif [[ "$btrbk_result" == "success" ]]; then
    if [[ -n "$success_ago" ]]; then
      row "Backup" "✓ last success $success_ago ago"
    elif [[ -n "${btrbk_ran:-}" ]]; then
      row "Backup" "✓ last run ok at $btrbk_ran"
    else
      # systemd reports Result=success for a unit that has never run.
      row "Backup" "no run recorded — next $btrbk_next"
    fi
  else
    row "Backup" "✗ last run $btrbk_result${success_ago:+ — last success $success_ago ago}"
  fi
  row "Next backup" "$btrbk_next"
  row "Snapshots" "$snap_count local${oldest_age:+, spanning $oldest_age}"
else
  row "Backup" "no btrbk instance on this host"
fi

# df percentages, then the btrfs-specific one: a btrfs can report free space
# while having no unallocated chunks left, and then fail with ENOSPC.
root_pct="$(df --output=pcent / | tail -1 | tr -dc '0-9')"
row "Disk /" "$(df -h --output=used,size,pcent / | awk 'NR==2 {print $1" used / "$2"  ("$3")"}')  $(mark "$root_pct" 85)"
if boot_pct="$(df --output=pcent /boot 2>/dev/null | tail -1 | tr -dc '0-9')" && [[ -n "$boot_pct" ]]; then
  row "Disk /boot" "$(df -h --output=used,size,pcent /boot | awk 'NR==2 {print $1" used / "$2"  ("$3")"}')  $(mark "$boot_pct" 70)"
fi
unalloc="$(btrfs filesystem usage -b / 2>/dev/null | awk '/Device unallocated:/{print $3}')"
if [[ -n "$unalloc" ]]; then
  row "btrfs unallocated" "$(numfmt --to=iec "$unalloc")  $( (( unalloc < 10737418240 )) && printf '⚠' || printf '✓')"
fi
