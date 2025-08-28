{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.2.1";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-ldQ7Qwm5dm/iLXem5WhokdO5d6CUwVxQbHUR0bb7WJ0=";
      postFetch = ''
        ${lib.getExe npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-247zfZG0RarO2iW97EHWBjMiIdc+fIfuD3n+Js9TJj4=";
    };

    dontCheckForBrokenSymlinks = true;
  }
)
