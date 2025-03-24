## Getting Started

1. `git clone https://github.com/limouren/dotfiles ~/.config/home-manager`
2. [Optional] Restore backup if needed:
   1. `make restore`
   2. `cp -r backup/.gnupg/ ~/.gnupg && chmod 700 ~/.gnupg`
   3. `cp -r backup/.ssh ~`
3. [Install lix](https://lix.systems/install/)
4. Install [standalone home-manager](https://nix-community.github.io/home-manager/#sec-install-standalone)
5. `home-manager switch`
6. `sudo vi /etc/shells` and add `/Users/limouren/.nix-profile/bin/fish`
7. `chsh -s /Users/limouren/.nix-profile/bin/fish`
