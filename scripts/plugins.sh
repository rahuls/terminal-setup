#!/usr/bin/env bash

set -euo pipefail

log() {
	printf '[plugins] %s\n' "$1"
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

install_runtime_dependencies() {
	if ! command_exists git; then
		log "Installing missing dependency: git"
		install_packages git
	fi

	if ! command_exists fzf; then
		log "Installing missing dependency: fzf"
		install_packages fzf
	fi

	# zsh-bat needs bat/batcat binary for previews.
	if ! command_exists bat && ! command_exists batcat; then
		log "Installing missing dependency: bat"
		install_packages bat
	fi
}

install_or_update_plugin() {
	local plugin_name="$1"
	local repo_url="$2"
	local target_dir="$3"

	if [[ -d "$target_dir/.git" ]]; then
		log "Updating $plugin_name"
		git -C "$target_dir" pull --ff-only || log "Could not fast-forward $plugin_name, keeping current checkout"
		return
	fi

	if [[ -d "$target_dir" ]]; then
		log "Directory exists for $plugin_name but is not a git repo, skipping: $target_dir"
		return
	fi

	log "Installing $plugin_name"
	git clone --depth=1 "$repo_url" "$target_dir"
}

install_plugins() {
	local zsh_dir omz_custom plugins_dir
	zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"

	if [[ ! -d "$zsh_dir" ]]; then
		log "Oh My Zsh not found at $zsh_dir. Run setup.sh first."
		exit 1
	fi

	omz_custom="${ZSH_CUSTOM:-$zsh_dir/custom}"
	plugins_dir="$omz_custom/plugins"
	mkdir -p "$plugins_dir"

	install_or_update_plugin "zsh-bat" "https://github.com/fdellwing/zsh-bat.git" "$plugins_dir/zsh-bat"
	install_or_update_plugin "you-should-use" "https://github.com/MichaelAquilina/zsh-you-should-use.git" "$plugins_dir/you-should-use"
	install_or_update_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git" "$plugins_dir/zsh-autosuggestions"
	install_or_update_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$plugins_dir/zsh-syntax-highlighting"
	install_or_update_plugin "fast-syntax-highlighting" "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$plugins_dir/fast-syntax-highlighting"
	install_or_update_plugin "zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete.git" "$plugins_dir/zsh-autocomplete"
}

main() {
	install_runtime_dependencies
	install_plugins
	log "Plugin setup completed"
}

main "$@"
