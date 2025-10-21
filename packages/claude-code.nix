{
  fetchurl,
  claude-code,
}:

claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.0.24";

    src = fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-c/35HU9IBWXUiBkH0Ua5enfV6ytACZDUql6bn6NuKLQ=";
    };
  }
)
