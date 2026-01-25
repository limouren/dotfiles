{
  pkgs ? import <nixpkgs> { },
}:

{
  claude-code = pkgs.callPackage ./claude-code.nix { };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent { };
  uv = pkgs.callPackage ./uv.nix { };
}
// pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  mssql-tools = pkgs.callPackage ./mssql-tools.nix { };
}
