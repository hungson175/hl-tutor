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
#   - CLAUDE_CONFIG_DIR isolation (no global ~/.claude/CLAUDE.md bleed)

set -euo pipefail

SESSION="hl-tutor"
SOURCE_PATH="${BASH_SOURCE[0]}"
while [ -L "$SOURCE_PATH" ]; do
	SOURCE_DIR="$(cd -P "$(dirname "$SOURCE_PATH")" && pwd)"
	SOURCE_PATH="$(readlink "$SOURCE_PATH")"
	case "$SOURCE_PATH" in
	/*) ;;
	*) SOURCE_PATH="$SOURCE_DIR/$SOURCE_PATH" ;;
	esac
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE_PATH")" && pwd)"
TUTOR_WORKSPACE="$HOME/tutor-workspace"
PROMPTS_SRC="$SCRIPT_DIR"
MEMORY_SRC="$SCRIPT_DIR/tutor/memory"
HOOKS_SRC="$SCRIPT_DIR/tutor-hooks"
TUTOR_CMD_PATH="$HOME/.local/bin/tutor"
APT_UPDATED=0

log() {
	echo "[setup] $1"
}

shell_profile_path() {
	case "${SHELL:-}" in
	*/zsh) echo "${ZDOTDIR:-$HOME}/.zprofile" ;;
	*/bash) echo "$HOME/.bash_profile" ;;
	*) echo "$HOME/.profile" ;;
	esac
}

append_line_if_missing() {
	local line="$1"
	local file="$2"
	mkdir -p "$(dirname "$file")"
	touch "$file"
	grep -Fqx "$line" "$file" 2>/dev/null || printf '\n%s\n' "$line" >>"$file"
}

ensure_tutor_command() {
	mkdir -p "$HOME/.local/bin"
	ln -sf "$SCRIPT_DIR/setup.sh" "$TUTOR_CMD_PATH"
	append_line_if_missing 'export PATH="$HOME/.local/bin:$PATH"' "$(shell_profile_path)"
	export PATH="$HOME/.local/bin:$PATH"
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
	brew_bin="$(command -v brew 2>/dev/null || brew_bin_path || true)"
	[ -n "$brew_bin" ] || {
		log "Installing Homebrew..."
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		brew_bin="$(brew_bin_path)"
	}
	brew_shellenv_line="eval \"\$(${brew_bin} shellenv)\""
	append_line_if_missing "$brew_shellenv_line" "$(shell_profile_path)"
	eval "$(${brew_bin} shellenv)"
}

apt_install() {
	command -v apt-get >/dev/null 2>&1 || {
		echo "Error: automatic installs only support Homebrew on macOS or apt-get on Linux." >&2
		exit 1
	}
	if [ "$APT_UPDATED" -eq 0 ]; then
		sudo apt-get update
		APT_UPDATED=1
	fi
	sudo apt-get install -y "$@"
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
	ensure_node_and_npm
	if ! command -v claude >/dev/null 2>&1; then
		log "Installing Claude Code CLI..."
		case "$(uname -s)" in
		Linux) sudo npm install -g @anthropic-ai/claude-code ;;
		*) npm install -g @anthropic-ai/claude-code ;;
		esac
	fi
	ensure_tutor_command
}

ensure_dependencies

# ── Kill existing session if any ──────────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
	echo "Session '$SESSION' already exists. Killing it..."
	tmux kill-session -t "$SESSION"
fi

# ── Provision tutor workspace ─────────────────────────────────────────────────
echo "Provisioning tutor workspace at $TUTOR_WORKSPACE..."
mkdir -p "$TUTOR_WORKSPACE"/{prompts,projects}
mkdir -p "$TUTOR_WORKSPACE/.claude/hooks"

# Copy prompts (always refresh from source)
cp "$PROMPTS_SRC/TUTOR_PROMPT.md" "$TUTOR_WORKSPACE/prompts/TUTOR_PROMPT.md"
cp "$PROMPTS_SRC/CURRICULUM.md" "$TUTOR_WORKSPACE/prompts/CURRICULUM.md"

# Copy hooks (always refresh from source)
cp "$HOOKS_SRC/session_start_tutor.py" "$TUTOR_WORKSPACE/.claude/hooks/session_start_tutor.py"
chmod +x "$TUTOR_WORKSPACE/.claude/hooks/session_start_tutor.py"

# Migrate memory: only initialize on fresh start, preserve existing progress
if [ ! -f "$TUTOR_WORKSPACE/memory/progress.md" ]; then
	echo "Initializing fresh tutor memory..."
	mkdir -p "$TUTOR_WORKSPACE/memory"
	cp "$MEMORY_SRC/progress.md" "$TUTOR_WORKSPACE/memory/progress.md"
	cp "$MEMORY_SRC/lessons-learned.md" "$TUTOR_WORKSPACE/memory/lessons-learned.md"
else
	echo "Existing tutor memory found — preserving student progress."
fi

# Isolated Claude config: prevents global ~/.claude/CLAUDE.md from bleeding in
TUTOR_CLAUDE_CONFIG="$TUTOR_WORKSPACE/.claude-config"
mkdir -p "$TUTOR_CLAUDE_CONFIG/commands"
# Bring in the hooks settings (not the global CLAUDE.md)
cp "$HOOKS_SRC/settings.json" "$TUTOR_CLAUDE_CONFIG/settings.json"
# Copy /ecp command if available (used to load prompts in Claude Code)
cp ~/.claude/commands/ecp.md "$TUTOR_CLAUDE_CONFIG/commands/" 2>/dev/null || true

# ── Create tmux session ───────────────────────────────────────────────────────
echo "Creating tmux session '$SESSION'..."
tmux new-session -d -s "$SESSION" -c "$TUTOR_WORKSPACE" -x 220 -y 50

# Enable mouse support (click panes, scroll, resize)
tmux set-option -t "$SESSION" -g mouse on

# Copy mouse drag selections to the macOS clipboard on release
tmux bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
tmux bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

# Student pane (left): bash welcome
tmux send-keys -t "$SESSION:0.0" \
	"clear && printf '\\n  Welcome! This is YOUR terminal.\\n  Your tutor is on the right -->\\n  Start by saying hi!\\n\\n'" \
	Enter

# Split: right pane for tutor (40% width)
tmux split-window -h -t "$SESSION:0.0" -c "$TUTOR_WORKSPACE" -p 40

# ── Resolve pane IDs into tutor prompt ───────────────────────────────────────
STUDENT_PANE=$(tmux list-panes -t "$SESSION:0" -F "#{pane_id}" | sed -n '1p')
TUTOR_PANE=$(tmux list-panes -t "$SESSION:0" -F "#{pane_id}" | sed -n '2p')

echo "Pane IDs:  STUDENT=$STUDENT_PANE  TUTOR=$TUTOR_PANE"

RESOLVED_PROMPT="$TUTOR_WORKSPACE/prompts/.TUTOR_PROMPT_RESOLVED.md"
cp "$TUTOR_WORKSPACE/prompts/TUTOR_PROMPT.md" "$RESOLVED_PROMPT"

# Substitute placeholders (perl works identically on macOS and Linux)
perl -i -pe "s|\\\${STUDENT_PANE}|$STUDENT_PANE|g" "$RESOLVED_PROMPT"
perl -i -pe "s|\\\${TUTOR_PANE}|$TUTOR_PANE|g" "$RESOLVED_PROMPT"
perl -i -pe "s|\\\${PROJECT_ROOT}|$SCRIPT_DIR|g" "$RESOLVED_PROMPT"

# ── Generate tutor launcher script ───────────────────────────────────────────
# A wrapper script avoids all quoting issues when passing the prompt via tmux
LAUNCHER="$TUTOR_WORKSPACE/.launch-tutor.sh"
cat >"$LAUNCHER" <<LAUNCHER_EOF
#!/usr/bin/env bash
# Auto-generated by setup.sh — do not edit manually
cd "$TUTOR_WORKSPACE"
PROMPT_CONTENT="\$(cat '$RESOLVED_PROMPT')"
exec env CLAUDE_CONFIG_DIR="$TUTOR_CLAUDE_CONFIG" claude --append-system-prompt "\$PROMPT_CONTENT"
LAUNCHER_EOF
chmod +x "$LAUNCHER"

# ── Start tutor Claude Code in right pane ────────────────────────────────────
tmux send-keys -t "$SESSION:0.1" "$LAUNCHER" Enter

# Focus the student pane so they start there
tmux select-pane -t "$SESSION:0.0"

# ── Attach ────────────────────────────────────────────────────────────────────
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
echo ""

tmux attach-session -t "$SESSION"
