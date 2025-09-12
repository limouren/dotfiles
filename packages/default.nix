{
  pkgs ? import <nixpkgs> { },
}:

{
  claude-code = pkgs.callPackage ./claude-code.nix { };
  mssql-tools = pkgs.callPackage ./mssql-tools.nix { };
  uv = pkgs.callPackage ./uv.nix { };
}
