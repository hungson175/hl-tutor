# hl-tutor

> **This README is for Claude Code to read.** Follow the instructions below to set up and run the tutor for the user.

## What This Is

A terminal-based coding tutor for complete beginners. It launches a tmux session with two panes:
- **Left pane**: The student's terminal (they type commands here)
- **Right pane**: Claude Code acting as a patient, warm coding tutor

The tutor guides students from zero knowledge through terminal basics, HTML, CSS, JavaScript, and deployment — building a real project the entire time.

## Prerequisites

The user needs these installed before you can run setup:

| Tool | Install command (macOS) | Install command (Linux) |
|------|------------------------|------------------------|
| **tmux** | `brew install tmux` | `sudo apt install tmux` |
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | `npm install -g @anthropic-ai/claude-code` |
| **Node.js** (for Claude Code) | `brew install node` | `sudo apt install nodejs npm` |

## Setup & Run

**Step 1**: Check prerequisites. Run these and verify they succeed:
```bash
tmux -V
claude --version
```

If either is missing, install it using the table above.

**Step 2**: Make the setup script executable and run it:
```bash
chmod +x setup.sh
./setup.sh
```

That's it. The tmux session will launch and the tutor will introduce itself to the student.

### Optional: Custom project directory

By default the student's project lives at `~/my-project`. To use a different directory:
```bash
./setup.sh /path/to/custom-dir
```

### Reattaching to an existing session

If the terminal is closed, reattach with:
```bash
tmux attach -t hl-tutor
```

## How It Works

1. `setup.sh` creates a tmux session called `hl-tutor`
2. It copies `TUTOR_PROMPT.md` into the project directory as `CLAUDE.md` so Claude Code auto-loads it as its system prompt
3. It splits the terminal: student on the left, Claude Code tutor on the right
4. The tutor can observe the student's terminal via `tmux capture-pane` and guide them step by step

## Files

- `setup.sh` — Launch script. Creates tmux session and starts the tutor.
- `TUTOR_PROMPT.md` — The tutor's system prompt. Defines personality, pedagogy, curriculum, and session management.
