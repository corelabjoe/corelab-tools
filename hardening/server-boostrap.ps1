<#
.SYNOPSIS
    Core Lab: Windows Network Auditor
.DESCRIPTION
    (c) 2026 Joe | corelab.tech
    Licensed under the MIT License.
#>

# Core Lab Windows Server/Workstation Bootstrap & Hardening v1.0
# Targeted for Windows 10/11 or Windows Server 2022+

# --- 0. ADMIN CHECK ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script MUST be run as Administrator." -ForegroundColor Red
    exit
}

Clear-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " 🛡️ Core Lab: Windows Lockdown & Level-Up Kit 🛡️" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# --- 1. USER INPUTS ---
$NewUser = Read-Host "Enter new daily username (e.g., corelabjoe)"
$UserPass = Read-Host -AsSecureString "Enter password for $NewUser"
$SSHPort = Read-Host "Custom SSH Port (Default: 2222)"
if (-not $SSHPort) { $SSHPort = "2222" }

Write-Host ""
Write-Host "--- Optional Features ---"
$InstallUtils = Read-Host "Install btop & modern CLI tools? (y/n)"
$InstallDocker = Read-Host "Install Docker Desktop? (y/n)"
$ApplyTweaks = Read-Host "Apply Core Lab Performance Tweaks (Memory Compression)? (y/n)"
Write-Host ""

# --- 2. SYSTEM UPDATES ---
Write-Host "📦 Checking for Winget updates..." -ForegroundColor Gray
winget upgrade --all

# --- 3. USER CREATION & PRIVILEGES ---
Write-Host "👤 Creating user $NewUser..." -ForegroundColor Gray
$UserParams = @{
    Name = $NewUser
    Password = $UserPass
    FullName = "Core Lab Daily User"
    Description = "Standard user account with sudo-like access"
}
New-LocalUser @UserParams -ErrorAction SilentlyContinue
Add-LocalGroupMember -Group "Administrators" -Member $NewUser
Write-Host "✅ User $NewUser created and added to Administrators."

# --- 4. OPENSSH INSTALL & HARDENING ---
Write-Host "🔒 Configuring OpenSSH on port $SSHPort..." -ForegroundColor Gray
# Install OpenSSH Server if not present
$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($sshServer.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $sshServer.Name
}

# Start Service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Update Port and Hardening in sshd_config
$configPath = "$env:ProgramData\ssh\sshd_config"
(Get-Content $configPath) -replace '#Port 22', "Port $SSHPort" `
                          -replace '#PermitRootLogin.*', 'PermitRootLogin no' `
                          -replace '#PasswordAuthentication yes', 'PasswordAuthentication yes' | Set-Content $configPath

# --- 5. FIREWALL ---
Write-Host "🧱 Configuring Windows Firewall..." -ForegroundColor Gray
New-NetFirewallRule -Name "OpenSSH-Custom" -DisplayName "OpenSSH Port $SSHPort" -Enabled True -Profile Any -Action Allow -Protocol TCP -LocalPort $SSHPort
Write-Host "✅ Firewall rule added for port $SSHPort."

# --- 6. OPTIONAL: UTILITIES ---
if ($InstallUtils -eq "y") {
    Write-Host "🛠️ Installing btop and modern CLI tools..." -ForegroundColor Gray
    winget install --id aristocratos.btop -e
    winget install --id gokcehan.lf -e  # A fast terminal file manager
    Write-Host "✅ Utilities installed."
}

# --- 7. OPTIONAL: DOCKER ---
if ($InstallDocker -eq "y") {
    Write-Host "🐳 Installing Docker Desktop..." -ForegroundColor Gray
    winget install --id Docker.DockerDesktop -e
    Write-Host "✅ Docker Desktop installed. (Restart required to finish WSL2 setup)."
}

# --- 8. OPTIONAL: PERFORMANCE TWEAKS ---
if ($ApplyTweaks -eq "y") {
    Write-Host "🧠 Enabling Windows Memory Compression (zRAM equivalent)..." -ForegroundColor Gray
    Enable-mmAgent -MemoryCompression
    # Network stack optimization for high-throughput
    netsh int tcp set global autotuninglevel=normal
    Write-Host "✅ Memory and Network tweaks applied."
}

# --- 9. WRAP UP ---
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "🎉 WINDOWS BOOTSTRAP COMPLETE!" -ForegroundColor Green
Write-Host "1. Log out and log in as $NewUser."
Write-Host "2. Verify SSH access: ssh $NewUser@localhost -p $SSHPort"
Write-Host "3. Visit CoreLab.tech for your next steps!"
Write-Host "=======================================================" -ForegroundColor Cyan
