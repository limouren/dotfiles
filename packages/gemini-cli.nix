{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.2.0";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-Vn50zF8QDDJrtCrqm8YSsIMV0k9mOROWEmBRfYHOT8I=";
      postFetch = ''
        ${lib.getExe npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-8Kn/3dNcUXcIvLjbg7l/UEsYZyuF3lekgZWYeTkeZQE=";
    };

    dontCheckForBrokenSymlinks = true;
  }
)
