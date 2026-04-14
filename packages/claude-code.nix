{
  fetchzip,
  fetchNpmDeps,
  claude-code,
}:

let
  version = "2.1.105";
  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-IauZBWRzeatROeGOJI57fcD4Iz7NnmAtORf3lzaoOm4=";
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
      hash = "sha256-/oQxdQjMVS8r7e1DUPEjhWOLOD/hhVCx8gjEWb3ipZQ=";
    };
  }
)
