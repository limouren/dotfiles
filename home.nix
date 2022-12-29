{ config, lib, ... }:

let

  pkgs = import
    (fetchTarball {
      name = "nixos-unstable-2022-09-28";
      url = "https://github.com/NixOS/nixpkgs/archive/37c2766.tar.gz";
      # Hash obtained using `nix-prefetch-url --unpack <url>`
      sha256 = "0my1hkwnihnpfk0mf61b7vzbd5kfzyprq9xmsv5jdd274jp0y2zs";
    })
    {
      config.allowBroken = true;
    };

  pass = pkgs.pass.withExtensions (ext: [ ext.pass-update ]);

  pinentry = pkgs.pinentry_mac;

in

{
  # Disable symlink behaviour to avoid conflict with `copyApplications` activation
  # See https://github.com/nix-community/home-manager/issues/1341#issuecomment-1301555596
  disabledModules = [ "targets/darwin/linkapps.nix" ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "limouren";
  home.homeDirectory = "/Users/limouren";

  home.activation = {
    # See https://github.com/nix-community/home-manager/issues/1341#issuecomment-778820334
    copyApplications =
      let
        apps = pkgs.buildEnv {
          name = "home-manager-applications";
          paths = config.home.packages;
          pathsToLink = "/Applications";
        };
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        baseDir="$HOME/Applications/Home Manager Apps"
        if [ -d "$baseDir" ]; then
          rm -rf "$baseDir"
        fi
        mkdir -p "$baseDir"
        for appFile in ${apps}/Applications/*; do
          target="$baseDir/$(basename "$appFile")"
          $DRY_RUN_CMD cp ''${VERBOSE_ARG:+-v} -fHRL "$appFile" "$baseDir"
          $DRY_RUN_CMD chmod ''${VERBOSE_ARG:+-v} -R +w "$target"
        done
      '';
  };

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
    pkgs.asdf-vm
    pkgs.azure-cli
    # pkgs.blackbox
    # pkgs.cachix
    pkgs.cocoapods
    pkgs.dua
    pkgs.fzf
    pkgs.go
    ((drv: drv.withExtraComponents [ drv.components.gke-gcloud-auth-plugin ]) pkgs.google-cloud-sdk)
    pkgs.kubectl
    pkgs.kubectx
    pkgs.kubernetes-helm-wrapped
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
    pkgs.nodejs-16_x
    pkgs.nodejs-16_x.pkgs.yarn
    pkgs.nixpkgs-fmt
    pkgs.podman
    pkgs.poetry
    pkgs.postgresql
    pkgs.pwgen
    pkgs.qemu
    pkgs.youtube-dl
    pkgs.yq-go
    # pkgs.redis
    pkgs.ripgrep
    pkgs.ruby_3_1
    pkgs.tree
    pkgs.xh

    # gpg
    pkgs.gnupg

    # pass related
    pass
    pinentry
    pkgs.passff-host

    pkgs.nodePackages.pnpm
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.kitty.enable = true;
  programs.kitty.theme = "Ayu Mirage";
  programs.kitty.font = {
    name = "FiraCode Nerd Font";
    size = 14;
  };
  programs.kitty.keybindings = {
    "cmd+t" = "new_tab_with_cwd";
  };
  programs.kitty.settings = {
    shell_integration = "enabled";
    confirm_os_window_close = -1;
  };

  programs.fish.enable = true;
  programs.fish.plugins = [
    {
      # https://github.com/lilyball/nix-env.fish
      name = "nix-env.fish";
      src = pkgs.fetchFromGitHub
        {
          owner = "lilyball";
          repo = "nix-env.fish";
          rev = "7b65bd228429e852c8fdfa07601159130a818cfa";
          sha256 = "069ybzdj29s320wzdyxqjhmpm9ir5815yx6n522adav0z2nz8vs4";
        };
    }
  ];
  programs.fish.shellInit = ''
    eval (/opt/homebrew/bin/brew shellenv)
    # TODO: manage android studio & android sdk
    set PATH $PATH ~/Library/Android/sdk/platform-tools
  '';
  programs.fish.interactiveShellInit = ''
    if asdf current java > /dev/null 2>&1
      . ~/.asdf/plugins/java/set-java-home.fish
    end
  '';

  programs.starship.enable = true;
  programs.starship.enableFishIntegration = true;
  home.file.".config/starship.toml".source = ./starship.toml;

  programs.git.enable = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  nixpkgs.config.allowBroken = true;
}
