# Issues to Report to hl-tutor Maintainer

## Target Repository
https://github.com/hungson175/hl-tutor

## Issues Found on Windows WSL

### Issue 1: Tutor pane doesn't detect WSL/Linux environment
**Severity:** Medium

**Description:** When running on Ubuntu via WSL (Windows Subsystem for Linux), the Claude Code tutor in the right pane doesn't automatically detect the environment. It may give instructions assuming macOS (e.g., `brew install`, `open` commands).

**Expected behavior:** Tutor should detect `uname -a` or check `/proc/version` to identify Linux/Wsl.

**Workaround:** User must manually tell the tutor: "I'm using Ubuntu on Windows WSL, not Mac."

---

### Issue 2: User must manually type `claude` in left pane
**Severity:** Low (UX friction)

**Description:** After launching the tutor session, the left pane shows a shell prompt (`caoha@Cao-Ngoc-Ha:~/tutor-workspace$`) but nothing happens when the user types. The user must explicitly type `claude` and press Enter to start interacting with the tutor.

**Expected behavior:** The tutor should greet or prompt the user automatically upon launching.

**Workaround:** Type `claude` and press Enter.

---

### Issue 3: Copy-paste from tutor pane is awkward
**Severity:** Low (UX friction)

**Description:** When copying commands from the right tutor pane:
- Long commands wrap awkwardly in the terminal
- Multi-line code snippets are hard to copy accurately
- The left pane terminal doesn't handle pasted multi-line commands well

**Expected behavior:** Either:
- Better copy mechanism (e.g., click to copy buttons)
- Or auto-execute single-line commands in left pane

**Workaround:** Type commands manually rather than copying.

---

## Environment Details
- OS: Ubuntu on WSL2 (Windows 11)
- Terminal: Windows Terminal
- Shell: bash
- tmux: Yes
- Node.js: Yes
- Claude Code: v2.1.86

## Suggested Priority
1. Issue 1 (environment detection) — affects correctness of instructions
2. Issue 2 (auto-start interaction) — affects first-time user experience
3. Issue 3 (copy-paste) — minor UX friction

---

*Reported by: Cao Ngoc Ha via OpenClaw*
*Date: 2026-03-29*
