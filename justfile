# Bare `just` lists the recipes and does nothing else.
#
# A host is built when its platform matches this machine's and evaluated
# otherwise: kalliope and melpomene are x86_64-linux, thalia is
# aarch64-darwin. Forcing the drvPath still catches every type error,
# unknown option and bad interpolation (just not a compile failure).
#
# `switch` acts on the running system: nixos-rebuild on NixOS,
# home-manager elsewhere. The other generation recipes are nixos-rebuild
# only and refuse to run anywhere but NixOS.

nix_system := arch() + "-" + if os() == "macos" { "darwin" } else { os() }

# List the recipes
default:
    @just --list

# Check every host before committing
check: kalliope melpomene thalia

# Check kalliope's system closure
kalliope:
    @just _host x86_64-linux nixosConfigurations.kalliope.config.system.build.toplevel

# Check melpomene's system closure
melpomene:
    @just _host x86_64-linux nixosConfigurations.melpomene.config.system.build.toplevel

# Check the thalia home-manager generation
thalia:
    @just _host aarch64-darwin homeConfigurations.thalia.activationPackage

# Build a flake output on its own platform, evaluate it on any other
_host system output:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{system}}" = "{{nix_system}}" ]; then
        nix build --no-link ".#{{output}}"
    else
        echo "{{output}}: {{system}}, evaluating only on {{nix_system}}"
        nix eval --raw ".#{{output}}.drvPath" >/dev/null
    fi

# Refuse a NixOS-only recipe elsewhere
_nixos recipe:
    #!/usr/bin/env bash
    if [ ! -e /etc/NIXOS ]; then
        echo "just {{recipe}}: NixOS only, and this is $(hostname -s) ({{nix_system}})" >&2
        exit 1
    fi

# Show what switching to this checkout would change on the current host
diff: (_nixos "diff")
    nix build --no-link --print-out-paths .#nixosConfigurations.$(hostname -s).config.system.build.toplevel \
      | xargs -I {} nix store diff-closures /run/current-system {}

# Switch this host to this checkout
switch:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -e /etc/NIXOS ]; then
        just _switch-nixos
    else
        just _switch-home
    fi

# Switch the running system; refuse if a mount or systemd changed
_switch-nixos:
    #!/usr/bin/env bash
    set -euo pipefail
    host=$(hostname -s)
    new=$(nix build --no-link --print-out-paths ".#nixosConfigurations.$host.config.system.build.toplevel")
    if ! diff -q <(grep -v '^#' /etc/fstab) <(grep -v '^#' "$new/etc/fstab") >/dev/null; then
        echo "fstab differs. A live switch restarts local-fs.target, which stranded" >&2
        echo "this machine on 2026-09-10. Use 'just stage' and reboot instead." >&2
        exit 1
    fi
    if [ "$(readlink /run/current-system/systemd)" != "$(readlink "$new/systemd")" ]; then
        echo "systemd differs. A live switch re-executes PID 1, which froze this" >&2
        echo "machine on 2026-09-22. Use 'just stage' and reboot instead." >&2
        exit 1
    fi
    sudo nixos-rebuild switch --flake ".#$host" 2>&1 | tee /tmp/switch.log

# Activate the home-manager generation for this user. -b backup moves a
# colliding unmanaged file to <name>.backup instead of aborting activation.
_switch-home:
    home-manager switch -b backup --flake .#$(hostname -s) 2>&1 | tee /tmp/switch.log

# Stage this checkout for the next boot; the safe path for fileSystems changes
stage: (_nixos "stage")
    sudo nixos-rebuild boot --flake .#$(hostname -s) 2>&1 | tee /tmp/switch.log
    @echo "Staged. Reboot to apply."

# Make the previous generation the default boot entry
rollback: (_nixos "rollback")
    sudo nixos-rebuild --rollback boot
    @echo "Previous generation is now default. Reboot to use it."
