alias bat="batcat"
alias e="explorer.exe"
alias p="pnpm"
alias pa="p add"
alias pr="p run"
alias pi="p install"
alias pd="p run dev"
alias pdw="p run dev:watch"
alias pc="p run codegen"
alias pcw="p run codegen-watch"
alias plc="p run lint:check"
alias plf="p run lint:fix"
alias ptc="p run type-check"
alias pds="p run dev:storybook"
alias psd="p run start:dev"
alias pb="p run build"
alias gcm="git commit -m"
alias gs="git status"
alias gcb="git pull && git checkout -b"
alias gmd="git merge --no-edit origin/dev"
alias gfa="git fetch --all"
alias gsc='git stash push --keep-index -m "stash-unstaged"'
alias t='turbo'
alias sz="source ~/.zshrc"


#brew aliases
alias bw="brew"
alias bwi="bw install"
alias bwic="bw install --cask"
alias bws="bw search"
alias bwu="bw uninstall"
alias bwl="bw list"
alias bwc="bw cleanup"
alias bwup="bw upgrade && bw cleanup && sudo softwareupdate -ia && mas upgrade"

# docker alises
alias d="docker"
alias dc="d compose"
alias dps="d ps"
alias dpsa="d ps -a"

alias di="d images"
alias dlog="d logs -f"
alias dexec="d exec -it"
alias dprune="d system prune -f"

alias dcud="d compose up -d"
alias dcd="d compose down"
alias dcl="d compose logs -f"
alias dcb="d compose build"

alias py="python3"