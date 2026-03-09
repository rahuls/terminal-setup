#!/usr/bin/env bash

set -euo pipefail

log() {
	printf '[brew] %s\n' "$1"
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

main() {
	if [[ "$(uname -s)" != "Darwin" ]]; then
		log "Non-macOS machine detected, skipping Homebrew setup"
		exit 0
	fi

	if ! command_exists brew; then
		log "Installing Homebrew"
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		# Add brew to PATH for the current script execution.
		if [[ -x /opt/homebrew/bin/brew ]]; then
			eval "$(/opt/homebrew/bin/brew shellenv)"
		elif [[ -x /usr/local/bin/brew ]]; then
			eval "$(/usr/local/bin/brew shellenv)"
		fi
	else
		log "Homebrew already installed"
	fi

	log "Updating Homebrew to latest"
	brew update
	brew upgrade
	log "Homebrew is ready"
}

main "$@"
