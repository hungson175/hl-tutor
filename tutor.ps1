param([string]$Action="launch")
switch ($Action.ToLower()) {
    "launch" { wsl -d Ubuntu -- bash -l -c "source ~/.bashrc 2>/dev/null; tutor" }
    "attach" { wsl -d Ubuntu -- bash -l -c "tmux attach -t hl-tutor" }
    "kill" { wsl -d Ubuntu -- bash -l -c "tmux kill-session -t hl-tutor" }
    "status" { wsl -d Ubuntu -- bash -l -c "tmux has-session -t hl-tutor" }
}
