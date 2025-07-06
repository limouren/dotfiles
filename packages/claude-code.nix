{
  lib,
  pkgs,
}:

pkgs.claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.2.65";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-IkUwgt1ympmvwivyUjAxPQHVhnvtOog34arcNA/GinM=";
    };
  }
)
