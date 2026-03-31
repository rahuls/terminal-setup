GIT_AUTO_FETCH_INTERVAL=300

unalias gc 2>/dev/null

gc() {
  if [[ -z "$1" ]]; then
    echo "Usage: gc <branch>"
    return 1
  fi

  zp
  git checkout "$1" && git pull
  pnpm install
}

_gc_complete() {
  local -a branches
  branches=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)}")
  _describe 'branch' branches
}
compdef _gc_complete gc

cc() {
  if [[ -z "$1" ]]; then
    echo "Usage: cc <file>"
    return 1
  fi

  if [[ ! -f "$1" ]]; then
    echo "File not found: $1"
    return 1
  fi

  xclip -selection clipboard < "$1"
  echo "Copied $1 to clipboard"
}

_cc_complete() {
  _files
}
compdef _cc_complete cc

# Remove all node_modules in monorepo and return to root.
rmnode() {
  local root_dir dir
  root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

  if [[ ! -f "$root_dir/pnpm-workspace.yaml" ]]; then
    dir="$PWD"
    while [[ "$dir" != "/" ]]; do
      if [[ -f "$dir/pnpm-workspace.yaml" ]]; then
        root_dir="$dir"
        break
      fi
      dir="$(dirname "$dir")"
    done
  fi

  echo "Monorepo root detected at: $root_dir"
  cd "$root_dir" || return

  echo "Removing all node_modules folders..."
  find "$root_dir" -name "node_modules" -type d -prune -print -exec rm -rf {} +

  echo "Done removing all node_modules in the monorepo."
  echo "You are now in the monorepo root. Run 'pnpm i' when ready."
}

localip() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}' | sort -u
    return
  fi

  if command -v ip >/dev/null 2>&1; then
    ip -4 -o addr show scope global up | awk '{print $4}' | cut -d/ -f1 | sort -u
    return
  fi

  ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}' | sort -u
}

# DNS cache clear function - works on both macOS and Ubuntu
dnsclear() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Clearing DNS cache on macOS..."
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    echo "DNS cache cleared ✓"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Ubuntu/Linux with systemd-resolve
    echo "Clearing DNS cache on Linux..."
    sudo systemctl restart systemd-resolved
    echo "DNS cache cleared ✓"
  else
    echo "OS not supported. Use 'uname -s' to check your system."
  fi
}