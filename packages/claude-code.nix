{
  fetchurl,
  claude-code,
}:

claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.0.57";

    src = fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-ymyg21CgjALM3+oWk7haC+CvYuN54+mlQQefQF2hMCs=";
    };
  }
)
