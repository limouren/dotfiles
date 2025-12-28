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

  home.packages = [
    pkgs.cocoapods
    pkgs.idb-companion
    pkgs.terminal-notifier
    pkgs.xcodegen

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
}
