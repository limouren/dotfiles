{
  description = "Home Manager configuration for macOS and Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-env-fish = {
      url = "github:lilyball/nix-env.fish";
      flake = false;
    };
    nix-ai-tools = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-env-fish,
      nix-ai-tools,
      ...
    }:
    let
      mkHome =
        {
          system,
          modules,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit modules;
          extraSpecialArgs = {
            inherit nix-env-fish;
            ai-tools = nix-ai-tools.packages.${system};
          };
        };
    in
    {
      homeConfigurations."limouren" = mkHome {
        system = "aarch64-darwin";
        modules = [
          ./home-common.nix
          ./home-darwin.nix
        ];
      };

      homeConfigurations."bazzite" = mkHome {
        system = "x86_64-linux";
        modules = [
          ./home-common.nix
          ./home-bazzite.nix
        ];
      };

      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
