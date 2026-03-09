#!/usr/bin/env bash
# run this script by chmod +x setup.sh && bash -n setup.sh
set -euo pipefail

log() {
	printf '[setup] %s\n' "$1"
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

run_privileged() {
	if command_exists sudo; then
		sudo "$@"
	else
		"$@"
	fi
}

is_container() {
	[[ -f /.dockerenv ]] && return 0
	grep -qaE 'docker|containerd|kubepods' /proc/1/cgroup 2>/dev/null
}

install_zsh() {
	if command_exists zsh; then
		log "zsh is already installed"
		return
	fi

	log "Installing zsh"

	if command_exists apt-get; then
		run_privileged apt-get update
		run_privileged apt-get install -y zsh
	elif command_exists dnf; then
		run_privileged dnf install -y zsh
	elif command_exists yum; then
		run_privileged yum install -y zsh
	elif command_exists pacman; then
		run_privileged pacman -Sy --noconfirm zsh
	elif command_exists zypper; then
		run_privileged zypper --non-interactive install zsh
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
		echo "$zsh_path" | run_privileged tee -a /etc/shells >/dev/null
	fi

	if is_container; then
		log "Container environment detected. Skipping chsh (not required for container test runs)."
		return
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
