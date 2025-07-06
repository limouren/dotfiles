{ pkgs ? import <nixpkgs> {} }:

let
  lib = pkgs.lib;
in
{
  claude-code = import ./claude-code.nix { inherit lib pkgs; };
  gemini-cli = import ./gemini-cli.nix { inherit lib pkgs; };
}