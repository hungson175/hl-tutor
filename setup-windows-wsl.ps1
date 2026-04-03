# hl-tutor Windows WSL Installer
param([switch]$SkipWSLCheck)
$ErrorActionPreference="Stop"

Write-Host ""
Write-Host "========================================"
Write-Host " hl-tutor WSL Installer - Windows"
Write-Host "========================================"
Write-Host ""

# Check Ubuntu via direct test
Write-Host "[1/4] Checking Ubuntu..."
try {
    $result = wsl -d Ubuntu -- bash -c "echo OK" 2>&1
    if ($result -match "OK") {
        Write-Host "  [OK] Ubuntu is ready"
    } else {
        Write-Host "  [FAIL] Ubuntu not working properly"
        exit 1
    }
} catch {
    Write-Host "  [FAIL] Ubuntu not found. Make sure Ubuntu is installed from Microsoft Store."
    exit 1
}

# Check WSL version
Write-Host "[2/4] Checking WSL..."
try {
    $wslVersion = wsl.exe --version 2>&1
    if ($wslVersion -match "WSL 2") {
        Write-Host "  [OK] WSL 2 detected"
    } else {
        Write-Host "  [INFO] WSL version check skipped"
    }
} catch {
    Write-Host "  [INFO] WSL version check skipped"
}

# Install dependencies
Write-Host "[3/4] Installing dependencies..."

# git
$check = wsl -d Ubuntu -- bash -c "which git" 2>&1
if ($check -match "/") {
    Write-Host "  [OK] git installed"
} else {
    Write-Host "  Installing git..."
    wsl -d Ubuntu -- bash -c "sudo apt-get update ; sudo apt-get install -y git" 2>&1 | Out-Null
    Write-Host "  [OK] git installed"
}

# tmux
$check = wsl -d Ubuntu -- bash -c "which tmux" 2>&1
if ($check -match "/") {
    Write-Host "  [OK] tmux installed"
} else {
    Write-Host "  Installing tmux..."
    wsl -d Ubuntu -- bash -c "sudo apt-get install -y tmux" 2>&1 | Out-Null
    Write-Host "  [OK] tmux installed"
}

# Node.js
Write-Host "[4/4] Checking Node.js..."
$nodeCheck = wsl -d Ubuntu -- bash -c "node --version 2>&1" 2>&1
if ($nodeCheck -match "v") {
    Write-Host "  [OK] Node.js installed"
} else {
    Write-Host "  [INFO] Node.js not found - will install during setup"
}

Write-Host ""
Write-Host "========================================"
Write-Host " Prerequisites OK!"
Write-Host "========================================"
Write-Host ""

Write-Host "Ready to install hl-tutor!"
Write-Host ""
$cont = Read-Host "Continue? (Y/n)"
if ($cont -eq "n" -or $cont -eq "N") {
    Write-Host "Cancelled."
    exit 0
}

Write-Host ""
Write-Host "[Installing hl-tutor...]"
Write-Host ""

# Run hl-tutor setup
$cmd = "bash <(curl -fsSL https://raw.githubusercontent.com/hungson175/hl-tutor/main/setup.sh)"
Start-Process wsl -ArgumentList "bash","-c",$cmd -Wait -NoNewWindow

Write-Host ""
Write-Host "[Creating tutor.ps1 wrapper...]"

# Create tutor.ps1
$tutorContent = @"
param([string]`$Action="launch")
switch (`$Action.ToLower()) {
    "launch" { wsl -d Ubuntu -- bash -c "source ~/.bashrc 2>/dev/null; tutor" }
    "attach" { wsl -d Ubuntu -- bash -c "tmux attach -t hl-tutor" }
    "kill" { wsl -d Ubuntu -- bash -c "tmux kill-session -t hl-tutor" }
    "status" { wsl -d Ubuntu -- bash -c "tmux has-session -t hl-tutor" }
}
"@

Set-Content -Path "tutor.ps1" -Value $tutorContent -Encoding UTF8
Write-Host "  [OK] Created: tutor.ps1"

Write-Host ""
Write-Host "========================================"
Write-Host " Installation complete!"
Write-Host "========================================"
Write-Host ""
Write-Host "To start the tutor, run:"
Write-Host "  .\tutor.ps1"
Write-Host ""
