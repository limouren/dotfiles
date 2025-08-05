{
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  npm-lockfile-fix,
  gemini-cli,
}:

gemini-cli.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "0.1.17";

    src = fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-4PnyJKAiRksiGac6/ibZ/DhFhCFsFn+hjEPqml2XVfk=";
    };

    patches = [ ./gemini-cli.patch ];

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src patches;
      hash = "sha256-+hKZmkifv96C7QZSkEC+HtJnRr0GUuQFmm4p7bjP97M=";
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
