Core Lab: Diagnostic & Hardening Toolkit

Welcome to the official script repository for [CoreLab.tech](https://corelab.tech). This toolkit is designed for homelabbers, self-hosters, and cybersecurity enthusiasts who want to move from "default settings" to a hardened, optimized infrastructure.

Included Tools

### 1. Universal Network Auditor (`audit.sh` / `audit.ps1`)
A cross-platform diagnostic tool to visualize your network topology.
* **Detects:** CG-NAT, Double NAT, and "Green Light" public paths.
* **Health Check:** Identifies DNS leaks, upstream resolvers, and measures latency to major edge nodes.
* **Compatibility:** Linux (Bash), macOS (Zsh), and Windows (PowerShell).

### 2. Debian 13 "Master Bootstrap" (`harden.sh`)
An interactive script to take a fresh Debian 13 (Trixie) VPS from "vulnerable" to "production-ready."
* **Security:** SSH hardening, custom ports, and Fail2Ban integration.
* **Performance:** Automatic zRAM (zstd) configuration and sysctl RAM optimizations.
* **Ease of Use:** Optional Docker/Docker Compose and CLI utility installation.

### 3. Windows Server Level-Up (`harden.ps1`)
A PowerShell equivalent for Windows-based homelab hosts.
* **Optimization:** Enables native Windows Memory Compression.
* **Access:** Securely configures OpenSSH server and Windows Firewall.

---

One-Liner Execution - You can run these tools directly without cloning the repository!
You may have to install curl first, apt install curl -y

### Network Auditor
**Linux/macOS:**
```bash
curl -sL [https://corelab.tech/audit.sh](https://corelab.tech/audit.sh) | bash
```
**In Windows PowerShell:**
```PowerShell
irm [https://corelab.tech/audit.ps1](https://corelab.tech/audit.ps1) | iex
```
### Debian Hardening
**Linux/macOS:**
```bash
curl -sL [https://corelab.tech/harden.sh](https://corelab.tech/harden.sh) | bash
```
License & Attribution
These tools are released under the MIT License. You are free to use, modify, and distribute them. Attribution back to CoreLab.tech is appreciated.

Community
If you find a bug or have a feature request, please open an Issue or submit a Pull Request.

Stay curious. Stay secure. - Joe, Core Lab
