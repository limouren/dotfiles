{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "blackbox";
  version = "1.20220610";

  src = fetchFromGitHub {
    owner = "StackExchange";
    repo = "blackbox";
    rev = "v${finalAttrs.version}";
    hash = "sha256-g0oNV7Nj7ZMmsVQFVTDwbKtF4a/Fb3WDB+NRx9IGSWA=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin bin/blackbox_*
    install -Dm644 -t $out/bin bin/_blackbox_common.sh bin/_stack_lib.sh
    runHook postInstall
  '';

  meta = {
    description = "Safely store secrets in Git/Mercurial/Subversion";
    homepage = "https://github.com/StackExchange/blackbox";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.all;
    mainProgram = "blackbox_postdeploy";
  };
})
