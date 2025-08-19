{
  fetchurl,
  claude-code,
}:

claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "1.0.84";

    src = fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-m4yrbnak2Et48CkJmOKZ7zfvi4j+WL+ZMeTTx5rERR0=";
    };
  }
)
