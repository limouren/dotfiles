{
  lib,
  stdenv,
  fetchurl,
  unixODBC,
  openssl,
  unixODBCDrivers,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "mssql-tools";
  version = "18.4.1.1";

  src = fetchurl (
    if stdenv.hostPlatform.isAarch64 then
      {
        url = "https://download.microsoft.com/download/f/0/e/f0e1f86e-1647-480f-b649-27741eea9642/mssql-tools18-${version}-arm64.tar.gz";
        sha256 = "26eff3ea30c8dd9e003916263f1bbef6d8cb06554d437b04029a2dccfd87028a";
      }
    else
      {
        url = "https://download.microsoft.com/download/f/0/e/f0e1f86e-1647-480f-b649-27741eea9642/mssql-tools18-${version}-amd64.tar.gz";
        sha256 = "a2d5a454a5f9eb1503f3a33205d13e99587113acfb5a1f48f13d9fa44ad2f909";
      }
  );

  buildInputs = [
    unixODBC
    openssl
  ];

  nativeBuildInputs =
    lib.optionals stdenv.hostPlatform.isDarwin [
      stdenv.cc.bintools.bintools
    ]
    ++ [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share
    mkdir -p $out/etc

    # Copy binaries
    cp -r bin/* $out/bin/

    # Copy resources (needed for sqlcmd and bcp)
    if [ -d "share" ]; then
      cp -r share/* $out/share/
    fi
    if [ -d "resources" ]; then
      cp -r resources $out/share/
    fi

    # Create ODBC configuration files
    cat > $out/etc/odbcinst.ini <<EOF
    [ODBC Driver 18 for SQL Server]
    Description=Microsoft ODBC Driver 18 for SQL Server
    Driver=${unixODBCDrivers.msodbcsql18}/lib/libmsodbcsql.18.dylib
    UsageCount=1
    EOF

    # Rename original binaries
    mv $out/bin/sqlcmd $out/bin/.sqlcmd-unwrapped
    mv $out/bin/bcp $out/bin/.bcp-unwrapped

    # Make binaries executable
    chmod +x $out/bin/.sqlcmd-unwrapped
    chmod +x $out/bin/.bcp-unwrapped

    # Fix dynamic library paths on macOS
    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      for binary in .sqlcmd-unwrapped .bcp-unwrapped; do
        # Fix ODBC library path
        install_name_tool -change /opt/homebrew/lib/libodbc.2.dylib ${unixODBC}/lib/libodbc.2.dylib $out/bin/$binary || true
        # Fix OpenSSL library paths
        install_name_tool -change /opt/homebrew/lib/libssl.3.dylib ${openssl}/lib/libssl.3.dylib $out/bin/$binary || true
        install_name_tool -change /opt/homebrew/lib/libcrypto.3.dylib ${openssl}/lib/libcrypto.3.dylib $out/bin/$binary || true
      done
    ''}

    # Create wrapper scripts that set ODBCSYSINI
    makeWrapper $out/bin/.sqlcmd-unwrapped $out/bin/sqlcmd \
      --set ODBCSYSINI $out/etc

    makeWrapper $out/bin/.bcp-unwrapped $out/bin/bcp \
      --set ODBCSYSINI $out/etc

    runHook postInstall
  '';

  meta = with lib; {
    description = "Sqlcmd and Bcp for Microsoft(R) SQL Server(R)";
    homepage = "https://msdn.microsoft.com/en-us/library/ms162773.aspx";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = platforms.darwin;
    mainProgram = "sqlcmd";
  };
}
