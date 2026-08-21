{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.1.0";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/oursky/kube-authgear-login/releases/download/v${version}/kubectl-authgear_login_${version}_darwin_arm64.tar.gz";
      hash = "sha256-98n91fE/cQLmpwedNnxWqfHgR1MI8wNi3xp7t19GUfo=";
    };
    x86_64-darwin = {
      url = "https://github.com/oursky/kube-authgear-login/releases/download/v${version}/kubectl-authgear_login_${version}_darwin_amd64.tar.gz";
      hash = "sha256-OdPIgk83vIWHCF0VnjbmcJFCnUouTJlelfPxfAGSDvQ=";
    };
    aarch64-linux = {
      url = "https://github.com/oursky/kube-authgear-login/releases/download/v${version}/kubectl-authgear_login_${version}_linux_arm64.tar.gz";
      hash = "sha256-IucFx5kIm/HjJSabuKrD4eXYcD2YQDdiGW0zhI5M2pE=";
    };
    x86_64-linux = {
      url = "https://github.com/oursky/kube-authgear-login/releases/download/v${version}/kubectl-authgear_login_${version}_linux_amd64.tar.gz";
      hash = "sha256-rG0giHVty6caijG6rh6Q8M5jdD/8P3eINSWjTBy0q7g=";
    };
  };

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
in

stdenvNoCC.mkDerivation {
  pname = "kube-authgear-login";
  inherit version src;

  sourceRoot = ".";

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 kubectl-authgear_login $out/bin/kubectl-authgear_login
    runHook postInstall
  '';

  meta = {
    description = "Kubectl credential plugin for Authgear";
    homepage = "https://github.com/oursky/kube-authgear-login";
    license = lib.licenses.mit;
    mainProgram = "kubectl-authgear_login";
    platforms = builtins.attrNames sources;
  };
}
