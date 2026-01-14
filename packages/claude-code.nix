{
  fetchurl,
  claude-code,
}:

claude-code.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "2.1.7";

    src = fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
      hash = "sha256-iafHnlQkbYbnzJGI+/JVKnDzaVFE/RTe+r+A+Mge2HQ=";
    };
  }
)
