if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(zsh-bat you-should-use fzf git git-auto-fetch z zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)
source $ZSH/oh-my-zsh.sh

GIT_AUTO_FETCH_INTERVAL=300   

alias bat="batcat"
alias e="explorer.exe"
alias p=pnpm
alias pa="pnpm add"
alias pr="pnpm run"
alias pi="pnpm install"
alias pd="pnpm run dev"
alias pdw="pnpm run dev:watch"
alias pc="pnpm run codegen"
alias pcw="pnpm run codegen-watch"
alias plc="pnpm run lint:check"
alias plf="pnpm run lint:fix"
alias ptc="pnpm run type-check"
alias pds="pnpm run dev:storybook"
alias psd="pnpm run start:dev"
alias pb="pnpm run build"
alias gcm="git commit -m"
alias gs="git status"
alias gcb="git pull && git checkout -b"
alias gmd="git merge --no-edit origin/dev"
alias gfa="git fetch --all"
alias gsc='git stash push --keep-index -m "stash-unstaged"'
alias t='turbo'
unalias gc 2>/dev/null
gc() {
  if [ -z "$1" ]; then
    echo "Usage: gc <branch>"
    return 1
  fi
  zp
  git checkout "$1" && git pull

  pnpm install
}
_gc_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=($(compgen -W "$(git for-each-ref --format='%(refname:short)' refs/heads/)" -- "$cur"))
}
complete -F _gc_complete gc
cc() {
    if [ -z "$1" ]; then
        echo "Usage: cc <file>"
        return 1
    fi
    if [ ! -f "$1" ]; then
        echo "File not found: $1"
        return 1
    fi
    xclip -selection clipboard < "$1"
    echo "Copied $1 to clipboard ✔"
}
_cc_complete() {
    COMPREPLY=( $(compgen -f -- "${COMP_WORDS[1]}") )
}
# Remove all node_modules in monorepo & return to root
rmnode() {
  # Find repo root using pnpm-workspace.yaml (preferred) or .git
  local ROOT_DIR
  ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  if [[ -f "$ROOT_DIR/pnpm-workspace.yaml" ]]; then
    ROOT_DIR="$ROOT_DIR"
  else
    # fallback: search upward for pnpm-workspace.yaml
    local DIR="$PWD"
    while [[ "$DIR" != "/" ]]; do
      if [[ -f "$DIR/pnpm-workspace.yaml" ]]; then
        ROOT_DIR="$DIR"
        break
      fi
      DIR="$(dirname "$DIR")"
    done
  fi

  echo "📍 Monorepo root detected at: $ROOT_DIR"
  cd "$ROOT_DIR" || return

  echo "🧹 Removing all node_modules folders..."
  find "$ROOT_DIR" -name "node_modules" -type d -prune -print -exec rm -rf {} +

  echo "✅ Done removing all node_modules in the monorepo."
  echo "📦 You're now in the monorepo root. Run 'pnpm i' when ready."
}


complete -F _cc_complete cc
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  

# pnpm
export PNPM_HOME="/home/rahul-hf/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
