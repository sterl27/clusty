# Run from Windows PowerShell (as Administrator) — one time only.
# Copies .wslconfig to your Windows home, enabling WSL2 mirrored networking
# so the GPU agent (WSL2) is reachable from the k3s server at 192.168.0.28.

$wslconfig = "$PSScriptRoot\..\wslconfig"
$dest      = "$env:USERPROFILE\.wslconfig"

if (Test-Path $dest) {
    $backup = "$dest.bak"
    Copy-Item -Path $dest -Destination $backup -Force
    Write-Host "Existing .wslconfig backed up to $backup"
}

# Strip leading dot — the repo stores it as 'wslconfig', Windows needs '.wslconfig'
Copy-Item -Path $wslconfig -Destination $dest -Force
Write-Host "Copied .wslconfig to $dest"

Write-Host ""
Write-Host "Shutting down WSL to apply mirrored networking..."
wsl --shutdown
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "Done. Start a new WSL2 terminal and verify your IP has changed:"
Write-Host "  wsl -- ip addr show eth0"
Write-Host "It should now show your Windows LAN IP (192.168.0.x)."
