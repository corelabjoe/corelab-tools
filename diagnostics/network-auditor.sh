#!/bin/bash
# Core Lab: Universal Network Auditor
# (c) 2026 Joe | corelab.tech
# Licensed under the MIT License.
# See: https://github.com/corelabjoe/corelab-tools/blob/main/LICENSE

# --- 1. DATA GATHERING ---
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
GATEWAY_IP=$(ip route | grep default | awk '{print $3}' | head -n 1)
PUBLIC_IP=$(curl -s --max-time 5 https://icanhazip.com || echo "Offline")

# Range Checks
IS_CGNAT=false
IS_DOUBLE_NAT=false

if [[ $LOCAL_IP =~ ^100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\. ]]; then
    IS_CGNAT=true
elif [[ $LOCAL_IP =~ ^10\. || $LOCAL_IP =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. || $LOCAL_IP =~ ^192\.168\. ]]; then
    IS_DOUBLE_NAT=true
fi

# DNS Detection
LOCAL_DNS=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}' | head -n 1)
# Bypassing local stub to see actual egress DNS IP
UPSTREAM_DNS=$(nslookup -timeout=2 -type=txt o-o.myaddr.l.google.com 8.8.8.8 2>/dev/null | grep -oP '\"?\K[0-9.]+' | head -n 1)

# Latency Check
MS_CF=$(ping -c 3 1.1.1.1 2>/dev/null | tail -1 | awk -F '/' '{print $5}' | cut -d. -f1)
MS_GOOG=$(ping -c 3 8.8.8.8 2>/dev/null | tail -1 | awk -F '/' '{print $5}' | cut -d. -f1)

# --- 2. THE VISUALIZER ---
clear
echo "======================================================="
echo "        ^=^t^m CORE LAB: NETWORK HEALTH AUDIT  ^=^t^m           "
echo "======================================================="
echo ""
echo "  [ Device ]      [ Gateway ]      [ ISP/Cloud ]     [ Internet ]"
echo "  +--------+      +--------+       +-----------+     +----------+"
echo "  |    ^=^r    | ---> |    ^=^s^=   | ----> |     ^x^a  ^o      | --> |     ^=^l^p    |"
echo "  +--------+      +--------+       +-----------+     +----------+"
printf "  %-12s    %-12s     %-12s      %-12s\n" "$LOCAL_IP" "$GATEWAY_IP" "  ..." "$PUBLIC_IP"
echo ""

# --- 3. THE DIAGNOSIS ---
echo "-------------------------------------------------------"
echo "CONNECTIVITY STATUS:"

if [ "$PUBLIC_IP" == "Offline" ]; then
    echo " ^}^l OFFLINE: No internet detected."
elif [ "$LOCAL_IP" == "$PUBLIC_IP" ]; then
    echo " ^|^e DIRECT EDGE: No NAT detected. You are directly on the WAN."
elif [ "$IS_CGNAT" = true ]; then
    echo " ^z   ^o  CG-NAT: Port forwarding will NOT work. Use Tunnels/Tailscale."
elif [ "$IS_DOUBLE_NAT" = true ]; then
    echo " ^z   ^o  DOUBLE NAT: You are behind a private router."
    echo "   Advice: Ensure your ISP modem is in Bridge Mode if hosting."
else
    # THE "GREEN LIGHT" STATUS
    echo " ^=^=  CLEAN PATH: No CG-NAT or significant routing blocks detected."
    echo "   Status: You are in a great position to start self-hosting!"
fi

echo ""
echo "DNS CONFIGURATION:"
echo "  Local Resolver:   $LOCAL_DNS"
echo "  Upstream Public:  ${UPSTREAM_DNS:-Unknown}"

if [[ "$UPSTREAM_DNS" =~ ^(1.1.1.1|8.8.8.8|9.9.9.9|208.67.222.222) ]]; then
    echo "   ^|^e Status: Verified Public DNS (Privacy/Speed Optimized)."
else
    echo "   ^z   ^o  Status: ISP/Router DNS detected. Consider 1.1.1.1 for privacy."
fi

echo ""
echo "NETWORK PERFORMANCE (Latency):"
echo "  Cloudflare (1.1.1.1): ${MS_CF:-ERR} ms"
echo "  Google     (8.8.8.8): ${MS_GOOG:-ERR} ms"

if [ -n "$MS_CF" ] && [ "$MS_CF" -lt 50 ]; then
    echo "   ^=^z^` Status: Excellent. High-responsiveness detected."
fi

echo "-------------------------------------------------------"
echo "Brought to you by CoreLab.tech - Self-hosting simplified."
