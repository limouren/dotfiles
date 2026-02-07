{
  fetchzip,
  fetchNpmDeps,
  claude-code,
}:

let
  version = "2.1.34";
  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-J3kltFY5nR3PsRWbW310VqD/6hhfMbVSvynv0eaIi3M=";
  };
  postPatch = ''
    cp ${./claude-code-package-lock.json} package-lock.json
    substituteInPlace cli.js \
      --replace-warn '#!/bin/bash' '#!/usr/bin/env bash'
  '';
in
claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    inherit version src postPatch;

    # Must explicitly recalculate npmDeps when src changes
    npmDeps = fetchNpmDeps {
      inherit src postPatch;
      name = "claude-code-${version}-npm-deps";
      hash = "sha256-C8HVKSz1ZQmYNMoLUKk2XUpf5y+Np4nTacCGMVEqO8c=";
    };
  }
)
