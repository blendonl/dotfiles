#!/usr/bin/env bash


SEARCH_PATHS=(
    ~/.config/nvim
    ~/dotfiles/.config
    ~/work
    ~/notes
    ~/personal
    /mnt/network-share/personal
    /mnt/network-share/work
)

CONFIG_ROOTS=(
    /mnt/data/personal/dotfiles/.config
    /home/notpc/dotfiles/.config
)

MONOREPO_SUBDIRS=(apps packages)

MAX_DEPTH=6
STATE_FILE="$HOME/.local/state/hypr/session.json"
CACHE_FILE=/tmp/hypr-session-picker-cache.txt
REMOTE_CACHE_FILE=/tmp/hypr-session-picker-remote-cache.txt
LOG=/tmp/hypr-session-picker.log
SESSIONS_LUA="$HOME/.config/hypr/sessions.lua"
DEV_SERVER="devserver"
REMOTE_PICKER="box-picker"

# =========================================================================
# Local session discovery (unchanged)
# =========================================================================

find_sessions() {
    lua -e 'local s=dofile("'"$SESSIONS_LUA"'") for _,v in ipairs(s) do print(v.dir) end' 2>/dev/null

    if [[ -s "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
        return
    fi

    local config_roots_arg
    config_roots_arg=$(IFS=,; echo "${CONFIG_ROOTS[*]}")

    local tmp_cache="${CACHE_FILE}.tmp"

    # timeout prevents hangs on unresponsive CIFS mounts (e.g. /mnt/network-share)
    timeout 10 perl "$HOME/.config/hypr/scripts/find-sessions.pl" \
        "$MAX_DEPTH" \
        "$config_roots_arg" \
        "$(IFS=,; echo "${MONOREPO_SUBDIRS[*]}")" \
        "${SEARCH_PATHS[@]}" | tee "$tmp_cache"

    local rc=${PIPESTATUS[0]}
    if [[ $rc -eq 0 ]] && [[ -s "$tmp_cache" ]]; then
        mv "$tmp_cache" "$CACHE_FILE"
    else
        rm -f "$tmp_cache"
        if [[ $rc -eq 124 ]]; then
            echo "Session scan timed out after 10s — network mounts may be unresponsive" >&2
        fi
        # Partial results still reached stdout via tee; just don't cache them
    fi
}

# =========================================================================
# Remote session discovery — delegates to devserver box-picker --list
# Output format:  display_name\tworktree_path\ttmux_session_name
# =========================================================================

find_remote_sessions() {
    if [[ -s "$REMOTE_CACHE_FILE" ]]; then
        cat "$REMOTE_CACHE_FILE"
        return
    fi

    local tmp_cache="${REMOTE_CACHE_FILE}.tmp"
    ssh "$DEV_SERVER" "$REMOTE_PICKER --list" 2>/dev/null | tee "$tmp_cache"

    local rc=${PIPESTATUS[0]}
    if [[ $rc -eq 0 ]] && [[ -s "$tmp_cache" ]]; then
        mv "$tmp_cache" "$REMOTE_CACHE_FILE"
    else
        rm -f "$tmp_cache"
        # SSH failed or no projects found — don't cache, will retry next time
    fi
}

# =========================================================================
# Name resolution
# =========================================================================

resolve_session_name() {
    local dir=$1

    # Remote projects: derive display name from path (strip /mnt/data/ prefix)
    if [[ "$dir" == /mnt/data/* ]]; then
        local rel="${dir#/mnt/data/}"           # e.g. "personal/project/sub"
        echo "${rel}" | tr . _
        return
    fi

    # Check static sessions first (names are predefined in sessions.lua)
    local name
    name=$(lua -e 'local s=dofile("'"$SESSIONS_LUA"'") for _,v in ipairs(s) do if v.dir=="'"$dir"'" then print(v.name) return end end' 2>/dev/null)
    [[ -n "$name" ]] && { echo "$name"; return; }

    if [[ -d "$dir/.git" ]]; then
        echo "${dir##*/}" | tr . _
        return
    fi

    local parent=$dir
    while [[ "$parent" != "/" ]]; do
        parent=${parent%/*}
        parent=${parent:-/}  # handle "/home" → "" after stripping trailing component
        if [[ -d "$parent/.git" ]]; then
            echo "${parent##*/}/${dir##*/}" | tr . _
            return
        fi
    done

    echo "${dir##*/}" | tr . _
}

# =========================================================================
# Workspace setup (unchanged — default_workspaces.lua handles remote detection)
# =========================================================================

setup_default_workspaces() {
  local session_name=$1
  local session_dir=$2
  local file="$HOME/.config/hypr/session/default_workspaces.lua"

  [[ -f "$file" ]] || { echo "setup_default_workspaces: $file not found" >&2; return 1; }
  [[ -n "$session_name" ]] && [[ -n "$session_dir" ]] || {
    echo "usage: setup_default_workspaces <name> <dir>" >&2; return 1
  }

  lua - "$file" "$session_name" "$session_dir" <<'LUA_EOF'
    local ws = dofile(arg[1])
    local name = arg[2]
    local dir  = arg[3]

    for _, w in ipairs(ws) do
      local on_created = w.on_created_empty(dir, name)
      local ws_name    = "'name:" .. name .. "/" .. w.suffix .. "'"

      -- Build value as:  name:..., on_created_empty:...
      local value = "workspace=".. ws_name .. ", on_created_empty='" .. on_created .. "'"
      if w.default then
        value = value .. ", default=true"
      end

      -- Single-quote the value for the shell, escaping any embedded single quotes
      local escaped = value:gsub("'", "'\\''")

      local ev = 'hl.workspace_rule({' .. escaped .. '})'

      os.execute("hyprctl eval '" .. ev .. "'")
    end
LUA_EOF
}


# =========================================================================
# --list mode: print session paths (local + remote) and exit
# Used by session_picker.lua for discovery
# =========================================================================

if [[ "$1" == "--list" ]]; then
    find_sessions
    # Remote paths (column 2 of tab-separated output)
    find_remote_sessions | cut -f2 2>/dev/null
    exit 0
fi


# =========================================================================
# Interactive mode
# =========================================================================

# --- Gather sessions ------------------------------------------------------
local_sessions=$(find_sessions)

# Temp file for remote metadata:  path\tname\ttmux_session per line
REMOTE_META=$(mktemp)
trap 'rm -f "$REMOTE_META"' EXIT

while IFS=$'\t' read -r display path tmux_name; do
    [[ -z "$path" ]] && continue
    printf '%s\t%s\t%s\n' "$path" "$display" "$tmux_name" >> "$REMOTE_META"
done < <(find_remote_sessions)

# --- Build rofi input ----------------------------------------------------
# Local sessions: raw paths (rofi shows the path)
# Remote sessions: "[remote] <display-name>" for visual distinction
rofi_input=$(
    {
        echo "$local_sessions"
        # Extract just the display name (column 2) and prefix with [remote]
        awk -F'\t' '{print "[remote] " $2}' "$REMOTE_META" 2>/dev/null
    } | grep -v '^$'
)

# --- Selection -----------------------------------------------------------
selected=${1:-$(echo "$rofi_input" | rofi -dmenu -p "Session: " -theme dmenu-custom)}
[[ -z "$selected" ]] && exit 0

# --- Parse selection: local path or remote? ------------------------------
is_remote=false
remote_tmux_session=""

if [[ "$selected" == "[remote] "* ]]; then
    is_remote=true
    remote_display="${selected#"[remote] "}"

    # Look up metadata by display name (column 2)
    meta_line=$(awk -F'\t' -v d="$remote_display" '$2 == d {print; exit}' "$REMOTE_META")
    selected=$(echo "$meta_line" | cut -f1)          # actual devserver path
    remote_tmux_session=$(echo "$meta_line" | cut -f3)  # e.g. "personal-foo~main"

    # box-picker uses project-specific sockets: ~/.tmux-socket-<project_name>
    # Session names are "<project_name>~<branch>" — extract project_name.
    remote_project_name="${remote_tmux_session%%~*}"
    remote_tmux_sock="~/.tmux-socket-${remote_project_name}"

        # Only provision if the tmux session does not already exist on the devserver.
        # Check the project-specific socket first, then fall back to the default
        # socket (for legacy sessions created before project-specific sockets).
        if ! ssh -o ConnectTimeout=10 "$DEV_SERVER" \
            "tmux -S ${remote_tmux_sock} has-session -t '$remote_tmux_session' 2>/dev/null || \
             tmux -S ~/.tmux-socket has-session -t '$remote_tmux_session' 2>/dev/null" 2>/dev/null; then

        # Show progress in a floating terminal while the session is being
        # prepared.  Container provisioning (apt-get install …) can take
        # minutes on first run — the user sees distrobox output live.
        _ensure_rc_file=$(mktemp)
        _ensure_script=$(mktemp)

        cat > "$_ensure_script" <<SCRIPT_EOF
    #!/usr/bin/env bash
    echo 'Preparing session: $remote_display'
    echo '========================================'
    ssh -t -o LogLevel=ERROR '$DEV_SERVER' "$REMOTE_PICKER --ensure '$remote_display'"
    _rc=\$?
    echo '========================================'
    if [[ \$_rc -eq 0 ]]; then
    echo 'Session ready: $remote_tmux_session'
    else
    echo "FAILED (exit code: \$_rc)"
    fi
    echo \$_rc > '$_ensure_rc_file'
    echo ''
    echo 'Closing in 3 seconds...'
    sleep 3
SCRIPT_EOF

        chmod +x "$_ensure_script"
        alacritty --class session-progress --title "Session: $remote_display" \
            --command "$_ensure_script" &
        _alacritty_pid=$!

        # Wait for the rc file to be written (SSH command finished).
        # Time out after 5 min in case the user closes the floating terminal early.
        _ensure_rc=
        _poll_waited=0
        while [[ ! -s "$_ensure_rc_file" ]]; do
            if [[ $_poll_waited -ge 300 ]]; then
                echo "$(date): ERROR: --ensure timed out after 5min for '$remote_display'" >>"$LOG"
                notify-send -u critical "Session Picker" \
                    "Timed out waiting for session: $remote_display" 2>/dev/null || true
                rm -f "$_ensure_rc_file" "$_ensure_script"
                exit 1
            fi
            # If the terminal was closed, give up sooner
            if ! kill -0 "$_alacritty_pid" 2>/dev/null; then
                echo "$(date): ERROR: progress terminal closed before --ensure finished" >>"$LOG"
                rm -f "$_ensure_rc_file" "$_ensure_script"
                exit 1
            fi
            sleep 0.5
            _poll_waited=$((_poll_waited + 1))
        done
        _ensure_rc=$(cat "$_ensure_rc_file")
        rm -f "$_ensure_rc_file" "$_ensure_script"

        if [[ $_ensure_rc -ne 0 ]]; then
            echo "$(date): ERROR: --ensure failed for '$remote_display' (rc=$_ensure_rc)" >>"$LOG"
            notify-send -u critical "Session Picker" \
                "Failed to create session: $remote_display" 2>/dev/null || true
            exit 1
        fi

        # Wait until the tmux session is actually reachable on the devserver
        _waited=0
        while ! ssh -o ConnectTimeout=10 "$DEV_SERVER" "tmux -S ${remote_tmux_sock} has-session -t '$remote_tmux_session'" 2>/dev/null; do
            if [[ $_waited -ge 30 ]]; then
                echo "$(date): ERROR: tmux session '$remote_tmux_session' not ready after 30s" >>"$LOG"
                notify-send -u critical "Session Picker" \
                    "Session '$remote_display' is not ready after 30s" 2>/dev/null || true
                exit 1
            fi
            sleep 1
            _waited=$((_waited + 1))
        done

        echo "$(date): remote session '$remote_tmux_session' ready (waited ${_waited}s)" >>"$LOG"
        fi
fi

name=$(resolve_session_name "$selected")

# --- Resolve browser URL ---------------------------------------------------
# For remote sessions the browser container runs on the server with its own
# LAN IP (macvlan).  Query the server's ip-allocations to get the correct
# URL.  Local sessions with a compose setup are handled by the Lua callback.
browser_url=""
if $is_remote; then
    # box-picker uses:  box_name="${project_name}-${branch}"
    #                       session_name="${project_name}~${branch}"
    # So: box_name = session_name with "~" → "-"
    remote_box_name="${remote_tmux_session//\~/-}"
    browser_url=$(ssh "$DEV_SERVER" "
        if [[ -f /tmp/compose/ip-allocations.txt ]]; then
            ip=\$(grep \"^${remote_box_name} \" /tmp/compose/ip-allocations.txt | awk '{print \$2}')
            if [[ -n \"\$ip\" ]]; then
                echo \"https://\${ip}:6901\"
                exit 0
            fi
        fi
        # Host-mode fallback (no macvlan configured on the server).
        echo 'https://devserver:6901'
    " 2>/dev/null || echo 'https://devserver:6901')
    echo "$(date): browser URL for '$remote_box_name' → $browser_url" >>"$LOG"
fi

# --- Persist state -------------------------------------------------------
mkdir -p "$(dirname "$STATE_FILE")"
[[ -f "$STATE_FILE" ]] || echo '{"sessions":{}}' > "$STATE_FILE"

focus_ws_type=$(jq -r --arg name "$name" --arg dir "$selected" '
  (.sessions[$name].last_workspace // "browser") as $old_ws
  | .sessions[$name].last_workspace // "browser"
' "$STATE_FILE" 2>/dev/null || echo "browser")

if [[ "$focus_ws_type" == "browser" ]]; then
    ws=$(lua -e 'local s=dofile("'"$SESSIONS_LUA"'") for _,v in ipairs(s) do if v.dir=="'"$selected"'" then print(v.default_workspace or "browser") return end end' 2>/dev/null)
    [[ -n "$ws" ]] && focus_ws_type="$ws"
fi

# Persist to state.json — include remote_tmux_session for remote projects
if $is_remote; then
    jq --arg name "$name" --arg dir "$selected" --arg remote_tmux "$remote_tmux_session" --arg remote_sock "$remote_tmux_sock" --arg browser_url "$browser_url" '
      .sessions |= with_entries(.value.active = "false")
      | .sessions[$name] = {
          dir: $dir,
          last_workspace: (.sessions[$name].last_workspace // null),
          active: "true",
          last_active_ts: (now | strftime("%Y-%m-%dT%H:%M:%S")),
          remote_tmux_session: $remote_tmux,
          remote_tmux_sock: $remote_sock,
          browser_url: $browser_url,
        }
      | .last_active = $name
    ' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
else
    jq --arg name "$name" --arg dir "$selected" '
      .sessions |= with_entries(.value.active = "false")
      | .sessions[$name] = {
          dir: $dir,
          last_workspace: (.sessions[$name].last_workspace // null),
          active: "true",
          last_active_ts: (now | strftime("%Y-%m-%dT%H:%M:%S"))
        }
      | .last_active = $name
    ' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
fi

# --- Register workspace rules --------------------------------------------
setup_default_workspaces "$name" "$selected"

# --- Focus workspace -----------------------------------------------------
echo "$(date): focusing workspace name:$name/$focus_ws_type" >>"$LOG"
hyprctl dispatch "hl.dsp.focus({workspace=\"name:$name/$focus_ws_type\"})" >>"$LOG" 2>&1 || {
    echo "$(date): hyprctl FAILED with exit code $?" >>"$LOG"
}
