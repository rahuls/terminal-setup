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

# Best-effort lossless transcode: HEVC gives a strong size reduction without dropping quality.
vcompress() {
  if [[ -z "$1" ]]; then
    echo "Usage: vcompress <input-video> [output-format|output-video]"
    return 1
  fi

  if [[ ! -f "$1" ]]; then
    echo "File not found: $1"
    return 1
  fi

  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg is not installed"
    return 1
  fi

  local input_file="$1"
  local output_target="$2"
  local output_file
  local output_ext="mkv"
  local -a subtitle_args
  local -a container_args

  if [[ -z "$output_target" ]]; then
    local input_dir="${input_file:h}"
    local input_name="${input_file:t:r}"
    output_file="${input_dir}/${input_name}_lossless.${output_ext}"
  elif [[ "$output_target" == */* || "$output_target" == *.* ]]; then
    output_file="$output_target"
    output_ext="${output_file:e:l}"
  else
    output_ext="${output_target:l}"
    local input_dir="${input_file:h}"
    local input_name="${input_file:t:r}"
    output_file="${input_dir}/${input_name}_lossless.${output_ext}"
  fi

  case "$output_ext" in
    mp4|m4v|mov)
      subtitle_args=(-c:s mov_text)
      container_args=(-tag:v hvc1 -movflags +faststart)
      ;;
    *)
      subtitle_args=(-c:s copy)
      container_args=()
      ;;
  esac

  ffmpeg -hide_banner -y -i "$input_file" \
    -map 0 -map_metadata 0 -map_chapters 0 \
    -c:v libx265 -preset veryslow -x265-params lossless=1 \
    -c:a copy "${subtitle_args[@]}" "${container_args[@]}" \
    "$output_file"
}

