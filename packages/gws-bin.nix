{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.22.5";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/googleworkspace/cli/releases/download/v${version}/google-workspace-cli-aarch64-apple-darwin.tar.gz";
      hash = "sha256-HSqf/VvJssLEtIYw2vCC+tE9nlfXQZiKLCSO7VYvfaw=";
    };
    x86_64-darwin = {
      url = "https://github.com/googleworkspace/cli/releases/download/v${version}/google-workspace-cli-x86_64-apple-darwin.tar.gz";
      hash = "sha256-Ufm9cxQE1LuibDbi4w3WjFbczR+DTAElLLCxTWplRLI=";
    };
    aarch64-linux = {
      url = "https://github.com/googleworkspace/cli/releases/download/v${version}/google-workspace-cli-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-lEkCldlYDh6IV05xWgoWKZF0fRLWL4x7jcyCaLbBzqA=";
    };
    x86_64-linux = {
      url = "https://github.com/googleworkspace/cli/releases/download/v${version}/google-workspace-cli-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-3njs29LxqEzKAGOn7LxEAkD8FLbrzLsX9GRreSqMXB8=";
    };
  };

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
in

stdenvNoCC.mkDerivation {
  pname = "gws-bin";
  inherit version src;

  sourceRoot = ".";

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 gws $out/bin/gws
    runHook postInstall
  '';

  meta = {
    description = "Google Workspace CLI";
    homepage = "https://github.com/googleworkspace/cli";
    license = lib.licenses.asl20;
    mainProgram = "gws";
    platforms = builtins.attrNames sources;
  };
}
