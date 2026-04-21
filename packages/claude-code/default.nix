{
  lib,
  stdenv,
  fetchurl,
  claude-code-bin,
}:

# Override nixpkgs's `claude-code-bin` with a `manifest.json` we control, so we
# can track upstream releases ahead of nixpkgs. The manifest format and release
# bucket mirror what nixpkgs itself uses for `claude-code-bin`; see
# `packages/claude-code/update.sh` for the bump script.
let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  manifest = lib.importJSON ./manifest.json;
  platformKey = "${stdenv.hostPlatform.node.platform}-${stdenv.hostPlatform.node.arch}";
  platformManifestEntry = manifest.platforms.${platformKey};
in
claude-code-bin.overrideAttrs (_: {
  inherit (manifest) version;

  src = fetchurl {
    url = "${baseUrl}/${manifest.version}/${platformKey}/claude";
    sha256 = platformManifestEntry.checksum;
  };
})
