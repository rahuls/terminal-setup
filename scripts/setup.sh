#!/usr/bin/env bash
# run this script by chmod +x scripts/setup.sh && bash -n scripts/setup.sh
set -euo pipefail

log() {
	printf '[setup] %s\n' "$1"
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
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
	install_packages zsh

	log "zsh installation completed"
}

install_oh_my_zsh() {
	local omz_dir
	omz_dir="${ZSH:-$HOME/.oh-my-zsh}"

	if [[ -d "$omz_dir" ]]; then
		log "Oh My Zsh is already installed at $omz_dir"
		return
	fi

	log "Installing Oh My Zsh"

	if ! command_exists git; then
		log "Installing missing dependency: git"
		install_packages git
	fi

	if ! command_exists curl && ! command_exists wget; then
		log "Installing missing dependency: curl"
		install_packages curl
	fi

	if command_exists curl; then
		RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	else
		RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi

	log "Oh My Zsh installation completed"
}

install_zsh_plugins() {
	local script_dir
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

	if [[ ! -f "$script_dir/plugins.sh" ]]; then
		log "plugins.sh not found, skipping plugin install"
		return
	fi

	chmod +x "$script_dir/plugins.sh"
	bash "$script_dir/plugins.sh"
}

setup_zshrc() {
	local script_dir
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

	if [[ ! -f "$script_dir/zshrc.sh" ]]; then
		log "zshrc.sh not found, skipping .zshrc setup"
		return
	fi

	chmod +x "$script_dir/zshrc.sh"
	bash "$script_dir/zshrc.sh"
}

setup_zsh_theme() {
	local script_dir
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

	if [[ ! -f "$script_dir/theme.sh" ]]; then
		log "theme.sh not found, skipping theme setup"
		return
	fi

	chmod +x "$script_dir/theme.sh"
	bash "$script_dir/theme.sh"
}

link_repo_custom_file() {
	local file_name script_dir repo_root repo_file zsh_dir zsh_custom target_file backup_path
	file_name="$1"
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	repo_root="$(cd "$script_dir/.." && pwd)"
	repo_file="$repo_root/zsh/custom/$file_name"
	zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
	zsh_custom="${ZSH_CUSTOM:-$zsh_dir/custom}"
	target_file="$zsh_custom/$file_name"

	if [[ ! -f "$repo_file" ]]; then
		log "Repo custom file not found at $repo_file, skipping"
		return
	fi

	mkdir -p "$zsh_custom"

	if [[ -L "$target_file" ]] && [[ "$(readlink "$target_file")" == "$repo_file" ]]; then
		log "$file_name symlink already configured"
		return
	fi

	if [[ -e "$target_file" && ! -L "$target_file" ]]; then
		backup_path="$target_file.backup.$(date +%Y%m%d%H%M%S)"
		mv "$target_file" "$backup_path"
		log "Backed up existing $file_name to $backup_path"
	fi

	ln -sfn "$repo_file" "$target_file"
	log "Linked $target_file -> $repo_file"
}

link_repo_custom_files() {
	link_repo_custom_file "aliases.zsh"
	link_repo_custom_file "functions.zsh"
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
	install_oh_my_zsh
	setup_zshrc
	setup_zsh_theme
	link_repo_custom_files
	install_zsh_plugins
	set_zsh_as_default_shell
}

main "$@"
