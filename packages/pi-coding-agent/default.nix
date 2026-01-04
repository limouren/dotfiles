{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.33.0";

  srcByPlatform = {
    "aarch64-darwin" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-darwin-arm64.tar.gz";
      hash = "sha256-0rrGtk0+cXdBP8q1J0uVeNT4uJrxOE3HQuPT6jQki0o=";
    };
    "x86_64-darwin" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-darwin-x64.tar.gz";
      hash = "sha256-tMkofnq9MObgjW03a3lrvcOFQIih1GooAC926GcRAiE=";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-linux-x64.tar.gz";
      hash = "sha256-KPcCzpTITGqlNYaxpaHxSnhZZY5/FCPb5K+seVrCl9o=";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-linux-arm64.tar.gz";
      hash = "sha256-DAUN9U0DBE/Yafpr7axR0JY3izWbA55eaKpe41b5+Co=";
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
