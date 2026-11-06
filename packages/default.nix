{
  pkgs ? import <nixpkgs> { },
}:

{
  blackbox = pkgs.callPackage ./blackbox.nix { };
  gws-bin = pkgs.callPackage ./gws-bin.nix { };
  herdr-core-bin = pkgs.callPackage ./herdr-core-bin { };
  kube-authgear-login = pkgs.callPackage ./kube-authgear-login.nix { };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent { };
}
// pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  class-dump = pkgs.callPackage ./class-dump.nix { };
  mssql-tools = pkgs.callPackage ./mssql-tools.nix { };
}
