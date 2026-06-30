{
  config,
  lib,
  pkgs,
  ...
}:

let
  passffJson = builtins.toJSON {
    name = "passff";
    description = "Host for communicating with zx2c4 pass";
    path = "${config.home.homeDirectory}/.local/bin/passff-host";
    type = "stdio";
    allowed_extensions = [ "passff@invicem.pro" ];
  };

  passffHostScript = ''
    #!/bin/sh
    exec flatpak-spawn --host ${pkgs.passff-host}/share/passff-host/passff.py "$@"
  '';
in

{
  home.username = "bazzite";
  home.homeDirectory = "/home/bazzite";

  home.file.gpg-agent = {
    target = ".gnupg/gpg-agent.conf";
    text = ''
      pinentry-program /usr/bin/pinentry-qt
    '';
  };

  services.flatpak = {
    enable = true;
    packages = [
      "io.github.ilya_zlobintsev.LACT"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };

  programs.fish.shellAliases = {
    lact = "flatpak run io.github.ilya_zlobintsev.LACT";
  };

  # passff-host for Flatpak Firefox
  home.activation.passff-host = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${config.home.homeDirectory}/.var/app/org.mozilla.firefox/.mozilla/native-messaging-hosts"
        run mkdir -p "${config.home.homeDirectory}/.local/bin"

        run cat > "${config.home.homeDirectory}/.var/app/org.mozilla.firefox/.mozilla/native-messaging-hosts/passff.json" << 'EOF'
    ${passffJson}
    EOF

        run cat > "${config.home.homeDirectory}/.local/bin/passff-host" << 'EOF'
    ${passffHostScript}
    EOF
        run chmod +x "${config.home.homeDirectory}/.local/bin/passff-host"
  '';
}
