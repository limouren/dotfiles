{ config, lib, ... }:

let

  pkgs =
    import
      (fetchTarball {
        name = "nixos-unstable-2025-02-11";
        url = "https://github.com/NixOS/nixpkgs/archive/b2243f41e860ac85c0b446eadc6930359b294e79.tar.gz";
        sha256 = "0bhibarcx56j1szd40ygv1nm78kap3yr4s24p5cv1kdiy4hsb21k";
      })
      {
        config.allowBroken = true;
        config.allowUnfree = true;
      };

  pass = pkgs.pass.withExtensions (ext: [
    ext.pass-update
    ext.pass-otp
  ]);

  pinentry = pkgs.pinentry_mac;

  mac-app-util-src = pkgs.fetchFromGitHub {
    owner = "hraban";
    repo = "mac-app-util";
    rev = "9c6bbe2a6a7ec647d03f64f0fadb874284f59eac";
    hash = "sha256-BqkwZ2mvzn+COdfIuzllSzWmiaBwQktt4sw9slfwM70=";
  };
  mac-app-util = (pkgs.callPackage mac-app-util-src { });

in

{
  imports = [ mac-app-util.homeManagerModules.default ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
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
    pkgs.asdf-vm
    pkgs.blackbox
    pkgs.btop
    pkgs.bun
    pkgs.cachix
    pkgs.cloudflared
    pkgs.cocoapods
    pkgs.devenv
    pkgs.dua
    pkgs.fzf
    # pkgs.go
    # pkgs.gopls
    # pkgs.gotools
    # pkgs.go-outline
    ((drv: drv.withExtraComponents [ drv.components.gke-gcloud-auth-plugin ]) pkgs.google-cloud-sdk)
    pkgs.kubectl
    pkgs.kubectx
    pkgs.kubernetes-helm-wrapped
    pkgs.idb-companion
    pkgs.lftp
    pkgs.nodejs
    pkgs.nodejs.pkgs.firebase-tools
    pkgs.nodejs.pkgs.yarn
    pkgs.nixfmt-rfc-style
    pkgs.nurl
    pkgs.overmind
    pkgs.podman
    pkgs.poetry
    pkgs.postgresql
    pkgs.pwgen
    pkgs.qemu
    pkgs.yq-go
    pkgs.python312
    pkgs.yt-dlp
    pkgs.redis
    pkgs.ripgrep
    pkgs.ruby_3_1
    pkgs.rye
    pkgs.temurin-bin-11
    pkgs.terraform
    pkgs.tree
    pkgs.unrar
    pkgs.uv
    pkgs.xh

    # gpg
    pkgs.gnupg

    # pass related
    pass
    pinentry
    pkgs.passff-host
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

  # programs.kitty.enable = true;
  # programs.kitty.themeFile = "ayu_mirage";
  # programs.kitty.font = {
  #   name = "FiraCode Nerd Font";
  #   size = 14;
  # };
  # programs.kitty.keybindings = {
  #   "cmd+t" = "new_tab_with_cwd";
  # };
  # programs.kitty.settings = {
  #   shell_integration = "enabled";
  #   confirm_os_window_close = -1;
  # };

  programs.fish.enable = true;
  programs.fish.plugins = [
    {
      # https://github.com/lilyball/nix-env.fish
      name = "nix-env.fish";
      src = pkgs.fetchFromGitHub {
        owner = "lilyball";
        repo = "nix-env.fish";
        rev = "7b65bd228429e852c8fdfa07601159130a818cfa";
        sha256 = "069ybzdj29s320wzdyxqjhmpm9ir5815yx6n522adav0z2nz8vs4";
      };
    }
  ];
  programs.fish.shellInit = ''
    if test $(uname -m) = "x86_64"
        eval (/usr/local/bin/brew shellenv)
    else
        eval (/opt/homebrew/bin/brew shellenv)
    end

    # https://developer.android.com/tools
    # TODO: manage android studio & android sdk
    set ANDROID_HOME ~/Library/Android/sdk
    set PATH $PATH $ANDROID_HOME/tools
    set PATH $PATH $ANDROID_HOME/tools/bin
    set PATH $PATH $ANDROID_HOME/platform-tools

    # Sublime Text
    set PATH $PATH '/Applications/Sublime Text.app/Contents/SharedSupport/bin'
  '';

  programs.starship.enable = true;
  programs.starship.enableFishIntegration = true;
  home.file.".config/starship.toml".source = ./starship.toml;

  programs.git = {
    enable = true;
    userEmail = "limouren@gmail.com";
    userName = "Kenji Pa";
    extraConfig = {
      url = {
        "https://" = {
          insteadof = "git://";
        };
      };
    };

    riff.enable = true;
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  nixpkgs.config.allowBroken = true;
}
