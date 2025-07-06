{
  lib,
  pkgs,
}:

pkgs.claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.0.43";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-t8XunDJEt8jdShec4AtelTBmQ3KtWPMOgMxjxuMveRU=";
    };
  }
)
