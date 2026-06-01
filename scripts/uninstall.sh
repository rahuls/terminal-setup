#!/usr/bin/env bash

set -euo pipefail

START_MARKER="# >>> terminal-setup managed block >>>"
END_MARKER="# <<< terminal-setup managed block <<<"

log() {
	printf '[uninstall] %s\n' "$1"
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

remove_terminal_setup_zshrc_block() {
	local zshrc tmp
	zshrc="$HOME/.zshrc"

	if [[ ! -f "$zshrc" ]]; then
		log "No ~/.zshrc found, skipping"
		return
	fi

	tmp="$(mktemp)"
	awk -v start="$START_MARKER" -v end="$END_MARKER" '
		BEGIN { in_block=0 }
		$0 == start { in_block=1; next }
		$0 == end { in_block=0; next }
		in_block { next }

		/^[[:space:]]*export[[:space:]]+ZSH=/ { next }
		/^[[:space:]]*ZSH_THEME=/ { next }
		/^[[:space:]]*plugins=\(/ { next }
		/^[[:space:]]*source[[:space:]]+\$ZSH\/oh-my-zsh\.sh/ { next }
		/^[[:space:]]*\[\[[[:space:]]*![[:space:]]*-f[[:space:]]+~\/\.p10k\.zsh[[:space:]]*\]\][[:space:]]*\|\|[[:space:]]*source[[:space:]]+~\/\.p10k\.zsh/ { next }

		{ print }
	' "$zshrc" > "$tmp"

	cp "$zshrc" "$zshrc.backup.$(date +%Y%m%d%H%M%S)"
	mv "$tmp" "$zshrc"
	log "Removed terminal-setup managed entries from ~/.zshrc"
}

remove_oh_my_zsh_and_theme() {
	local zsh_dir target_p10k
	zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
	target_p10k="$HOME/.p10k.zsh"

	if [[ -d "$zsh_dir" ]]; then
		rm -rf "$zsh_dir"
		log "Removed $zsh_dir"
	else
		log "Oh My Zsh directory not found at $zsh_dir"
	fi

	if [[ -L "$target_p10k" ]]; then
		rm -f "$target_p10k"
		log "Removed symlink $target_p10k"
	fi
}

switch_default_shell_to_bash() {
	local bash_path
	bash_path="$(command -v bash || true)"

	if [[ -z "$bash_path" ]]; then
		log "bash not found, cannot change default shell"
		return
	fi

	if [[ "${SHELL:-}" == "$bash_path" ]]; then
		log "bash is already the current default shell"
		return
	fi

	if command_exists grep && [[ -r /etc/shells ]] && ! grep -qx "$bash_path" /etc/shells; then
		echo "$bash_path" | run_privileged tee -a /etc/shells >/dev/null
	fi

	if is_container; then
		log "Container environment detected. Skipping chsh."
		return
	fi

	chsh -s "$bash_path"
	log "Default shell changed to bash. Log out and back in to apply everywhere."
}

main() {
	remove_terminal_setup_zshrc_block
	remove_oh_my_zsh_and_theme
	switch_default_shell_to_bash
}

main "$@"
