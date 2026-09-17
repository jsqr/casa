{
  description = "jsqr/casa - NixOS (melpomene, kalliope) + Home Manager (thalia)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Prebuilt nix-index database, regenerated upstream weekly. Pinned here so
    # it refreshes with `nix flake update` instead of a manual `nix-index` run.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The ashokan MCP server on melpomene is built from the ashokan repo's
    # uv.lock: uv2nix turns the lock into a python package set, and
    # build-system-pkgs supplies the build backends (hatchling here).
    # See hosts/melpomene/ashokan-mcp.nix.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The repo is private, so this is fetched over ssh as jj; the nightly
    # lock bump on melpomene runs as jj too, and the root build reuses what
    # that put in the store.
    ashokan = {
      url = "git+ssh://git@github.com/jsqr/ashokan.git?ref=main";
      flake = false;
    };

    # Only for homeModules.default: home-manager release-26.05 has no
    # programs.noctalia (master does). The package itself comes from
    # nixpkgs-unstable — see home/shells/noctalia.nix.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs: {
    nixosConfigurations.melpomene = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        home-manager.nixosModules.home-manager
        ./hosts/melpomene/configuration.nix
      ];
    };

    nixosConfigurations.kalliope = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        home-manager.nixosModules.home-manager
        inputs.disko.nixosModules.disko
        inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
        { home-manager.sharedModules = [ inputs.noctalia.homeModules.default ]; }
        ./hosts/kalliope/configuration.nix
      ];
    };

    homeConfigurations.thalia = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      extraSpecialArgs = { inherit inputs; };
      modules = [ ./home/thalia.nix ];
    };
  };
}
