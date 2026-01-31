{
  fetchzip,
  fetchNpmDeps,
  claude-code,
}:

let
  version = "2.1.27";
  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-Y1LBBBXtr7vlGC1vDox3jW+6N+U5MgNpFKsl+BhpHgE=";
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
