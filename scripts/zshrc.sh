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
    BEGIN { in_block=0; hb_block=0; znap_block=0 }
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    in_block { next }

    hb_block {
      if ($0 ~ /^[[:space:]]*fi[[:space:]]*$/) { hb_block=0 }
      next
    }

    znap_block {
      if ($0 !~ /\\[[:space:]]*$/) { znap_block=0 }
      next
    }

    /^[[:space:]]*export[[:space:]]+ZSH=/ { next }
    /^[[:space:]]*ZSH_THEME=/ { next }
    /^[[:space:]]*plugins=\(/ { next }
    /^[[:space:]]*source[[:space:]]+\$ZSH\/oh-my-zsh\.sh/ { next }
    /^[[:space:]]*\[\[[[:space:]]*![[:space:]]*-f[[:space:]]+~\/\.p10k\.zsh[[:space:]]*\]\][[:space:]]*\|\|[[:space:]]*source[[:space:]]+~\/\.p10k\.zsh/ { next }
    /^[[:space:]]*HB_CNF_HANDLER=/ { next }
    /^[[:space:]]*if[[:space:]]+\[[[:space:]]+-f[[:space:]]+"\$HB_CNF_HANDLER"[[:space:]]*\];[[:space:]]*then/ { hb_block=1; next }
    /^[[:space:]]*source[[:space:]]+"\$HB_CNF_HANDLER";?[[:space:]]*$/ { next }
    /^[[:space:]]*\[\[[[:space:]]+-r[[:space:]].*znap\.zsh.*\]\][[:space:]]*\|\|[[:space:]]*$/ { znap_block=1; next }
    /^[[:space:]]*git[[:space:]]+clone[[:space:]]+--depth[[:space:]]+1[[:space:]]+--[[:space:]]*\\?[[:space:]]*$/ { znap_block=1; next }
    /\.oh-my-zsh\/custom\/plugins\/znap\/znap\.zsh/ { next }
    /\.oh-my-zsh\/custom\/plugins\/znap/ { next }
    /zsh-snap\.git/ { next }
    /\.oh-my-zsh\/custom\/plugins\/zsh-autocomplete\/zsh-autocomplete\.plugin\.zsh/ { next }
    /\.oh-my-zsh\/custom\/plugins\/zsh-z\/zsh-z\.plugin\.zsh/ { next }
    /^[[:space:]]*export[[:space:]]+PATH=\/opt\/homebrew\/bin:\$PATH[[:space:]]*$/ { next }

    { print }
  ' "$zshrc" > "$tmp"

  cat > "$zshrc" <<EOF
$START_MARKER
# Powerlevel10k instant prompt. Keep near the top of ~/.zshrc.
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

# Ensure Homebrew is on PATH and initialize command-not-found (macOS).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if command -v brew >/dev/null 2>&1; then
  eval "$(brew command-not-found-init 2>/dev/null)"
fi

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
