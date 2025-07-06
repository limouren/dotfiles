{
  lib,
  pkgs,
}:

pkgs.gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.1.9";

    src = pkgs.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-o+AczO0SXnWeXth5gKRadeURLM4RsWvbSYRroXVIx5g=";
      postFetch = ''
        ${lib.getExe pkgs.npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = pkgs.fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-xwW0ZtpTYGirMIpSPGdkbNlVicNzsRDlgeysJKkdyHI=";
    };
  }
)
