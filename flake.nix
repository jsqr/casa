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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
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
