#!/usr/bin/env bash
# hl-tutor: Launch a tmux coding tutor session
# Usage: ./setup.sh [project-dir]
#
# Left pane  = Student terminal (they type here)
# Right pane = AI Tutor (Claude Code with tutor prompt)

set -euo pipefail

SESSION="hl-tutor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/TUTOR_PROMPT.md"
PROJECT_DIR="${1:-$HOME/my-project}"

# ── Preflight checks ─────────────────────────────────────────────
if ! command -v tmux &>/dev/null; then
    echo "Error: tmux is not installed. Install it first:"
    echo "  brew install tmux    # macOS"
    echo "  sudo apt install tmux  # Linux"
    exit 1
fi

if ! command -v claude &>/dev/null; then
    echo "Error: claude (Claude Code CLI) is not installed."
    echo "  npm install -g @anthropic-ai/claude-code"
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: Tutor prompt not found at $PROMPT_FILE"
    exit 1
fi

# ── Kill existing session if any ──────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "Session '$SESSION' already exists. Killing it..."
    tmux kill-session -t "$SESSION"
fi

# ── Create project directory & inject CLAUDE.md ───────────────────
mkdir -p "$PROJECT_DIR"

# Copy the tutor prompt as CLAUDE.md so Claude Code auto-loads it
cp "$PROMPT_FILE" "$PROJECT_DIR/CLAUDE.md"

# ── Build the tmux session ────────────────────────────────────────
# Create session with the student terminal (left pane)
tmux new-session -d -s "$SESSION" -c "$PROJECT_DIR" -x 200 -y 50

# Enable mouse support (click panes, scroll, resize)
tmux set-option -t "$SESSION" -g mouse on

# Student pane: clean welcome
tmux send-keys -t "$SESSION:0.0" "clear && printf '\\n  Welcome! This is YOUR terminal.\\n  Your tutor is on the right side -->\\n  Type commands here. Experiment freely!\\n\\n'" Enter

# Split: right pane for the tutor (40% width)
tmux split-window -h -t "$SESSION:0.0" -c "$PROJECT_DIR" -p 40

# Launch Claude Code in the right pane
# Uses CLAUDE.md for the system prompt (auto-loaded by Claude Code)
# --append-system-prompt adds the session-specific context
tmux send-keys -t "$SESSION:0.1" "claude --append-system-prompt 'You are now live in the hl-tutor tmux session. The student is in pane 0 (left). You are in pane 1 (right). To see their terminal: tmux capture-pane -t hl-tutor:0.0 -p -S -50. Their project directory is $PROJECT_DIR. Start by introducing yourself and asking their name.'" Enter

# Focus the student pane (left) so student starts there
tmux select-pane -t "$SESSION:0.0"

# ── Attach ────────────────────────────────────────────────────────
echo ""
echo "  hl-tutor is starting..."
echo ""
echo "  Left pane:  Your terminal (type here)"
echo "  Right pane: Your AI tutor"
echo "  Project dir: $PROJECT_DIR"
echo ""
echo "  To reattach later: tmux attach -t hl-tutor"
echo ""

tmux attach-session -t "$SESSION"
