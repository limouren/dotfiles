{
  description = "Home Manager configuration of limouren";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/2f9173bde1d3fbf1ad26ff6d52f952f9e9da52ea";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util/9c6bbe2a6a7ec647d03f64f0fadb874284f59eac";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-env-fish = {
      url = "github:lilyball/nix-env.fish/7b65bd228429e852c8fdfa07601159130a818cfa";
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
    };
}
