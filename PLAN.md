# Phương án: hl-tutor trên Windows (PowerShell + WSL)

## Tổng quan Project

**hl-tutor** là terminal-based coding tutor cho người mới bắt đầu:
- Sử dụng tmux split-pane ( trái: terminal học sinh, phải: Claude Code tutor)
- Hiện chỉ hỗ trợ macOS và Linux (apt-based)
- Mục tiêu: Port sang Windows PowerShell + WSL

---

## 1. Phân tích Code hiện tại

### Shell Scripts (.sh)
| File | Chức năng | Phụ thuộc | Porting |
|------|-----------|-----------|---------|
| setup.sh | Main launcher | bash, tmux, git, node | Cần bash (WSL) |
| tutor-hooks/* | Hooks cho Claude Code | Python, claude | Có thể dùng native |

### Tmux Sessions
- Tạo split-pane horizontal
- Gửi commands đến từng pane
- Điều khiển qua tmux commands

### Claude Code Integration
- Settings.json: permissions.defaultMode = "bypassPermissions"
- System prompt từ TUTOR_PROMPT.md
- Session persistence qua memory files

---

## 2. Kiến trúc đề xuất cho Windows

### A. WSL (Windows Subsystem for Linux) - Khuyến nghị

```
┌─────────────────────────────────────────┐
│  Windows Desktop                         │
│  ├── Windows Terminal (Modern)           │
│  │   └── WSL Ubuntu                     │
│  │       ├── tmux                       │
│  │       ├── Claude Code CLI            │
│  │       └── tutor workspace            │
│  └── PowerShell (Legacy)                │
└─────────────────────────────────────────┘
```

**Ưu điểm:**
- Tương thích 90% với code hiện tại
- Tmux hoạt động tốt trên WSL
- Claude Code CLI hỗ trợ Linux

**Nhược điểm:**
- Cần WSL installed
- Split pane không tích hợp native Windows

### B. PowerShell + Native Windows - Thử nghiệm

```
┌─────────────────────────────────────────┐
│  PowerShell 7+                          │
│  ├── Invoke-Parallel / Posh-SSH         │
│  ├── Windows Terminal tabs              │
│  └── Claude Code CLI (Node.js)         │
└─────────────────────────────────────────┘
```

**Ưu điểm:**
- Không cần WSL
- Tích hợp sâu Windows

**Nhược điểm:**
- Tmux không có native
- Cần thay thế tmux bằng PowerShell Start-Job / Runspace
- Rewrites lớn

---

## 3. Chi tiết Implementation

### 3.1 WSL Solution (Ưu tiên cao)

#### Bước 1: Tạo setup-windows-wsl.ps1

```powershell
# setup-windows-wsl.ps1
# Check WSL installation
wsl --status
wsl --install Ubuntu

# Update WSL
wsl --update

# Run bash setup trong WSL
wsl bash -c "bash <(curl -fsSL https://raw.githubusercontent.com/hungson175/hl-tutor/main/setup.sh)"
```

#### Bước 2: Tạo tutor.ps1 (Windows wrapper)

```powershell
# tutor.ps1 - Windows launcher
param(
    [string]$Action = "launch"
)

$WSL_CMD = "wsl"

switch ($Action) {
    "launch" {
        & $WSL_CMD bash -c "source ~/.bashrc 2>/dev/null; tutor"
    }
    "attach" {
        & $WSL_CMD bash -c "tmux attach -t hl-tutor"
    }
    "kill" {
        & $WSL_CMD bash -c "tmux kill-session -t hl-tutor 2>/dev/null"
    }
    default {
        Write-Host "Usage: tutor.ps1 [launch|attach|kill]"
    }
}
```

#### Bước 3: Sửa setup.sh cho Windows detection

```bash
# Thêm vào setup.sh - phát hiện Windows
detect_wsl() {
    if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
        return 0  # Đang chạy trong WSL
    fi
    if [ -d "/mnt/c/Windows" ] && [ -d "/proc/sys/fs/binfmt_misc" ]; then
        return 0  # Có thể truy cập Windows từ WSL
    fi
    return 1
}
```

### 3.2 PowerShell Native Solution (Ưu tiên thấp - Proof of Concept)

#### Tmux Replacement với PowerShell

```powershell
# tutor-native.ps1 - Sử dụng PowerShell runspaces thay vì tmux

# Tạo 2 runspaces (tương đương 2 panes)
$StudentRunspace = [RunspaceFactory]::CreateRunspace()
$StudentRunspace.Open()

$TutorRunspace = [RunspaceFactory]::CreateRunspace()
$TutorRunspace.Open()

# PowerShell không có split-pane native
# Giải pháp: 2 Windows Terminal tabs hoặc splitted console
```

---

## 4. Danh sách Files cần tạo/sửa

### 4.1 Files mới

| File | Mô tả | Priority |
|------|--------|----------|
| `setup-windows-wsl.ps1` | PowerShell installer cho WSL | 🔴 Cao |
| `tutor.ps1` | Windows wrapper command | 🔴 Cao |
| `tutor-native.ps1` | PowerShell native (không WSL) | 🟡 Trung bình |
| `CLAUDE_SETTINGS_WINDOWS.md` | Hướng dẫn cài đặt Claude Code trên Windows | 🔴 Cao |

### 4.2 Files cần sửa

| File | Thay đổi | Priority |
|------|----------|----------|
| `setup.sh` | Thêm detection cho WSL | 🟡 Trung bình |
| `TUTOR_PROMPT.md` | Thêm note về Windows usage | 🟡 Trung bình |

---

## 5. Dependencies

### 5.1 WSL Solution

```powershell
# Cần cài đặt trên Windows:
# 1. WSL2 (Windows Subsystem for Linux)
wsl --install Ubuntu

# 2. Windows Terminal (optional nhưng khuyến nghị)
winget install Microsoft.WindowsTerminal

# 3. Claude Code CLI (trong WSL)
npm install -g @anthropic-ai/claude-code
```

### 5.2 Native PowerShell Solution

```powershell
# Dependencies cho PowerShell native:
# - PowerShell 7+
# - Node.js (for Claude Code CLI)
# - git
# Không cần tmux (dùng Start-Job hoặc Thread Job)
```

---

## 6. Installation Hướng dẫn

### 6.1 Hướng dẫn nhanh (Quick Start)

```powershell
# Bước 1: Mở PowerShell as Administrator
# Bước 2: Cài WSL (nếu chưa có)
wsl --install Ubuntu

# Bước 3: Restart máy
# Bước 4: Mở Ubuntu terminal, chạy:
bash <(curl -fsSL https://raw.githubusercontent.com/hungson175/hl-tutor/main/setup.sh)

# Bước 5 (Optional): Tạo Windows shortcut
# Tạo tutor.ps1 và chạy mỗi khi cần
```

### 6.2 Troubleshooting

| Issue | Solution |
|-------|----------|
| WSL not installed | Run: `wsl --install` as Admin |
| tmux not found | `sudo apt install tmux` trong WSL |
| Claude Code not found | `npm install -g @anthropic-ai/claude-code` |
| Permission denied | Run PowerShell as Administrator |

### Known Issues (Discovered during real-world testing)

#### Issue 1: WSL check script fails despite Ubuntu being installed (RESOLVED)
- **Symptom:** `setup-windows-wsl.ps1` fails with "[FAIL] Ubuntu not found in WSL"
- **Root Cause:** Script parses text output from `wsl --list` which varies by locale/environment
- **Fix:** v2 uses direct test: `wsl -d Ubuntu -- bash -c "echo OK"`

#### Issue 2: sudo password never set / forgotten
- **Symptom:** Setup script hangs at `[sudo] password for caoha:`
- **Fix:** Set password from PowerShell: `wsl -d Ubuntu -u root bash -c "passwd caoha"`
- **Alt:** Skip xclip: `export SKIP_XCLIP=1` before running setup.sh

#### Issue 3: GitHub 503 errors during curl
- **Symptom:** `curl: (22) The requested URL returned error: 503`
- **Fix:** Wait a few minutes and retry, or clone directly: `git clone https://github.com/hungson175/hl-tutor.git`

#### Issue 4: Claude Code OAuth sign-in / "Missing client_id parameter"
- **Symptom:** Terminal shows OAuth URL but pasting it causes "Missing client_id" error
- **Root Cause:** Two URLs displayed — second one is truncated
- **Fix:** Copy ONLY the first URL (complete one starting with `https://claude.com/cai/oauth/authorize?code=true&...`)

#### Issue 5: User must manually type `claude` in left pane
- **Symptom:** Left pane shows prompt but nothing happens when typing
- **Fix:** Type `claude` and press Enter to start tutor interaction

#### Issue 6: Tutor can't detect WSL/Linux environment
- **Symptom:** Claude Code gives macOS instructions on WSL Ubuntu
- **Fix:** Explicitly tell tutor: "I'm using Ubuntu on Windows WSL"

#### Issue 7: Copy-paste from tutor pane is awkward
- **Symptom:** Commands copied from right pane wrap incorrectly or get cut off
- **Workaround:** Type commands manually or use tmux mouse mode

#### Issue 8: tutor.ps1 "tutor: command not found" (RESOLVED)
- **Symptom:** `tutor` command not found when running `.\tutor.ps1`
- **Root Cause:** `bash -c "source ~/.bashrc; tutor"` doesn't work because bash -c is non-interactive and doesn't source .bashrc
- **Fix:** Use `bash -l -c` (login shell) instead of `bash -c`

---

## 7. Testing Plan

### 7.1 WSL Solution Tests

```powershell
# Test 1: WSL available
wsl --status

# Test 2: Ubuntu runs
wsl -d Ubuntu -- bash -c "echo 'Ubuntu works'"

# Test 3: tmux available
wsl -d Ubuntu -- bash -c "which tmux"

# Test 4: Claude Code available
wsl -d Ubuntu -- bash -c "claude --version"

# Test 5: Full tutor launch
wsl -d Ubuntu -- bash -c "tutor"
```

### 7.2 PowerShell Native Tests

```powershell
# Test 1: Node.js available
node --version

# Test 2: Claude Code CLI
claude --version

# Test 3: Git available
git --version

# Test 4: Run tutor
.\tutor-native.ps1
```

---

## 8. Uncertainty Assessment

### 🔴 Cao Uncertainty

| Yếu tố | Lý do | Mitigation |
|---------|-------|------------|
| tmux performance trên WSL2 | WSL2 networking có thể gây latency | Test thực tế |
| PowerShell tmux replacement | Chưa có library mature | Dùng WSL thay vì native |
| Windows Terminal split-pane | Không hỗ trợ true split | Dùng tabs thay vì split |

### 🟡 Trung bình Uncertainty

| Yếu tố | Lý do | Mitigation |
|---------|-------|------------|
| Claude Code settings.json path | Windows path format khác | Sử dụng $HOME env |
| Clipboard integration | WSL clipboard khác | Test pbcopy/xclip equivalents |

---

## 9. Roadmap

### Phase 1: WSL Support (1-2 days)
- [ ] Tạo setup-windows-wsl.ps1
- [ ] Tạo tutor.ps1 wrapper
- [ ] Test trên WSL2 + Ubuntu
- [ ] Viết CLAUDE_SETTINGS_WINDOWS.md

### Phase 2: PowerShell Native (Proof of Concept) (3-5 days)
- [ ] Thiết kế tmux replacement
- [ ] Implement tutor-native.ps1
- [ ] Test Claude Code integration
- [ ] Fix edge cases

### Phase 3: Polish & Documentation (2-3 days)
- [ ] Update README cho Windows
- [ ] Video tutorial
- [ ] Community testing

---

## 10. Recommendations

### Khuyến nghị cho User:

1. **Dùng WSL2** (được hỗ trợ tốt nhất)
   - Cài WSL2 + Ubuntu
   - Chạy setup.sh như bình thường
   - Dùng Windows Terminal để mở WSL

2. **Không dùng PowerShell native** (quá phức tạp để replace tmux)

### Để implement:

Tôi có thể bắt đầu từ **Phase 1** ngay:
- Tạo setup-windows-wsl.ps1
- Tạo tutor.ps1
- Test với WSL của bạn

Bạn có muốn tôi bắt đầu implementation không? 🚀

---

## References

- Source repo: https://github.com/hungson175/hl-tutor
- WSL Docs: https://docs.microsoft.com/en-us/windows/wsl/
- PowerShell 7: https://github.com/PowerShell/PowerShell
