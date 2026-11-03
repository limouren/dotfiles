{
  config,
  lib,
  pkgs,
  ...
}:

let
  pinentry = pkgs.pinentry_mac;
in

{
  imports = [ ./modules/dlsite-proxy ];

  services.dlsiteProxy.enable = true;

  home.username = "limouren";
  home.homeDirectory = "/Users/limouren";

  home.file.gpg-agent = {
    target = ".gnupg/gpg-agent.conf";
    text = ''
      pinentry-program ${pinentry}/${pinentry.binaryPath}
    '';
  };

  home.file.passff-host = {
    target = "Library/Application Support/Mozilla/NativeMessagingHosts/passff.json";
    source = "${pkgs.passff-host}/share/passff-host/passff.json";
  };

  home.file.".docker/contexts/meta/${builtins.hashString "sha256" "podman"}/meta.json".text =
    builtins.toJSON
      {
        Name = "podman";
        Metadata.Description = "Podman Machine";
        Endpoints.docker = {
          Host = "unix:///var/folders/d_/ztr6kc0s6_93ywr4cf51p7k00000gn/T/podman/podman-machine-default-api.sock";
          SkipTLSVerify = false;
        };
      };

  home.packages = [
    pkgs.cocoapods
    pkgs.idb-companion
    pkgs.terminal-notifier
    # pkgs.xcodegen

    pinentry
  ];

  launchd.agents.home-manager-sync = {
    enable = true;
    config = {
      ProgramArguments = [
        "${config.home.homeDirectory}/.config/home-manager/scripts/sync-and-switch.sh"
      ];
      StartInterval = 3600; # Run every hour
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/home-manager-sync.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/home-manager-sync.log";
    };
  };

  # rex.on handlers in init.lua need a later Rex, so they run as a script.
  launchd.agents.rex-auto-label = {
    enable = true;
    config = {
      ProgramArguments = [
        "${config.home.homeDirectory}/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
        "do"
        "--autostart=false"
        "${./rex/auto-label.lua}"
        "--all"
      ];
      EnvironmentVariables.PATH = "${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin";
      # Rex Beta.app starts the server, which may come up after login.
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/rex-auto-label.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/rex-auto-label.log";
    };
  };

  launchd.agents.agent-taste-mine = {
    enable = true;
    config = {
      ProgramArguments = [
        "${config.home.homeDirectory}/agent-things/taste/run.sh"
        "mine"
      ];
      EnvironmentVariables = {
        PATH = "${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin";
        TASTE_HOST = "mac";
      };
      StartCalendarInterval = [
        {
          Hour = 3;
          Minute = 0;
        }
      ];
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/agent-taste.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/agent-taste.log";
    };
  };
}
