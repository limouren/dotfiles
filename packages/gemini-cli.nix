{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.1.17";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-J8IqmNifcqHaR5D2PXB5Hvm+C/J4cTbDRg9Sz+3A5k8=";
      postFetch = ''
        ${lib.getExe npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-lkU0KLSG8whi+9zRDjWe1cekSafovhjnrzq1IoWMrdA=";
    };

    dontCheckForBrokenSymlinks = true;
  }
)
