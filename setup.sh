#!/usr/bin/env bash
# hl-tutor: Launch a coding tutor tmux session
#
# Left pane  = Student terminal (~/tutor-workspace)
# Right pane = AI Tutor (Claude Code with rich prompt + memory)
#
# Features from guided-AI-coding:
#   - Rich TUTOR_PROMPT with curriculum, pacing, verification
#   - Persistent memory (progress.md + lessons-learned.md)
#   - Pane ID resolution into the prompt (${STUDENT_PANE}, etc.)
#   - SessionStart hook so tutor role survives auto-compact/restart
#   - Project-local Claude settings layered on top of the user's global config

set -euo pipefail

SESSION="hl-tutor"
INVOCATION_NAME="$(basename "$0")"

resolve_script_dir() {
	local source_path source_dir
	source_path="${BASH_SOURCE[0]:-$0}"

	case "$source_path" in
	/dev/fd/* | /proc/*/fd/*)
		pwd
		return 0
		;;
	esac

	while [ -L "$source_path" ]; do
		source_dir="$(cd -P "$(dirname "$source_path")" 2>/dev/null && pwd)" || {
			pwd
			return 0
		}
		source_path="$(readlink "$source_path")"
		case "$source_path" in
		/*) ;;
		*) source_path="$source_dir/$source_path" ;;
		esac
		case "$source_path" in
		/dev/fd/* | /proc/*/fd/*)
			pwd
			return 0
			;;
		esac
	done

	cd -P "$(dirname "$source_path")" 2>/dev/null && pwd || pwd
}

SCRIPT_DIR="$(resolve_script_dir)"
TUTOR_WORKSPACE="$HOME/tutor-workspace"
PROMPTS_SRC="$SCRIPT_DIR"
MEMORY_SRC="$SCRIPT_DIR/tutor/memory"
HOOKS_SRC="$SCRIPT_DIR/tutor-hooks"
REPO_URL="https://github.com/hungson175/hl-tutor.git"
INSTALL_ROOT="${HL_TUTOR_INSTALL_ROOT:-$HOME/.local/share/hl-tutor}"
INSTALL_DIR="$INSTALL_ROOT/repo"
TUTOR_CMD_PATH="$HOME/.local/bin/tutor"
CLAUDE_USER_SETTINGS_PATH="$HOME/.claude/settings.json"
LOGIN_SHELL_PROFILES=("$HOME/.profile" "$HOME/.bash_profile" "${ZDOTDIR:-$HOME}/.zprofile")
INTERACTIVE_SHELL_PROFILES=("$HOME/.bashrc" "${ZDOTDIR:-$HOME}/.zshrc")
APT_UPDATED=0

log() {
	echo "[setup] $1"
}

append_line_if_missing() {
	local line="$1"
	local file="$2"
	mkdir -p "$(dirname "$file")"
	touch "$file"
	grep -Fqx "$line" "$file" 2>/dev/null || printf '\n%s\n' "$line" >>"$file"
}

replace_matching_lines_in_file() {
	local pattern="$1"
	local replacement="$2"
	local file="$3"
	local temp_file
	mkdir -p "$(dirname "$file")"
	touch "$file"
	temp_file="$(mktemp)"
	grep -Ev "$pattern" "$file" >"$temp_file" || true
	printf '%s\n' "$replacement" >>"$temp_file"
	mv "$temp_file" "$file"
}

ensure_line_in_profiles() {
	local line="$1"
	shift
	local profile
	for profile in "$@"; do
		append_line_if_missing "$line" "$profile"
	done
}

ensure_path_entry_in_profiles() {
	local path_dir="$1"
	ensure_line_in_profiles "export PATH=\"$path_dir:\$PATH\"" "${LOGIN_SHELL_PROFILES[@]}" "${INTERACTIVE_SHELL_PROFILES[@]}"
}

ensure_alias_in_profiles() {
	local alias_name="$1"
	local alias_value="$2"
	local profile
	for profile in "${INTERACTIVE_SHELL_PROFILES[@]}"; do
		replace_matching_lines_in_file "^alias ${alias_name}=" "alias ${alias_name}=\"${alias_value}\"" "$profile"
	done
}

ensure_tutor_command() {
	mkdir -p "$HOME/.local/bin"
	ln -sf "$SCRIPT_DIR/setup.sh" "$TUTOR_CMD_PATH"
	ensure_path_entry_in_profiles "$HOME/.local/bin"
	ensure_alias_in_profiles tutor '$HOME/.local/bin/tutor'
	ensure_alias_in_profiles claude 'claude --dangerously-skip-permissions'
	export PATH="$HOME/.local/bin:$PATH"
}

npm_global_bin_path() {
	local npm_prefix
	command -v npm >/dev/null 2>&1 || return 1
	npm_prefix="$(npm config get prefix 2>/dev/null || true)"
	[ -n "$npm_prefix" ] && [ "$npm_prefix" != "undefined" ] || return 1
	echo "$npm_prefix/bin"
}

load_claude_command_into_current_shell() {
	local claude_bin_dir
	claude_bin_dir="$(npm_global_bin_path || true)"
	if [ -n "$claude_bin_dir" ]; then
		export PATH="$claude_bin_dir:$PATH"
	fi
	command -v claude >/dev/null 2>&1 || {
		echo "Error: Claude Code CLI was installed but 'claude' is still not on PATH." >&2
		if [ -n "$claude_bin_dir" ]; then
			echo "Run: export PATH=\"$claude_bin_dir:\$PATH\" or restart your shell." >&2
		fi
		exit 1
	}
}

ensure_claude_command_on_path() {
	local claude_bin_dir
	claude_bin_dir="$(npm_global_bin_path || true)"
	if [ -n "$claude_bin_dir" ]; then
		ensure_path_entry_in_profiles "$claude_bin_dir"
	fi
	load_claude_command_into_current_shell
}

ensure_global_claude_bypass_mode() {
	mkdir -p "$(dirname "$CLAUDE_USER_SETTINGS_PATH")"
	[ -f "$CLAUDE_USER_SETTINGS_PATH" ] || printf '{}\n' >"$CLAUDE_USER_SETTINGS_PATH"
	node - "$CLAUDE_USER_SETTINGS_PATH" <<'NODE'
const fs = require('fs')

const settingsPath = process.argv[2]

let settings = {}
const raw = fs.readFileSync(settingsPath, 'utf8').trim()

if (raw.length > 0) {
  try {
    settings = JSON.parse(raw)
  } catch (error) {
    console.error(`Error: ${settingsPath} contains invalid JSON. Fix it before running setup again.`)
    process.exit(1)
  }
}

if (settings === null || Array.isArray(settings) || typeof settings !== 'object') {
  console.error(`Error: ${settingsPath} must contain a JSON object.`)
  process.exit(1)
}

if (settings.permissions === null || Array.isArray(settings.permissions) || typeof settings.permissions !== 'object') {
  settings.permissions = {}
}

settings.permissions.defaultMode = 'bypassPermissions'

fs.writeFileSync(settingsPath, `${JSON.stringify(settings, null, 2)}\n`)
NODE
}

clipboard_copy_command() {
	case "$(uname -s)" in
	Darwin) echo "pbcopy" ;;
	Linux)
		if command -v wl-copy >/dev/null 2>&1; then
			echo "wl-copy"
		elif command -v xclip >/dev/null 2>&1; then
			echo "xclip -selection clipboard"
		fi
		;;
	esac
}

has_repo_companion_files() {
	[ -f "$PROMPTS_SRC/TUTOR_PROMPT.md" ] &&
		[ -f "$PROMPTS_SRC/CURRICULUM.md" ] &&
		[ -f "$HOOKS_SRC/session_start_tutor.py" ] &&
		[ -f "$HOOKS_SRC/settings.json" ] &&
		[ -f "$MEMORY_SRC/progress.md" ] &&
		[ -f "$MEMORY_SRC/lessons-learned.md" ]
}

bootstrap_repo_checkout() {
	has_repo_companion_files && return 0

	[ "${HL_TUTOR_BOOTSTRAPPED:-0}" = "1" ] && {
		echo "Error: setup.sh is missing the repository files it needs to continue." >&2
		exit 1
	}

	log "Fetching hl-tutor repository..."
	ensure_xcode_command_line_tools
	ensure_homebrew
	ensure_package_command git git
	mkdir -p "$INSTALL_ROOT"
	if [ -d "$INSTALL_DIR/.git" ]; then
		log "Updating existing checkout at $INSTALL_DIR..."
		git -C "$INSTALL_DIR" pull --ff-only
	elif [ -e "$INSTALL_DIR" ]; then
		echo "Error: $INSTALL_DIR exists but is not a git checkout." >&2
		exit 1
	else
		log "Cloning hl-tutor into $INSTALL_DIR..."
		git clone "$REPO_URL" "$INSTALL_DIR"
	fi
	exec env HL_TUTOR_BOOTSTRAPPED=1 bash "$INSTALL_DIR/setup.sh" "$@"
}

ensure_xcode_command_line_tools() {
	local trigger_file product_label waited_seconds=0
	[ "$(uname -s)" = "Darwin" ] || return 0
	xcode-select -p >/dev/null 2>&1 && return 0
	log "Installing Xcode Command Line Tools..."
	trigger_file="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
	touch "$trigger_file"
	product_label="$(softwareupdate -l 2>/dev/null | grep -E '^\*.*Command Line Tools' | tail -n 1 | sed 's/^[^C]*//')"
	[ -n "$product_label" ] || {
		rm -f "$trigger_file"
		echo "Error: unable to find Xcode Command Line Tools in softwareupdate." >&2
		exit 1
	}
	sudo softwareupdate -i "$product_label" --verbose
	rm -f "$trigger_file"
	until xcode-select -p >/dev/null 2>&1; do
		sleep 5
		waited_seconds=$((waited_seconds + 5))
		[ "$waited_seconds" -lt 1800 ] || {
			echo "Error: timed out waiting for Xcode Command Line Tools." >&2
			exit 1
		}
	done
}

brew_bin_path() {
	[ -x /opt/homebrew/bin/brew ] && echo /opt/homebrew/bin/brew && return 0
	[ -x /usr/local/bin/brew ] && echo /usr/local/bin/brew && return 0
	return 1
}

ensure_homebrew() {
	local brew_bin brew_shellenv_line
	[ "$(uname -s)" = "Darwin" ] || return 0
	brew_bin="$(brew_bin_path || true)"
	if [ -z "$brew_bin" ]; then
		brew_bin="$(command -v brew 2>/dev/null || true)"
		[ -n "$brew_bin" ] && [ -x "$brew_bin" ] || brew_bin=""
	fi
	[ -n "$brew_bin" ] || {
		log "Installing Homebrew..."
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		brew_bin="$(brew_bin_path)"
	}
	[ -n "$brew_bin" ] || {
		echo "Error: Homebrew install completed but brew was not found." >&2
		exit 1
	}
	brew_shellenv_line="eval \"\$(${brew_bin} shellenv)\""
	ensure_line_in_profiles "$brew_shellenv_line" "${LOGIN_SHELL_PROFILES[@]}"
	eval "$(${brew_bin} shellenv)"
}

apt_install() {
	command -v apt-get >/dev/null 2>&1 || {
		echo "Error: automatic installs only support Homebrew on macOS or apt-get on Linux." >&2
		exit 1
	}
	if [ "$APT_UPDATED" -eq 0 ]; then
		sudo env DEBIAN_FRONTEND=noninteractive apt-get update
		APT_UPDATED=1
	fi
	sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

ensure_package_command() {
	local command_name="$1"
	local package_name="$2"
	command -v "$command_name" >/dev/null 2>&1 && return 0
	log "Installing $package_name..."
	case "$(uname -s)" in
	Darwin) ensure_homebrew && brew install "$package_name" ;;
	Linux) apt_install "$package_name" ;;
	*)
		echo "Error: unsupported OS $(uname -s)." >&2
		exit 1
		;;
	esac
}

ensure_node_and_npm() {
	if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
		return 0
	fi
	log "Installing Node.js..."
	case "$(uname -s)" in
	Darwin) ensure_homebrew && brew install node ;;
	Linux) apt_install nodejs npm ;;
	*)
		echo "Error: unsupported OS $(uname -s)." >&2
		exit 1
		;;
	esac
}

ensure_dependencies() {
	ensure_xcode_command_line_tools
	ensure_homebrew
	ensure_package_command git git
	ensure_package_command tmux tmux
	if [ "$(uname -s)" = "Linux" ] && ! command -v wl-copy >/dev/null 2>&1 && ! command -v xclip >/dev/null 2>&1; then
		log "Installing xclip for clipboard support..."
		apt_install xclip
	fi
	ensure_node_and_npm
	if ! command -v claude >/dev/null 2>&1; then
		log "Installing Claude Code CLI..."
		case "$(uname -s)" in
		Linux) sudo npm install -g @anthropic-ai/claude-code ;;
		*) npm install -g @anthropic-ai/claude-code ;;
		esac
	fi
	ensure_claude_command_on_path
	ensure_global_claude_bypass_mode
	ensure_tutor_command
}

ensure_runtime_requirements() {
	has_repo_companion_files || {
		echo "Error: tutor runtime files are missing." >&2
		echo "Run the install command again: bash <(curl -fsSL https://raw.githubusercontent.com/hungson175/hl-tutor/main/setup.sh)" >&2
		exit 1
	}
	command -v tmux >/dev/null 2>&1 || {
		echo "Error: tmux is missing. Re-run ./setup.sh to reinstall prerequisites." >&2
		exit 1
	}
	load_claude_command_into_current_shell
}

launch_tutor_session() {
	local clipboard_command
	if tmux has-session -t "$SESSION" 2>/dev/null; then
		echo "Session '$SESSION' already exists. Killing it..."
		tmux kill-session -t "$SESSION"
	fi

	echo "Provisioning tutor workspace at $TUTOR_WORKSPACE..."
	mkdir -p "$TUTOR_WORKSPACE"/{prompts,projects}
	mkdir -p "$TUTOR_WORKSPACE/.claude/hooks"

	cp "$PROMPTS_SRC/TUTOR_PROMPT.md" "$TUTOR_WORKSPACE/prompts/TUTOR_PROMPT.md"
	cp "$PROMPTS_SRC/CURRICULUM.md" "$TUTOR_WORKSPACE/prompts/CURRICULUM.md"

	cp "$HOOKS_SRC/session_start_tutor.py" "$TUTOR_WORKSPACE/.claude/hooks/session_start_tutor.py"
	chmod +x "$TUTOR_WORKSPACE/.claude/hooks/session_start_tutor.py"

	if [ ! -f "$TUTOR_WORKSPACE/memory/progress.md" ]; then
		echo "Initializing fresh tutor memory..."
		mkdir -p "$TUTOR_WORKSPACE/memory"
		cp "$MEMORY_SRC/progress.md" "$TUTOR_WORKSPACE/memory/progress.md"
		cp "$MEMORY_SRC/lessons-learned.md" "$TUTOR_WORKSPACE/memory/lessons-learned.md"
	else
		echo "Existing tutor memory found — preserving student progress."
	fi

	cp "$HOOKS_SRC/settings.json" "$TUTOR_WORKSPACE/.claude/settings.json"

	echo "Creating tmux session '$SESSION'..."
	tmux new-session -d -s "$SESSION" -c "$TUTOR_WORKSPACE" -x 220 -y 50

	tmux set-option -t "$SESSION" -g mouse on
	clipboard_command="$(clipboard_copy_command || true)"
	if [ -n "$clipboard_command" ]; then
		tmux bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "$clipboard_command"
		tmux bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "$clipboard_command"
	fi

	tmux send-keys -t "$SESSION:0.0" \
		"clear && printf '\\n  Welcome! This is YOUR terminal.\\n  Your tutor is on the right -->\\n  Start by saying hi!\\n\\n'" \
		Enter

	tmux split-window -h -t "$SESSION:0.0" -c "$TUTOR_WORKSPACE" -l 40%

	STUDENT_PANE=$(tmux list-panes -t "$SESSION:0" -F "#{pane_id}" | sed -n '1p')
	TUTOR_PANE=$(tmux list-panes -t "$SESSION:0" -F "#{pane_id}" | sed -n '2p')

	echo "Pane IDs:  STUDENT=$STUDENT_PANE  TUTOR=$TUTOR_PANE"

	RESOLVED_PROMPT="$TUTOR_WORKSPACE/prompts/.TUTOR_PROMPT_RESOLVED.md"
	cp "$TUTOR_WORKSPACE/prompts/TUTOR_PROMPT.md" "$RESOLVED_PROMPT"

	perl -i -pe "s|\\\${STUDENT_PANE}|$STUDENT_PANE|g" "$RESOLVED_PROMPT"
	perl -i -pe "s|\\\${TUTOR_PANE}|$TUTOR_PANE|g" "$RESOLVED_PROMPT"
	perl -i -pe "s|\\\${PROJECT_ROOT}|$SCRIPT_DIR|g" "$RESOLVED_PROMPT"

	LAUNCHER="$TUTOR_WORKSPACE/.launch-tutor.sh"
	cat >"$LAUNCHER" <<LAUNCHER_EOF
#!/usr/bin/env bash
# Auto-generated by setup.sh — do not edit manually
cd "$TUTOR_WORKSPACE"
PROMPT_CONTENT="\$(cat '$RESOLVED_PROMPT')"
exec claude --append-system-prompt "\$PROMPT_CONTENT"
LAUNCHER_EOF
	chmod +x "$LAUNCHER"

	tmux send-keys -t "$SESSION:0.1" "$LAUNCHER" Enter
	tmux select-pane -t "$SESSION:0.0"

	echo ""
	echo "  hl-tutor is starting..."
	echo ""
	echo "  Left pane:  Your terminal (start here)"
	echo "  Right pane: Your AI tutor"
	echo "  Workspace:  $TUTOR_WORKSPACE"
	echo "  Memory:     $TUTOR_WORKSPACE/memory/"
	echo "  Command:    tutor"
	echo ""
	echo "  To reattach later: tmux attach -t $SESSION"
	echo "  To launch later:   tutor"
	echo "  If 'tutor'/'claude' are not found after detach: exec \$SHELL -l"
	echo ""

	tmux attach-session -t "$SESSION"
}

run_install_mode() {
	bootstrap_repo_checkout "$@"
	ensure_dependencies
	launch_tutor_session
	log "Install complete — reloading shell to activate 'tutor' command..."
	exec "${SHELL:-/bin/bash}" -l
}

run_tutor_mode() {
	ensure_runtime_requirements
	launch_tutor_session
}

case "$INVOCATION_NAME" in
tutor) run_tutor_mode "$@" ;;
*) run_install_mode "$@" ;;
esac
