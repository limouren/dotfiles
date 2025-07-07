{
  description = "Home Manager configuration of limouren";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-env-fish = {
      url = "github:lilyball/nix-env.fish";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      mac-app-util,
      nix-env-fish,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."limouren" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix
          mac-app-util.homeManagerModules.default
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          inherit nix-env-fish;
        };
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
