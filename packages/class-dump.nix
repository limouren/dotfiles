{
  lib,
  stdenv,
  fetchFromGitHub,
  apple-sdk_15,
}:

stdenv.mkDerivation rec {
  pname = "class-dump";
  version = "3.5-unstable-2024-01-17";

  src = fetchFromGitHub {
    owner = "nygard";
    repo = "class-dump";
    rev = "2c82b4ff12b2ea5d1ac23e49281d496997370841";
    hash = "sha256-kTOhM5SH1j/MDndx4zKd+5flEFeqs6BjGvluTRTGD34=";
  };

  buildInputs = [ apple-sdk_15 ];

  buildPhase = ''
    runHook preBuild

    sourceFiles=$(find Source -name '*.m' | sort)
    clang -arch arm64 \
      -fobjc-arc \
      -framework Foundation \
      -framework Security \
      -include class-dump-Prefix.pch \
      -ISource \
      -IThirdParty \
      -DCLASS_DUMP_VERSION='CLASS_DUMP_BASE_VERSION' \
      -DPLATFORM_IOSMAC=6 \
      -Wno-deprecated-declarations \
      -o class-dump \
      class-dump.m \
      ThirdParty/blowfish.c \
      $sourceFiles

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp class-dump $out/bin/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Command-line utility for examining Objective-C runtime information in Mach-O files";
    homepage = "https://github.com/nygard/class-dump";
    license = licenses.gpl2Plus;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "class-dump";
  };
}
