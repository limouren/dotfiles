{
  fetchurl,
  claude-code,
}:

claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.0.67";

    src = fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-HwT9YfoX44b18Sr1VdXMo0X7nIBrai1AAGPbV9l0zv8=";
    };
  }
)
