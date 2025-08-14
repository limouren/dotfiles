{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.1.20";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-vnt2WXZmZQWyv6BOwY+y9Ja+fvx+yTN4rnqubApgiGo=";
      postFetch = ''
        ${lib.getExe npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-OaM7RUXjtqg5QklWQ8b3W582i12I73cl6VF6Tmt7Wrs=";
    };

    dontCheckForBrokenSymlinks = true;
  }
)
