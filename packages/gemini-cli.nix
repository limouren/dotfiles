{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.1.19";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-KQiiJywp4zIBUx88tnhK6nD8GMhEipPlPxo0vlsOEXE=";
      postFetch = ''
        ${lib.getExe npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-pmm1ip9quQFuto5wlkj54Y7izQf79/sdpx+2uOAgbZI=";
    };

    dontCheckForBrokenSymlinks = true;
  }
)
