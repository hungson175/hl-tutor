#!/usr/bin/env python3
"""
SessionStart hook for the hl-tutor Claude Code instance.

Re-injects the resolved tutor prompt after auto-compact or session restart.
Reads $CLAUDE_PROJECT_DIR/prompts/.TUTOR_PROMPT_RESOLVED.md and returns it
as additionalContext so the tutor never forgets its role.

Safety: only activates inside the hl-tutor tmux session.
"""
import json
import os
import subprocess
import sys


def get_tmux_session():
    try:
        result = subprocess.run(
            ["tmux", "display-message", "-p", "#S"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.SubprocessError, FileNotFoundError):
        pass
    return None


def main():
    try:
        json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    # Safety: only activate in the hl-tutor session
    session = get_tmux_session()
    if session != "hl-tutor":
        sys.exit(0)

    # Read the resolved tutor prompt
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    prompt_path = os.path.join(project_dir, "prompts", ".TUTOR_PROMPT_RESOLVED.md")

    try:
        with open(prompt_path, "r", encoding="utf-8") as f:
            prompt_content = f.read()
    except (FileNotFoundError, IOError):
        sys.exit(0)

    if prompt_content.strip():
        output = {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": f"=== YOUR ROLE: TUTOR ===\n\n{prompt_content}"
            }
        }
        print(json.dumps(output))

    sys.exit(0)


if __name__ == "__main__":
    main()
