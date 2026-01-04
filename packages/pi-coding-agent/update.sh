#!/usr/bin/env bash

set -euo pipefail

version=$(curl -s "https://api.github.com/repos/badlogic/pi-mono/releases/latest" | jq -r '.tag_name' | sed 's/^v//')

base_url="https://github.com/badlogic/pi-mono/releases/download/v$version"

darwin_arm64_hash="sha256-$(curl -sL "$base_url/pi-darwin-arm64.tar.gz" | openssl dgst -sha256 -binary | openssl base64)"
darwin_x64_hash="sha256-$(curl -sL "$base_url/pi-darwin-x64.tar.gz" | openssl dgst -sha256 -binary | openssl base64)"
linux_x64_hash="sha256-$(curl -sL "$base_url/pi-linux-x64.tar.gz" | openssl dgst -sha256 -binary | openssl base64)"
linux_arm64_hash="sha256-$(curl -sL "$base_url/pi-linux-arm64.tar.gz" | openssl dgst -sha256 -binary | openssl base64)"

sed -i '' -E \
	-e 's|(version = )"[^"]+";|\1"'"$version"'";|' \
	-e '/aarch64-darwin.*fetchurl/,/};/ s|(hash = )"sha256-[A-Za-z0-9+/]+=";|\1"'"$darwin_arm64_hash"'";|' \
	-e '/x86_64-darwin.*fetchurl/,/};/ s|(hash = )"sha256-[A-Za-z0-9+/]+=";|\1"'"$darwin_x64_hash"'";|' \
	-e '/x86_64-linux.*fetchurl/,/};/ s|(hash = )"sha256-[A-Za-z0-9+/]+=";|\1"'"$linux_x64_hash"'";|' \
	-e '/aarch64-linux.*fetchurl/,/};/ s|(hash = )"sha256-[A-Za-z0-9+/]+=";|\1"'"$linux_arm64_hash"'";|' \
	./packages/pi-coding-agent/default.nix
