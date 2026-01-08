{
  lib,
  buildNpmPackage,
  fetchurl,
  fd,
  ripgrep,
  runCommand,
}:

let
  # Courtesy of https://github.com/numtide/llm-agents.nix/tree/e97b6b7f84a04ef9ae449f8af4cf8eb524673927/packages/pi
  versionData = lib.importJSON ./hashes.json;
  version = versionData.version;

  srcWithLock = runCommand "pi-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
        hash = versionData.sourceHash;
      }
    } -C $out --strip-components=1
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  pname = "pi-coding-agent";
  inherit version;

  src = srcWithLock;

  npmDepsHash = versionData.npmDepsHash;

  dontNpmBuild = true;

  postInstall = ''
    wrapProgram $out/bin/pi \
      --prefix PATH : ${
        lib.makeBinPath [
          fd
          ripgrep
        ]
      }
  '';

  meta = {
    description = "Terminal-based coding agent with multi-model support";
    homepage = "https://github.com/badlogic/pi-mono";
    changelog = "https://github.com/badlogic/pi-mono/releases";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
}
