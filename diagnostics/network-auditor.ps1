<#
.SYNOPSIS
    Core Lab: Windows Network Auditor
.DESCRIPTION
    (c) 2026 Joe | corelab.tech
    Licensed under the MIT License.
#>

# Core Lab Network Topology & Health Audit v6.0
# Windows PowerShell "Green Light" Edition

# --- 1. DATA GATHERING ---
Write-Host "⏳ Gathering network data..." -ForegroundColor Gray

# Public IP
try {
    $PublicIP = (Invoke-RestMethod -Uri "https://icanhazip.com" -TimeoutSec 5).Trim()
} catch {
    $PublicIP = "Offline"
}

# Local IP & Gateway
$LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPv4Address -notlike "169.*" } | Select-Object -First 1).IPv4Address
$Gateway = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select-Object -First 1).NextHop

# DNS Analysis
$LocalDNS = (Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses | Select-Object -First 1)
# Bypassing local resolver via Google's diagnostic TXT record
try {
    $UpstreamDNS = (Resolve-DnsName -Name "o-o.myaddr.l.google.com" -Type TXT -Server 8.8.8.8 -ErrorAction SilentlyContinue).Strings[0]
} catch {
    $UpstreamDNS = "Unknown"
}

# Latency Check
$PingCF = (Test-Connection -ComputerName 1.1.1.1 -Count 3 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average).Average
$PingGoog = (Test-Connection -ComputerName 8.8.8.8 -Count 3 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average).Average

# Logic Checks
$isCGNAT = $LocalIP -match "^100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\."
$isPrivate = $LocalIP -match "^10\." -or $LocalIP -match "^172\.(1[6-9]|2[0-9]|3[0-1])\." -or $LocalIP -match "^192\.168\."

# --- 2. THE VISUALIZER ---
Clear-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "       🔍 CORE LAB: NETWORK HEALTH AUDIT 🔍          " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [ Device ]      [ Gateway ]      [ ISP/Cloud ]     [ Internet ]"
Write-Host "  +--------+      +--------+       +-----------+     +----------+"
Write-Host "  |   💻   | ---> |   📟   | ----> |    ☁️      | --> |    🌐    |"
Write-Host "  +--------+      +--------+       +-----------+     +----------+"
Write-Host ("  {0,-12}    {1,-12}     {2,-12}      {3,-12}" -f $LocalIP, $Gateway, "  ...", $PublicIP)
Write-Host ""

# --- 3. THE DIAGNOSIS ---
Write-Host "-------------------------------------------------------"
Write-Host "CONNECTIVITY STATUS:"

if ($PublicIP -eq "Offline") {
    Write-Host "❌ OFFLINE: No internet connection detected." -ForegroundColor Red
} elseif ($LocalIP -eq $PublicIP) {
    Write-Host "✅ DIRECT EDGE: No NAT detected. You are directly on the WAN." -ForegroundColor Green
} elseif ($isCGNAT) {
    Write-Host "⚠️  CG-NAT: Port forwarding will NOT work. Use Tunnels/Tailscale." -ForegroundColor Yellow
} elseif ($isPrivate) {
    Write-Host "⚠️  DOUBLE NAT: You are behind a private router." -ForegroundColor Yellow
    Write-Host "   Advice: Ensure your ISP modem is in Bridge Mode if hosting."
} else {
    Write-Host "🟢 CLEAN PATH: No CG-NAT or significant routing blocks detected." -ForegroundColor Green
    Write-Host "   Status: You are in a great position to start self-hosting!"
}

Write-Host ""
Write-Host "DNS CONFIGURATION:"
Write-Host "  Local Resolver:   $LocalDNS"
Write-Host "  Upstream Public:  $UpstreamDNS"

if ($UpstreamDNS -match "1.1.1.1|8.8.8.8|9.9.9.9|208.67.222.222") {
    Write-Host "  ✅ Status: Verified Public DNS (Privacy/Speed Optimized)." -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Status: ISP/Router DNS detected. Consider 1.1.1.1 for privacy." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "NETWORK PERFORMANCE (Latency):"
Write-Host ("  Cloudflare (1.1.1.1): {0:N0} ms" -f $PingCF)
Write-Host ("  Google     (8.8.8.8): {0:N0} ms" -f $PingGoog)

if ($PingCF -lt 50) {
    Write-Host "  🚀 Status: Excellent. High-responsiveness detected." -ForegroundColor Cyan
}

Write-Host "-------------------------------------------------------"
Write-Host "Brought to you by CoreLab.tech - Self-hosting simplified."
