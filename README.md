# hl-tutor for Windows (WSL Edition)

Terminal-based coding tutor for complete beginners on Windows using WSL.

## Prerequisites

1. **Windows 10/11** with WSL2 enabled
2. **Ubuntu** installed from Microsoft Store
3. **Windows Terminal** (recommended)

## Quick Start

### 1. Open PowerShell as Administrator

### 2. Run the installer

```powershell
cd C:\Users\caong\Hà\BPF2026\Openclaw\projects\hl-tutor-windows
.\setup-windows-wsl.ps1
```

If the installer fails at the WSL check step, you can skip it with:
```powershell
.\setup-windows-wsl.ps1 -SkipWSLCheck
```

The installer will:
- ✅ Check WSL and Ubuntu
- ✅ Install git, tmux in WSL (if missing)
- ✅ Install Node.js in WSL (if missing)
- ✅ Run hl-tutor setup
- ✅ Create `tutor` command

### 3. Start the tutor

```powershell
.\tutor.ps1
```

## Commands

| Command | Description |
|---------|-------------|
| `.\tutor.ps1 launch` | Start a new tutor session |
| `.\tutor.ps1 attach` | Attach to existing session |
| `.\tutor.ps1 kill` | Stop the tutor session |
| `.\tutor.ps1 status` | Check if tutor is running |

> **Note:** Always run from the `hl-tutor-windows` directory:
> ```powershell
> cd C:\Users\caong\Hà\BPF2026\Openclaw\projects\hl-tutor-windows
> .\tutor.ps1
> ```

## Manual Installation

If you prefer to set up manually:

### 1. Install WSL (as Administrator)

```powershell
wsl --install Ubuntu
# Restart computer
```

### 2. Open Ubuntu and run

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/hungson175/hl-tutor/main/setup.sh)
```

### 3. Use tutor command

```bash
tutor          # Start tutor
tmux attach -t hl-tutor  # Reattach
```

## Files

```
hl-tutor-windows/
├── setup-windows-wsl.ps1  # Installer script
├── tutor.ps1             # Windows wrapper command
├── README.md             # This file
└── CLAUDE_SETTINGS_WINDOWS.md  # Claude Code setup guide
```

## Troubleshooting

### "WSL is not installed"

Run as Administrator:
```powershell
wsl --install
```

### "Ubuntu not found" / Script fails at WSL check

If `wsl --list` shows Ubuntu but the installer fails, verify Ubuntu works manually:
```powershell
wsl -d Ubuntu -- bash -c "echo OK"
```
Expected output: `OK`

If Ubuntu is installed but won't start, try restarting WSL:
```powershell
wsl --shutdown
# Then open a new terminal
```

### sudo password issues during installation

The setup script requires sudo to install `xclip`. If you've never set a password for your Ubuntu user:

1. **Set password via PowerShell (recommended):**
   ```powershell
   wsl -d Ubuntu -u root bash -c "passwd caoha"
   ```
   Then enter a new password twice.

2. **Or from inside Ubuntu:**
   ```bash
   # If you know current password:
   passwd
   
   # If you've never set one and "Enter" doesn't work, exit Ubuntu
   # and run from PowerShell:
   wsl -d Ubuntu -u root bash -c "echo 'caoha:yourpassword' | chpasswd"
   ```

3. **Skip xclip if you don't need clipboard support:**
   ```bash
   export SKIP_XCLIP=1
   bash <(curl -fsSL https://raw.githubusercontent.com/hungson175/hl-tutor/main/setup.sh)
   ```
   xclip is only needed for clipboard integration with the tutor.

### GitHub 503 / curl error during setup

GitHub's raw content service may be temporarily unavailable (503 errors).

**Try again in a few minutes:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/hungson175/hl-tutor/main/setup.sh)
```

**Or clone the repository directly:**
```bash
cd ~
rm -rf hl-tutor-temp
git clone https://github.com/hungson175/hl-tutor.git hl-tutor-temp
cd hl-tutor-temp
bash setup.sh
```

**Check GitHub status:** https://www.githubstatus.com

### Claude Code OAuth sign-in error

When Claude Code starts, it shows a URL for OAuth authentication but the URL may appear truncated or cause "Missing client_id parameter" error.

**Solution:**

1. **Copy the FIRST URL only** (starts with `https://claude.com/cai/oauth/authorize?code=true&...`)
   - There are 2 URLs displayed — the first one is the complete URL
   - The second URL is truncated and will cause errors

2. **Open the URL in your browser** (Chrome, Edge, or Firefox — not Internet Explorer)

3. **Sign in with your Anthropic account** at https://claude.com
   - Create an account if you don't have one

4. **Copy the authorization code** shown in the browser

5. **Paste it back in the terminal** when prompted

**If URL is cut off in terminal:** Try widening the terminal window, or run:
```bash
cat ~/.claude/.auth_url.txt 2>/dev/null || echo "URL not saved"
```

### Known Limitations on Windows WSL

#### 1. Must manually type `claude` to interact with tutor
After launching tutor, the left pane shows a prompt like:
```
caoha@Cao-Ngoc-Ha:~/tutor-workspace$
```
You need to **type `claude` and press Enter** to start interacting with the tutor. The tutor won't respond to text typed in the left pane automatically.

#### 2. Tutor can't detect WSL/Linux environment properly
The Claude Code tutor on the right pane may not correctly identify that it's running on **Ubuntu/WSL** vs Mac OS. It may:
- Give instructions assuming macOS commands (e.g., `brew`, `open`)
- Not recognize WSL-specific paths or tools

**Workaround:** Explicitly tell the tutor at the start:
```
I'm using Ubuntu on Windows WSL, not Mac. Please give commands for Ubuntu/Debian Linux.
```

#### 3. Copy-paste from tutor pane is not seamless
When copying commands from the right tutor pane:
- Text may wrap awkwardly or get cut off in the terminal
- Commands spanning multiple lines are hard to copy accurately
- The left pane terminal for typing doesn't auto-clear

**Workaround:**
- Type commands manually rather than copying
- Or use `tmux select-pane -t hl-tutor.left` then `Ctrl+A` to mark and copy
- In Windows Terminal, you can use mouse selection to copy from either pane

### "tutor command not found"

In WSL terminal, run:
```bash
source ~/.bashrc
# or
exec $SHELL -l
```

### tmux not found

In WSL, install tmux:
```bash
sudo apt-get update && sudo apt-get install -y tmux
```

### Installation script stops at WSL check

Some Windows environments have WSL installed but Ubuntu takes time to initialize on first run. Make sure you've opened Ubuntu at least once from the Start Menu and completed initial setup (creating user account).

## How It Works

```
Windows PowerShell
       │
       ▼
   WSL Ubuntu
       │
       ▼
   tmux session (hl-tutor)
       │
       ├── Left pane: Student terminal
       │
       └── Right pane: Claude Code tutor
```

The tutor uses tmux to create a split-pane terminal:
- **Left pane**: Your terminal (where you type commands)
- **Right pane**: Claude Code acting as your coding tutor

## Requirements

- WSL2 (Windows Subsystem for Linux)
- Ubuntu 20.04+ (from Microsoft Store)
- Internet connection (for setup and Claude Code)

## License

Same as [hl-tutor](https://github.com/hungson175/hl-tutor) - MIT License
