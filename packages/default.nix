{
  pkgs ? import <nixpkgs> { },
}:

{
  blackbox = pkgs.callPackage ./blackbox.nix { };
  claude-code = pkgs.callPackage ./claude-code.nix { };
  gws-bin = pkgs.callPackage ./gws-bin.nix { };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent { };
}
// pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  class-dump = pkgs.callPackage ./class-dump.nix { };
  mssql-tools = pkgs.callPackage ./mssql-tools.nix { };
}
