{
  lib,
  pkgs,
  npmTools,
}:

pkgs.gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = npmTools.gemini-cli.version;

    src = pkgs.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = npmTools.gemini-cli.src_hash;
      postFetch = ''
        ${lib.getExe pkgs.npm-lockfile-fix} $out/package-lock.json
      '';
    };

    npmDeps = pkgs.fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = npmTools.gemini-cli.npm_deps_hash;
    };
  }
)
