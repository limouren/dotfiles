{
  config,
  pkgs,
  nix-env-fish,
  ...
}:

let

  package-overrides = import ./packages { inherit pkgs; };

  pass = pkgs.pass.withExtensions (ext: [
    ext.pass-update
    ext.pass-otp
  ]);

  pinentry = pkgs.pinentry_mac;

in

{

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
  home.file.".lnav/formats/installed/logcat_log.json".source = ./lnav-logcat.json;
  home.file.passff-host = {
    target = "Library/Application Support/Mozilla/NativeMessagingHosts/passff.json";
    source = "${pkgs.passff-host}/share/passff-host/passff.json";
  };
  home.file.pass-completion = {
    target = ".config/fish/completions/pass.fish";
    source = pkgs.replaceVars ./pass-completion.fish {
      passCompletion = "${pkgs.pass}/share/fish/vendor_completions.d/pass.fish";
    };
  };

  home.packages = [
    pkgs.asdf-vm
    pkgs.blackbox
    pkgs.btop
    pkgs.bun
    pkgs.cachix
    pkgs.cloudflared
    pkgs.cocoapods
    pkgs.colima
    pkgs.devenv
    pkgs.dua
    pkgs.ffmpeg
    pkgs.fzf
    # pkgs.go
    # pkgs.gopls
    # pkgs.gotools
    # pkgs.go-outline
    pkgs.google-clasp
    ((drv: drv.withExtraComponents [ drv.components.gke-gcloud-auth-plugin ]) pkgs.google-cloud-sdk)
    pkgs.kubectl
    pkgs.kubectx
    pkgs.kubernetes-helm-wrapped
    pkgs.idb-companion
    pkgs.lftp
    pkgs.lnav
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
    pkgs.python312
    pkgs.qemu
    pkgs.yq-go
    pkgs.yt-dlp
    pkgs.redis
    pkgs.ripgrep
    pkgs.ruby_3_1
    pkgs.rye
    pkgs.shfmt
    pkgs.temurin-bin-17
    pkgs.terraform
    pkgs.tree
    pkgs.unrar
    pkgs.uv
    pkgs.xh
    pkgs.zbar

    # gpg
    pkgs.gnupg

    # pass related
    pass
    pinentry
    pkgs.passff-host

    pkgs.rustc
    pkgs.cargo
  ] ++ (builtins.attrValues package-overrides);

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

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
      src = nix-env-fish;
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
    set PATH $PATH $ANDROID_HOME/emulator
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
  nixpkgs.config.allowUnfree = true;
}
