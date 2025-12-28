{
  config,
  pkgs,
  nix-env-fish,
  ai-tools,
  ...
}:

let
  package-overrides = import ./packages { inherit pkgs; };

  pass = pkgs.pass.withExtensions (ext: [
    ext.pass-update
    ext.pass-otp
  ]);

in

{
  home.file.".lnav/formats/installed/logcat_log.json".source = ./lnav-logcat.json;
  home.file.pass-completion = {
    target = ".config/fish/completions/pass.fish";
    source = pkgs.replaceVars ./pass-completion.fish {
      passCompletion = "${pkgs.pass}/share/fish/vendor_completions.d/pass.fish";
    };
  };

  home.packages = [
    ai-tools.codex

    pkgs.aria2
    pkgs.asdf-vm
    pkgs.ast-grep
    pkgs.awscli2
    pkgs.aws-sam-cli
    pkgs.blackbox
    pkgs.btop
    pkgs.bun
    pkgs.cachix
    pkgs.certbot
    pkgs.cloudflared
    pkgs.colima
    pkgs.devenv
    pkgs.dua
    pkgs.ffmpeg_8
    pkgs.fvm
    pkgs.fzf
    pkgs.gh
    pkgs.git-filter-repo
    pkgs.go
    pkgs.google-clasp
    ((drv: drv.withExtraComponents [ drv.components.gke-gcloud-auth-plugin ]) pkgs.google-cloud-sdk)
    pkgs.gnumake
    pkgs.kubectl
    pkgs.kubectx
    pkgs.kubernetes-helm-wrapped
    pkgs.imagemagick
    pkgs.innoextract
    pkgs.lftp
    pkgs.libcaca
    pkgs.libcaca.dev
    pkgs.lnav
    pkgs.nginx
    pkgs.nixfmt-rfc-style
    pkgs.nodejs
    pkgs.nodejs.pkgs.firebase-tools
    pkgs.nodejs.pkgs.pnpm
    pkgs.nodejs.pkgs.yarn
    pkgs.nurl
    pkgs.obsidian
    pkgs.overmind
    pkgs.oxipng
    pkgs.p7zip
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
    pkgs.rtorrent
    pkgs.ruby
    pkgs.rustup
    pkgs.rye
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.sops
    pkgs.svgo
    pkgs.temurin-bin-17
    pkgs.terraform
    pkgs.tree
    pkgs.unrar
    pkgs.usql
    pkgs.websocat
    pkgs.xh
    pkgs.zbar

    # gpg
    pkgs.gnupg

    # pass related
    pass
    pkgs.passff-host
  ]
  ++ (builtins.attrValues package-overrides);

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

  programs.fish.enable = true;
  programs.fish.plugins = [
    {
      # https://github.com/lilyball/nix-env.fish
      name = "nix-env.fish";
      src = nix-env-fish;
    }
  ];
  programs.fish.shellInit = builtins.readFile ./fish-init.fish;

  programs.starship.enable = true;
  programs.starship.enableFishIntegration = true;
  home.file.".config/starship.toml".source = ./starship.toml;

  programs.git = {
    enable = true;
    userEmail = "limouren@gmail.com";
    userName = "Kenji Pa";
    extraConfig = {
      diff.blackbox.textconv = "gpg --use-agent -q --batch --decrypt";
      core.attributesfile = "${config.xdg.configHome}/git/attributes";
      url = {
        "https://" = {
          insteadof = "git://";
        };
      };
    };

    riff.enable = true;
  };
  home.file.".config/git/attributes".text = ''
    *.gpg diff=blackbox
  '';

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;
}
