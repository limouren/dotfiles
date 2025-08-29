{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.2.2";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-CLbwDORmXvSPAZnd8EV//QIz6UT9NX87aIfe5qnDXGU=";
      postFetch = ''
        ${lib.getExe npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-tb0hVzUxjiBF3Hm5YC6DYwsOdYW13PgjG15ZRWG849k=";
    };

    dontCheckForBrokenSymlinks = true;
  }
)
