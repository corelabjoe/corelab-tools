#!/bin/bash
# =======================================================
# Core Lab: Server Boostrap & Hardening Script
# (c) 2026 Joe | corelab.tech
# Licensed under the MIT License.
# Targeted for Debian 13 (Trixie)
# Original Guide: https://corelab.tech/vps-security-hardening/
# =======================================================

set -e

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Please run as root (or with sudo)."
  exit 1
fi

echo "======================================================="
echo " 🛡️ Core Lab: Debian 13 Lockdown & Level-Up Kit 🛡️"
echo "======================================================="

# --- 1. USER INPUTS ---
read -p "Enter new daily username: " NEW_USER
read -s -p "Enter password for $NEW_USER: " USER_PASS
echo ""
read -p "Custom SSH Port (Default: 2025): " INPUT_PORT
SSH_PORT=${INPUT_PORT:-2025}

echo ""
echo "--- Optional Features ---"
read -p "Install btop & pydf? (y/n): " INSTALL_UTILS
read -p "Install Docker & Docker Compose? (y/n): " INSTALL_DOCKER
read -p "Apply Power-User RAM Tweaks (sysctl)? (y/n): " APPLY_SYSCTL
read -p "Install zRAM (Compressed RAM Swap)? (y/n): " INSTALL_ZRAM
echo ""

# --- 2. SYSTEM UPDATE ---
echo "📦 Updating system..."
apt update && apt upgrade -y

# --- 3. USER & PRIVILEGES ---
if ! id "$NEW_USER" &>/dev/null; then
    adduser --disabled-password --gecos "" $NEW_USER
    echo "$NEW_USER:$USER_PASS" | chpasswd
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo "✅ User $NEW_USER created."
fi

# --- 4. SSH & HARDENING ---
echo "🔒 Securing SSH on port $SSH_PORT..."
mkdir -p /home/$NEW_USER/.ssh
chmod 700 /home/$NEW_USER/.ssh
touch /home/$NEW_USER/.ssh/authorized_keys
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config

# --- 5. FIREWALL & FAIL2BAN ---
apt install ufw fail2ban -y
ufw allow $SSH_PORT/tcp
ufw --force enable

cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
banaction = ufw
[sshd]
enabled = true
port = $SSH_PORT
maxretry = 3
EOF
systemctl restart fail2ban
echo "✅ Firewall and Fail2Ban configured."

# --- 6. OPTIONAL: UTILITIES ---
if [[ "$INSTALL_UTILS" =~ ^[Yy]$ ]]; then
    apt install btop pydf -y
    echo "✅ Utilities installed."
fi

# --- 7. OPTIONAL: DOCKER ---
if [[ "$INSTALL_DOCKER" =~ ^[Yy]$ ]]; then
    echo "🐳 Installing Docker..."
    apt install ca-certificates curl gnupg -y
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
    apt update && apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
    usermod -aG docker $NEW_USER
    echo "✅ Docker ready."
fi

# --- 8. OPTIONAL: POWER USER TWEAKS ---
if [[ "$APPLY_SYSCTL" =~ ^[Yy]$ ]]; then
    echo "🧠 Applying RAM optimizations..."
    {
        echo "vm.swappiness=10"
        echo "vm.vfs_cache_pressure=50"
        echo "net.core.somaxconn=1024" # Extra bonus: better handle connection spikes
    } >> /etc/sysctl.conf
    sysctl -p
    echo "✅ sysctl tweaks applied."
fi

# --- 9. OPTIONAL: zRAM ---
if [[ "$INSTALL_ZRAM" =~ ^[Yy]$ ]]; then
    echo "⚡ Installing zRAM..."
    apt install zram-tools -y
    # Configure zRAM to use 50% of RAM as compressed swap
    echo "PERCENT=50" > /etc/default/zramswap
    echo "ALGO=zstd" >> /etc/default/zramswap
    systemctl restart zramswap
    echo "✅ zRAM active (zstd compression)."
fi

# --- 10. WRAP UP ---
echo "======================================================="
echo "🎉 SETUP COMPLETE!"
echo "1. Paste your SSH Key into /home/$NEW_USER/.ssh/authorized_keys"
echo "2. Log out of root."
echo "3. Reconnect: ssh $NEW_USER@your_ip -p $SSH_PORT"
echo "======================================================="
