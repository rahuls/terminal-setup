#!/usr/bin/env bash
# run this script by chmod +x setup.sh && bash -n setup.sh
set -euo pipefail

log() {
	printf '[setup] %s\n' "$1"
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

install_zsh() {
	if command_exists zsh; then
		log "zsh is already installed"
		return
	fi

	log "Installing zsh"

	if command_exists apt-get; then
		sudo apt-get update
		sudo apt-get install -y zsh
	elif command_exists dnf; then
		sudo dnf install -y zsh
	elif command_exists yum; then
		sudo yum install -y zsh
	elif command_exists pacman; then
		sudo pacman -Sy --noconfirm zsh
	elif command_exists zypper; then
		sudo zypper --non-interactive install zsh
	elif command_exists brew; then
		brew install zsh
	else
		log "No supported package manager found. Install zsh manually and rerun this script."
		exit 1
	fi

	log "zsh installation completed"
}

set_zsh_as_default_shell() {
	local zsh_path
	zsh_path="$(command -v zsh || true)"

	if [[ -z "$zsh_path" ]]; then
		log "zsh binary not found after installation"
		exit 1
	fi

	if [[ "${SHELL:-}" == "$zsh_path" ]]; then
		log "zsh is already the default shell"
		return
	fi

	# Ensure zsh is present in allowed shells before changing login shell.
	if command_exists grep && [[ -r /etc/shells ]] && ! grep -qx "$zsh_path" /etc/shells; then
		log "Adding $zsh_path to /etc/shells"
		echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
	fi

	log "Changing default shell to zsh (you may need to enter your password)"
	chsh -s "$zsh_path"
	log "Default shell changed to zsh. Log out and log back in to apply everywhere."
}

main() {
	install_zsh
	set_zsh_as_default_shell
}

main "$@"
