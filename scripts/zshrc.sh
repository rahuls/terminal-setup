#!/usr/bin/env bash

set -euo pipefail

START_MARKER="# >>> terminal-setup managed block >>>"
END_MARKER="# <<< terminal-setup managed block <<<"

PLUGINS_LINE="plugins=(zsh-bat you-should-use fzf git git-auto-fetch z zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)"

log() {
  printf '[zshrc] %s\n' "$1"
}

rewrite_zshrc() {
  local zshrc tmp
  zshrc="$HOME/.zshrc"
  tmp="$(mktemp)"

  touch "$zshrc"

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

  cat > "$zshrc" <<EOF
$START_MARKER
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
$PLUGINS_LINE
source \$ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# Machine-specific overrides can go here.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
$END_MARKER
EOF

  if [[ -s "$tmp" ]]; then
    printf '\n' >> "$zshrc"
    cat "$tmp" >> "$zshrc"
  fi

  rm -f "$tmp"
  log "Updated $zshrc with managed Oh My Zsh/theme/plugin config"
}

main() {
  rewrite_zshrc
}

main "$@"
