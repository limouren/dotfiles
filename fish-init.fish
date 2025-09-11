if test $(uname -m) = "x86_64"
    eval (/usr/local/bin/brew shellenv)
else
    eval (/opt/homebrew/bin/brew shellenv)
end

# Ensure local bin precedes nix profile
set -g PATH $HOME/.local/bin $PATH

# https://developer.android.com/tools
# TODO: manage android studio & android sdk
set ANDROID_HOME ~/Library/Android/sdk
set PATH $PATH $ANDROID_HOME/emulator
set PATH $PATH $ANDROID_HOME/tools
set PATH $PATH $ANDROID_HOME/tools/bin
set PATH $PATH $ANDROID_HOME/platform-tools

# Sublime Text
set PATH $PATH '/Applications/Sublime Text.app/Contents/SharedSupport/bin'

# Point Docker to Podman socket
set -gx DOCKER_HOST "unix://"(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
