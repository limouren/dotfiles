{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "null";

  srcByPlatform = {
    "aarch64-darwin" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-darwin-arm64.tar.gz";
      hash = "sha256-ABnfxLMtY8E5KqJkrtIlPB4ML7CSFvjizCabv7i7SbU=";
    };
    "x86_64-darwin" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-darwin-x64.tar.gz";
      hash = "sha256-ABnfxLMtY8E5KqJkrtIlPB4ML7CSFvjizCabv7i7SbU=";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-linux-x64.tar.gz";
      hash = "sha256-ABnfxLMtY8E5KqJkrtIlPB4ML7CSFvjizCabv7i7SbU=";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-linux-arm64.tar.gz";
      hash = "sha256-ABnfxLMtY8E5KqJkrtIlPB4ML7CSFvjizCabv7i7SbU=";
    };
  };
in

stdenv.mkDerivation {
  pname = "pi-coding-agent";
  inherit version;

  src = srcByPlatform.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  unpackPhase = ''
    tar -xzf $src
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi-coding-agent
    cp -r . $out/lib/pi-coding-agent/

    mkdir -p $out/bin
    ln -s $out/lib/pi-coding-agent/pi $out/bin/pi

    runHook postInstall
  '';

  meta = {
    description = "Terminal-based coding agent with multi-model support";
    homepage = "https://github.com/badlogic/pi-mono";
    license = lib.licenses.mit;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "pi";
  };
}
