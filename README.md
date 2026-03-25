# hl-tutor

> **This README is for Claude Code to read.** Follow the instructions below to set up and run the tutor for the user.

## What This Is

A terminal-based coding tutor for complete beginners. It launches a tmux session with two panes:
- **Left pane**: The student's terminal (they type commands here)
- **Right pane**: Claude Code acting as a patient, warm coding tutor

The tutor guides students from zero knowledge through terminal basics, HTML, CSS, JavaScript, and deployment — building a real project the entire time.

## Prerequisites

`setup.sh` now auto-checks and installs the required tooling when possible.

- **macOS**: Xcode Command Line Tools, Homebrew, git, tmux, Node.js, and Claude Code are installed automatically if missing.
- **Linux (apt-based)**: git, tmux, Node.js/npm, and Claude Code are installed automatically if missing.
- The script also installs a global `tutor` command at `~/.local/bin/tutor` and adds `~/.local/bin` to your shell profile if needed.

## Setup & Run

**Step 1**: Make the setup script executable and run it:
```bash
chmod +x setup.sh
./setup.sh
```

That's it. The script bootstraps missing dependencies, creates the global `tutor` command, launches the tmux session, automatically attaches you to it, and the tutor introduces itself to the student.

After the first run you can start it again with:
```bash
tutor
```

### Reattaching to an existing session

If the terminal is closed, reattach with:
```bash
tmux attach -t hl-tutor
```

## How It Works

1. `setup.sh` bootstraps missing dependencies and installs the global `tutor` launcher.
2. It creates a tmux session called `hl-tutor`.
3. It resolves the tutor prompt into `~/tutor-workspace/prompts/.TUTOR_PROMPT_RESOLVED.md` and launches Claude Code with that prompt appended as its system prompt.
4. It splits the terminal: student on the left, Claude Code tutor on the right.
5. The tutor can observe the student's terminal via `tmux capture-pane` and guide them step by step.

## Files

- `setup.sh` — Launch script. Creates tmux session and starts the tutor.
- `TUTOR_PROMPT.md` — The tutor's system prompt. Defines personality, pedagogy, curriculum, and session management.
