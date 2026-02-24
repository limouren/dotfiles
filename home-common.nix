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
    pkgs.aria2
    pkgs.asdf-vm
    pkgs.ast-grep
    pkgs.awscli2
    # pkgs.aws-sam-cli
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
    pkgs.ghidra-bin
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
    pkgs.mpv
    pkgs.nginx
    pkgs.nixfmt
    pkgs.nodejs
    # pkgs.nodejs.pkgs.firebase-tools
    pkgs.nodejs.pkgs.pnpm
    pkgs.nodejs.pkgs.yarn
    pkgs.nurl
    pkgs.obsidian
    pkgs.overmind
    pkgs.oxipng
    pkgs.p7zip
    pkgs.php83
    pkgs.php83Packages.composer
    pkgs.podman
    pkgs.poetry
    pkgs.postgresql
    pkgs.pwgen
    pkgs.python312
    pkgs.qemu
    pkgs.uv
    pkgs.yq-go
    pkgs.yt-dlp
    pkgs.redis
    pkgs.ripgrep
    pkgs.rtorrent
    pkgs.ruby
    # pkgs.rustup
    pkgs.rye
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.sops
    pkgs.supabase-cli
    pkgs.svgo
    pkgs.temurin-bin-17
    pkgs.terraform
    pkgs.tree
    pkgs.typescript-go
    pkgs.unrar
    pkgs.usql
    pkgs.websocat
    pkgs.wrangler
    pkgs.python3Packages.weasyprint
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
    settings = {
      user = {
        email = "limouren@gmail.com";
        name = "Kenji Pa";
      };
      diff.blackbox.textconv = "gpg --use-agent -q --batch --decrypt";
      core.attributesfile = "${config.xdg.configHome}/git/attributes";
      url = {
        "https://" = {
          insteadof = "git://";
        };
      };
    };

  };
  home.file.".config/git/attributes".text = ''
    *.gpg diff=blackbox
  '';

  # git differ
  programs.riff = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.gitui.enable = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;
}
