{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.1.21";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-4s+mU8BhJQDwLJtKcWTH0ks/W4n/FuEjWzT8aFQAPWI=";
      postFetch = ''
        ${lib.getExe npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-Q64lBWC0iLRPKGVjuDpwcqNHe/LTYsOtUmzW+5ZeSo8=";
    };

    dontCheckForBrokenSymlinks = true;
  }
)
