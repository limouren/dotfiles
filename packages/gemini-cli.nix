{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.1.22";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-m+5w1fWL+LD06Oozz9+2D38uEYkIzgVTwvMVEMZ83Ac=";
      postFetch = ''
        ${lib.getExe npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-5vF4ojal3RFv9qbRW9mvX8NaRzajiXNCDC3ZvmS2eAw=";
    };

    dontCheckForBrokenSymlinks = true;
  }
)
