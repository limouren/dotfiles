{
  config,
  lib,
  pkgs,
  ...
}:

let
  herdr = (import ./packages { inherit pkgs; }).herdr-bin;

  herdrUpgrade = pkgs.writeShellApplication {
    name = "herdr-upgrade";
    runtimeInputs = [
      pkgs.jq
      pkgs.procps
    ];
    text = builtins.readFile ./scripts/herdr-upgrade.sh;
  };

  hostServicePath = "PATH=${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin";

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

  systemd.user.services.herdr = {
    Unit = {
      Description = "Herdr session server";
      # A restart kills every pane. herdr-upgrade hands off to the new version instead.
      X-SwitchMethod = "keep-old";
    };
    Service = {
      ExecStart = "${lib.getExe herdr} server";
      # A live handoff replaces the main process with a new server in the cgroup.
      ExitType = "cgroup";
      Restart = "on-failure";
      WorkingDirectory = "%h";
      Environment = [ hostServicePath ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.herdr-upgrade = {
    Unit.Description = "Move herdr to the current version without killing panes";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe herdrUpgrade;
      # May wait for all panes to become idle.
      TimeoutStartSec = "infinity";
      Environment = [
        hostServicePath
        "HERDR_BIN=${lib.getExe herdr}"
      ];
    };
  };

  # A separate unit, so the handoff does not depend on the switch process,
  # which may run inside a herdr pane.
  home.activation.herdrUpgrade = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    run env XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
      ${pkgs.systemd}/bin/systemctl --user start --no-block herdr-upgrade.service \
      || warnEcho "Could not start herdr-upgrade.service"
  '';

  systemd.user.services.home-manager-sync = {
    Unit = {
      Description = "Pull and switch Home Manager configuration";
      # The service runs home-manager switch, which must not restart it.
      X-SwitchMethod = "keep-old";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.config/home-manager/scripts/sync-and-switch.sh";
      Environment = [ hostServicePath ];
    };
  };

  systemd.user.timers.home-manager-sync = {
    Unit.Description = "Pull and switch Home Manager configuration hourly";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
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
