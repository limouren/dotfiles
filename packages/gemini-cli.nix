{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.1.9";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-o+AczO0SXnWeXth5gKRadeURLM4RsWvbSYRroXVIx5g=";
      postFetch = ''
        ${lib.getExe npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-xwW0ZtpTYGirMIpSPGdkbNlVicNzsRDlgeysJKkdyHI=";
    };
  }
)
