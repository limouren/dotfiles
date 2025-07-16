{
  fetchurl,
  claude-code,
}:

claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.0.53";

    src = fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-P5cD3OPIbgAwvh5Iwm0hFUeTa+nDR/cu/hg1x6BlEAw=";
    };
  }
)
