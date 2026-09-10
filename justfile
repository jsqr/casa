# Bare `just` runs the first recipe, so `just` == `just check`.
#
# `thalia` evaluates rather than builds: it is aarch64-darwin and cannot be
# built from the Linux hosts. Forcing the drvPath still catches every type
# error, unknown option and bad interpolation — just not a compile failure.
# The reverse holds on thalia, where the two NixOS builds cannot run; use
# `just thalia` there.

# Check every host before committing
check: kalliope melpomene thalia

# Build the kalliope system closure
kalliope:
    nix build --no-link .#nixosConfigurations.kalliope.config.system.build.toplevel

# Build the melpomene system closure
melpomene:
    nix build --no-link .#nixosConfigurations.melpomene.config.system.build.toplevel

# Evaluate the thalia home-manager generation
thalia:
    nix eval --raw .#homeConfigurations.thalia.activationPackage.drvPath

# Show what switching to this checkout would change on the current host
diff:
    nix build --no-link --print-out-paths .#nixosConfigurations.$(hostname -s).config.system.build.toplevel \
      | xargs -I {} nix store diff-closures /run/current-system {}
