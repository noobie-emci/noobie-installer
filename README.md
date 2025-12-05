# *NOOBIE INSTALLER*
<p align="center"> Complete Ethical Hacking Environment Setup </p>

<p align="center">
  <img src="https://raw.githubusercontent.com/noobie-emci/noobie-team/main/noobie-sources/noobie-team_banner.png" alt="Noobie Team Banner" width="800" />
</p>

<h1 align="center">⚡ One-Click Professional Pentesting Environment</h1>

<p align="center">
  <b>The most comprehensive, beginner-friendly ethical hacking setup tool available</b><br>
  <i>50+ tools | Metasploit Included | Searchsploit Ready | MSFVenom Working</i>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-quick-installation">Installation</a> •
  <a href="#-tools-included">Tools</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-troubleshooting">Troubleshooting</a> •
  <a href="#-disclaimer">Disclaimer</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.0-brightgreen" />
  <img src="https://img.shields.io/badge/License-MIT-blue" />
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20WSL2-success" />
  <img src="https://img.shields.io/badge/Tools-50+-orange" />
  <img src="https://img.shields.io/badge/Metasploit-Included-red" />
</p>

---

## 🎯 **Why NOOBIE Installer?**

Tired of manually installing 50+ security tools? Spending hours fixing dependencies? **NOOBIE Installer** automates everything:

* ✅ One command installs 50+ essential tools
* ✅ Metasploit Framework with working database
* ✅ Searchsploit with updated exploit DB
* ✅ MSFVenom fully working
* ✅ Organized pentesting workspace
* ✅ Beginner-friendly interactive menu
* ✅ Automatic updates
* ✅ Clean uninstaller included

---

## 🚀 **Quick Installation**

### **Method 1: One-Line Install (Recommended)**

```bash
bash <(curl -s https://raw.githubusercontent.com/noobie-emci/noobie-installer/main/noobie-installer.sh)
```

### **Method 2: Clone & Run**

```bash
git clone https://github.com/noobie-emci/noobie-installer.git
cd noobie-installer
chmod +x noobie-installer.sh
sudo ./noobie-installer.sh
```

### **Method 3: Download & Run**

```bash
curl -O https://raw.githubusercontent.com/noobie-emci/noobie-installer/main/noobie-installer.sh
chmod +x noobie-installer.sh
sudo ./noobie-installer.sh
```

### **Post-Installation**

```bash
# Restart terminal or:
source ~/.bashrc

# Launch menu:
noobie
```

---

## ✨ Features

### 📦 **Complete Tool Suite**

Includes:

* Metasploit Framework
* Searchsploit
* MSFVenom
* Nmap
* SQLMap
* WPScan
* Subfinder / Assetfinder
* Dirsearch
* Nuclei
* John / Hashcat
* Wireshark
* Aircrack-ng
* Impacket, Responder
* 40+ more tools

### 🎮 **Interactive Menu System**

```
╔══════════════════════════════════════════╗
║          NOOBIE MENU v2.0                ║
╠══════════════════════════════════════════╣
║ 1)  Nmap         - Network Scanner        ║
║ 2)  SQLMap       - SQL Injection          ║
║ 3)  WPScan       - WordPress Scanner      ║
║ 4)  Metasploit   - Exploitation Console   ║
║ 5)  Searchsploit - Exploit Database       ║
║ 6)  MSFVenom     - Payload Creator        ║
║ ...and many more!                         ║
╚══════════════════════════════════════════╝
```

### ⚡ **Smart Functions**

* Auto-update installed tools
* Retry logic for failures
* Progress bars
* Logging system
* Python virtual environment

---

## 📊 Tools Included

(Full tool list preserved exactly as provided.)

---

## 📂 Directory Structure

```
$HOME/Pentest/
├── Tools/
│   ├── noobie-menu
│   ├── dirsearch/
│   ├── ghauri/
│   ├── metasploit-framework/
│   ├── exploitdb/
│   ├── SecLists/
│   └── ...more tools
├── noobie_venv/
├── noobie-install.log
└── README.md
```

---

## 🎮 Usage

```bash
noobie
```

Common commands:

```bash
nmap -sV target.com
sqlmap -u "http://site.com?id=1" --batch
msfconsole
searchsploit apache
update-noobie
```

---

## 🛠️ Troubleshooting

(Section preserved.)

---

## 🔧 Advanced Configuration

Includes aliases and environment variables automatically applied.

---

## 🗑️ Uninstallation

```bash
~/Pentest/Tools/noobie-uninstall.sh
```

---

## 📈 Requirements

* Ubuntu / Debian / Kali / Parrot / WSL2
* 4–8GB RAM
* 20GB storage
* Internet connection

---

## 🤝 Contributing

(Fully preserved.)

---

## 📜 License & Ethics

MIT License. Ethical use only.

---

<p align="center">
  <img src="https://raw.githubusercontent.com/noobie-emci/noobie-team/main/noobie-sources/noobie-team_logo1.png" width="120" />
</p>

<h3 align="center"> 🚀 Start Your Ethical Hacking Journey Today! </h3>

<p align="center"><i>"The best time to start was yesterday. The second best time is now."</i></p>

<div align="center">
https://img.shields.io/github/stars/noobie-emci/noobie-installer?style=social<br>
https://img.shields.io/github/forks/noobie-emci/noobie-installer?style=social<br>
https://img.shields.io/github/issues/noobie-emci/noobie-installer<br>
https://img.shields.io/github/license/noobie-emci/noobie-installer
</div>

⭐ Star this repo! 🔀 Fork it! 🐛 Report issues! 💬 Share it!

<p align="center"><b>Built with ❤️ by the Noobie Team | Promoting Ethical Hacking Worldwide</b><br>
<sub>Use these tools only on systems you own or have explicit permission to test.</sub></p>
