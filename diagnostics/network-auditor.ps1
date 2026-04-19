# Core Lab: Universal Network Auditor (Windows Version)
# (c) 2026 Joe | corelab.tech
# Licensed under the MIT License.

# --- 1. DATA GATHERING ---
$ErrorActionPreference = "SilentlyContinue"

# Get IPs
$LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPv4Address -notlike "169.254.*" } | Select-Object -First 1).IPv4Address
$GatewayIP = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Sort-Object RouteMetric | Select-Object -First 1).NextHop
$PublicIP = (Invoke-RestMethod -Uri "https://icanhazip.com").Trim()
if (-not $PublicIP) { $PublicIP = "Offline" }

# NAT Logic
$IsCGNAT = $false
$IsDoubleNAT = $false

if ($LocalIP -match "^100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\.") {
    $IsCGNAT = $true
} elseif ($LocalIP -match "^10\." -or $LocalIP -match "^172\.(1[6-9]|2[0-9]|3[0-1])\." -or $LocalIP -match "^192\.168\.") {
    $IsDoubleNAT = $true
}

# DNS & Latency
$LocalDNS = (Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses | Select-Object -First 1)
$PingCF = Test-Connection -ComputerName 1.1.1.1 -Count 2 -Quiet
$PingGoog = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet

# --- 2. THE VISUALIZER ---
Clear-Host
Write-Host "=======================================================" -ForegroundColor Blue
Write-Host "           CORE LAB: NETWORK HEALTH AUDIT              " -ForegroundColor White -BackgroundColor Black
Write-Host "=======================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "  [ Device ]      [ Gateway ]       [ ISP/Cloud ]     [ Internet ]"
Write-Host "  +--------+      +--------+       +-----------+     +----------+"
Write-Host "  |   " -NoNewline; Write-Host "PC" -ForegroundColor Green -NoNewline; Write-Host "   | ---> |  " -NoNewline; Write-Host "ROUTER" -ForegroundColor Yellow -NoNewline; Write-Host "  | ----> |    " -NoNewline; Write-Host "WAN" -ForegroundColor Red -NoNewline; Write-Host "    | --> |    " -NoNewline; Write-Host "WEB" -ForegroundColor Green -NoNewline; Write-Host "    |"
Write-Host "  +--------+      +--------+       +-----------+     +----------+"
Write-Host ("  {0,-12}    {1,-12}       {2,-12}      {3,-12}" -f $LocalIP, $GatewayIP, "   ...", $PublicIP)
Write-Host ""

# --- 3. THE DIAGNOSIS ---
Write-Host "-------------------------------------------------------"
Write-Host "CONNECTIVITY STATUS:" -Style Bold

if ($PublicIP -eq "Offline") {
    Write-Host " [!] OFFLINE: No internet detected." -ForegroundColor Red
} elseif ($LocalIP -eq $PublicIP) {
    Write-Host " [*] DIRECT EDGE: No NAT detected. You are directly on the WAN." -ForegroundColor Green
} elseif ($IsCGNAT) {
    Write-Host " [!] CG-NAT: Port forwarding will NOT work. Use Tunnels/Tailscale." -ForegroundColor Yellow
} elseif ($IsDoubleNAT) {
    Write-Host " [!] DOUBLE NAT: You are behind a private router." -ForegroundColor Yellow
    Write-Host "    Advice: Ensure your ISP modem is in Bridge Mode if hosting."
} else {
    Write-Host " [*] CLEAN PATH: No CG-NAT or significant routing blocks detected." -ForegroundColor Green
}

Write-Host ""
Write-Host "DNS CONFIGURATION:"
Write-Host "  Local Resolver:   $LocalDNS"
if ($LocalDNS -match "^(1.1.1.1|8.8.8.8|9.9.9.9)") {
    Write-Host "  [*] Status: Verified Public DNS (Privacy/Speed Optimized)." -ForegroundColor Green
} else {
    Write-Host "  [!] Status: ISP/Router DNS detected. Consider 1.1.1.1 for privacy." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "NETWORK PERFORMANCE (Latency):"
if ($PingCF) { Write-Host "  Cloudflare (1.1.1.1): Reachable" -ForegroundColor Green } else { Write-Host "  Cloudflare (1.1.1.1): TIMEOUT" -ForegroundColor Red }
if ($PingGoog) { Write-Host "  Google     (8.8.8.8): Reachable" -ForegroundColor Green } else { Write-Host "  Google     (8.8.8.8): TIMEOUT" -ForegroundColor Red }

Write-Host ""
Write-Host "-------------------------------------------------------" -ForegroundColor Blue
Write-Host "Brought to you by CoreLab.tech - Self-hosting simplified."
