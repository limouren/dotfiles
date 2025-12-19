{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  writeShellApplication,
  cacert,
  curl,
  gnused,
  jq,
  openssl,
}:

let
  version = "0.24.0";

  srcByPlatform = {
    "aarch64-darwin" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-darwin-arm64.tar.gz";
      hash = "sha256-N8LdZU/yni83UE9DpJZ05S3F3F5GW9yWHklZHrORuaQ=";
    };
    "x86_64-darwin" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-darwin-x64.tar.gz";
      hash = "sha256-yA5a/2wOY0beQFSrKGrWO5bS+amU5ufIINkDUanhVxM=";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-linux-x64.tar.gz";
      hash = "sha256-HroMBZ0sW1OO1CKybUyjpxjIILOrJELikuha24MO3BU=";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/badlogic/pi-mono/releases/download/v${version}/pi-linux-arm64.tar.gz";
      hash = "sha256-uum3J4ndH2uhq6fnqBnG+tiiqdODJRqfQ14rS2lrWCE=";
    };
  };
in

stdenv.mkDerivation {
  pname = "pi-coding-agent";
  inherit version;

  src = srcByPlatform.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;

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

  passthru.updateScript = lib.getExe (writeShellApplication {
    name = "pi-coding-agent-update-script";
    runtimeInputs = [
      cacert
      curl
      gnused
      jq
      openssl
    ];
    text = ''
      version=$(curl -s "https://api.github.com/repos/badlogic/pi-mono/releases/latest" | jq -r '.tag_name' | sed 's/^v//')

      base_url="https://github.com/badlogic/pi-mono/releases/download/v$version"

      darwin_arm64_hash="sha256-$(curl -sL "$base_url/pi-darwin-arm64.tar.gz" | openssl dgst -sha256 -binary | openssl base64)"
      darwin_x64_hash="sha256-$(curl -sL "$base_url/pi-darwin-x64.tar.gz" | openssl dgst -sha256 -binary | openssl base64)"
      linux_x64_hash="sha256-$(curl -sL "$base_url/pi-linux-x64.tar.gz" | openssl dgst -sha256 -binary | openssl base64)"
      linux_arm64_hash="sha256-$(curl -sL "$base_url/pi-linux-arm64.tar.gz" | openssl dgst -sha256 -binary | openssl base64)"

      sed -i -E \
        -e 's|(version = )"[0-9]+\.[0-9]+\.[0-9]+";|\1"'"$version"'";|' \
        -e '/aarch64-darwin.*fetchurl/,/};/ s|(hash = )"sha256-[A-Za-z0-9+/]+=";|\1"'"$darwin_arm64_hash"'";|' \
        -e '/x86_64-darwin.*fetchurl/,/};/ s|(hash = )"sha256-[A-Za-z0-9+/]+=";|\1"'"$darwin_x64_hash"'";|' \
        -e '/x86_64-linux.*fetchurl/,/};/ s|(hash = )"sha256-[A-Za-z0-9+/]+=";|\1"'"$linux_x64_hash"'";|' \
        -e '/aarch64-linux.*fetchurl/,/};/ s|(hash = )"sha256-[A-Za-z0-9+/]+=";|\1"'"$linux_arm64_hash"'";|' \
        ./packages/pi-coding-agent.nix
    '';
  });

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
