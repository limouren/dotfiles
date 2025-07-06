{
  lib,
  pkgs,
  npmTools,
}:

pkgs.claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = npmTools.claude-code.version;

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = npmTools.claude-code.src_hash;
    };
  }
)
