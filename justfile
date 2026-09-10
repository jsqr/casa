# Bare `just` runs the first recipe, so `just` == `just check`.
#
# On thalia, we evaluate rather than building; aarch64-darwin can't be
# built from the Linux hosts. Forcing the drvPath still catches every type
# error, unknown option and bad interpolation (just not a compile failure).
# The reverse holds on thalia, where the two NixOS builds cannot run; use
# `just thalia` there.

# Check every host before committing
check: kalliope melpomene thalia

# Build kalliope system closure
kalliope:
    nix build --no-link .#nixosConfigurations.kalliope.config.system.build.toplevel

# Build melpomene system closure
melpomene:
    nix build --no-link .#nixosConfigurations.melpomene.config.system.build.toplevel

# Evaluate the thalia home-manager generation
thalia:
    nix eval --raw .#homeConfigurations.thalia.activationPackage.drvPath

# Show what switching to this checkout would change on the current host
diff:
    nix build --no-link --print-out-paths .#nixosConfigurations.$(hostname -s).config.system.build.toplevel \
      | xargs -I {} nix store diff-closures /run/current-system {}

# Switch the running system to this checkout; refuse if any mount changed
switch:
    #!/usr/bin/env bash
    set -euo pipefail
    host=$(hostname -s)
    new=$(nix build --no-link --print-out-paths ".#nixosConfigurations.$host.config.system.build.toplevel")
    if ! diff -q <(grep -v '^#' /etc/fstab) <(grep -v '^#' "$new/etc/fstab") >/dev/null; then
        echo "fstab differs. A live switch restarts local-fs.target, which stranded" >&2
        echo "this machine on 2026-09-10. Use 'just stage' and reboot instead." >&2
        exit 1
    fi
    sudo nixos-rebuild switch --flake ".#$host" 2>&1 | tee /tmp/switch.log

# Stage this checkout for the next boot; the safe path for fileSystems changes
stage:
    sudo nixos-rebuild boot --flake .#$(hostname -s) 2>&1 | tee /tmp/switch.log
    @echo "Staged. Reboot to apply."

# Make the previous generation the default boot entry
rollback:
    sudo nixos-rebuild --rollback boot
    @echo "Previous generation is now default. Reboot to use it."
