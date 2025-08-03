{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.1.16";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-fFYlXmOqQm3s4Bt3Rgkvlyph+85AJCb5ttDYFC3jfVo=";
    };

    patches = [ ./gemini-cli.patch ];

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src patches;
      hash = "sha256-YIcz0Y9Ih87OxWjY4D3aZ/shRlpOZSfiHxVcXSN7Szc=";
    };

    postInstall =
      (prevAttrs.postInstall or "")
      + ''
        # Remove broken symlink to VSCode extension
        rm -f $out/share/gemini-cli/node_modules/gemini-cli-vscode-ide-companion

        # Copy VSCode extension to main output
        mkdir -p $out/share/vscode/extensions
        cp packages/vscode-ide-companion/gemini-cli-vscode-ide-companion-${finalAttrs.version}.vsix $out/share/vscode/extensions/
      '';
  }
)
