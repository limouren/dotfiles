{
  pkgs ? import <nixpkgs> { },
}:

{
  claude-code = pkgs.callPackage ./claude-code.nix { };
  crush = pkgs.callPackage ./crush.nix { };
  gemini-cli = pkgs.callPackage ./gemini-cli.nix { };
}
