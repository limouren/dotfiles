# macOS-specific configuration
if test (uname) = Darwin
    # Homebrew initialization
    if test -x /usr/local/bin/brew
        eval (/usr/local/bin/brew shellenv)
    else if test -x /opt/homebrew/bin/brew
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
    if test -d '/Applications/Sublime Text.app/Contents/SharedSupport/bin'
        set PATH $PATH '/Applications/Sublime Text.app/Contents/SharedSupport/bin'
    end

    # Point Docker to Podman machine socket
    if command -v podman &>/dev/null
        set -gx DOCKER_HOST "unix://"(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
    end
end

# Ensure local bin precedes nix profile
set -g PATH $HOME/.local/bin $PATH
