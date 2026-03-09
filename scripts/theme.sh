#!/usr/bin/env bash

set -euo pipefail

log() {
	printf '[theme] %s\n' "$1"
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

install_packages() {
	if [[ "$#" -eq 0 ]]; then
		return
	fi

	if command_exists apt-get; then
		run_privileged apt-get update
		run_privileged apt-get install -y "$@"
	elif command_exists dnf; then
		run_privileged dnf install -y "$@"
	elif command_exists yum; then
		run_privileged yum install -y "$@"
	elif command_exists pacman; then
		run_privileged pacman -Sy --noconfirm "$@"
	elif command_exists zypper; then
		run_privileged zypper --non-interactive install "$@"
	elif command_exists brew; then
		brew install "$@"
	else
		log "No supported package manager found. Install required packages manually: $*"
		exit 1
	fi
}

install_powerlevel10k() {
	local zsh_dir zsh_custom theme_dir
	zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
	zsh_custom="${ZSH_CUSTOM:-$zsh_dir/custom}"
	theme_dir="$zsh_custom/themes/powerlevel10k"

	if [[ ! -d "$zsh_dir" ]]; then
		log "Oh My Zsh not found at $zsh_dir. Run scripts/setup.sh first."
		exit 1
	fi

	if ! command_exists git; then
		log "Installing missing dependency: git"
		install_packages git
	fi

	mkdir -p "$zsh_custom/themes"

	if [[ -d "$theme_dir/.git" ]]; then
		log "Powerlevel10k already installed, updating"
		git -C "$theme_dir" pull --ff-only || log "Could not fast-forward powerlevel10k, keeping current checkout"
		return
	fi

	if [[ -d "$theme_dir" ]]; then
		log "Powerlevel10k directory exists but is not a git repo: $theme_dir"
		return
	fi

	log "Installing Powerlevel10k theme"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
}

link_repo_p10k_config() {
	local script_dir repo_root repo_p10k target_p10k backup_path
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	repo_root="$(cd "$script_dir/.." && pwd)"
	repo_p10k="$repo_root/zsh/.p10k.zsh"
	target_p10k="$HOME/.p10k.zsh"

	if [[ ! -f "$repo_p10k" ]]; then
		if [[ -f "$target_p10k" ]]; then
			log "Using existing $target_p10k (no repo zsh/.p10k.zsh found)"
		else
			log "No powerlevel10k config found. Add your config at zsh/.p10k.zsh to auto-link it."
		fi
		return
	fi

	if [[ -L "$target_p10k" ]] && [[ "$(readlink "$target_p10k")" == "$repo_p10k" ]]; then
		log ".p10k.zsh symlink already configured"
		return
	fi

	if [[ -e "$target_p10k" && ! -L "$target_p10k" ]]; then
		backup_path="$target_p10k.backup.$(date +%Y%m%d%H%M%S)"
		mv "$target_p10k" "$backup_path"
		log "Backed up existing .p10k.zsh to $backup_path"
	fi

	ln -sfn "$repo_p10k" "$target_p10k"
	log "Linked $target_p10k -> $repo_p10k"
}

main() {
	install_powerlevel10k
	link_repo_p10k_config
}

main "$@"
