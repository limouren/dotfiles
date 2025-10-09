{
  fetchurl,
  claude-code,
}:

claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.0.11";

    src = fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-kxNCkkeE02uWWSmrqOkJQRdCBM2i+gbXTRsiAw6x4gU=";
    };
  }
)
