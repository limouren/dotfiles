{
  fetchurl,
  claude-code,
}:

claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.0.19";

    src = fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-ASVnmbrRQuXJWEQTOkrdNurfMg0VxEX88O3t/WnqXOs=";
    };
  }
)
