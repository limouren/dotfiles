{
  pkgs ? import <nixpkgs> { },
}:

{
  claude-code = pkgs.callPackage ./claude-code.nix { };
  # mssql-tools = pkgs.callPackage ./mssql-tools.nix { };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent.nix { };
  uv = pkgs.callPackage ./uv.nix { };
}
