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
# NEW: Python Virtual Environment Directory for better organization
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
#           INSTALL APT TOOLS (Core Tools)
##############################################
install_apt_tools() {
    section "Installing APT Packages (Nmap, Go, Python-Venv, etc.)"

    run_cmd "sudo apt update"

    APT_TOOLS=(
        # Core Network Scanning and Analysis
        nmap dnsutils whois net-tools wireshark tshark tcpdump
        
        # Web Application Tools
        sqlmap wpscan ffuf gobuster
        
        # Password Cracking & Wireless
        john hashcat aircrack-ng hcxtools
        
        # Exploitation & Remote Access
        metasploit-framework proxychains
        
        # Basic Dependencies + GO language compiler + VENV support
        python3 python3-pip python3-venv git build-essential golang-go
    )

    for tool in "${APT_TOOLS[@]}"; do
        echo -e "${CYAN}Installing $tool...${RESET}"
        run_cmd "sudo apt install -y $tool"
    done
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
#         INSTALL PYTHON LIBRARIES (IN VENV)
##############################################
install_python_libs() {
    section "Installing Global Python Dependencies (In VENV)"

    # Libraries for various tools, including Impacket dependencies
    PY_LIBS=(requests bs4 paramiko scapy)
    PIPX_PACKAGES=("impacket") 

    # Use the venv's pip to install core libraries
    for lib in "${PY_LIBS[@]}"; do
        echo -e "${CYAN}Installing Python module $lib...${RESET}"
        run_cmd "$VENV_DIR/bin/pip install $lib"
    done

    # Install pipx system-wide or with system python, as it's meant to manage isolated environments
    echo -e "${CYAN}Installing pipx system-wide...${RESET}"
    run_cmd "pip3 install pipx"
    
    # Install impacket using pipx for further isolation
    echo -e "${CYAN}Installing impacket using pipx...${RESET}"
    run_cmd "pipx install impacket"
}

##############################################
#           INSTALL GIT TOOLS (Cloning tools)
##############################################
install_git_tool() {
    local name="$1"
    local repo="$2"
    local target="$TOOLS_DIR/$name"

    echo -e "${CYAN}--- Cloning $name ---${RESET}"

    if [ ! -d "$target" ]; then
        run_cmd "git clone --depth 1 \"$repo\" \"$target\""
    else
        echo -e "${YELLOW}Tool $name already exists. Pulling latest code...${RESET}"
        run_cmd "git -C \"$target\" pull"
    fi
}

##############################################
#           INSTALL GO TOOLS (Compiled from source)
##############################################
install_go_tool() {
    local name="$1"
    local repo="$2"

    echo -e "${CYAN}--- Installing Go tool: $name ---${RESET}"
    
    if ! command -v go >/dev/null 2>&1; then
        echo -e "${RED}[✖] Go compiler not found. Skipping Go tool installation.${RESET}"
        return 1
    fi

    run_cmd "go install $repo@latest"
}

install_advanced_tools() {

    section "Cloning and Installing Pentest Tools (Go, Git, Pipx)"

    # Go-based Tools (High performance, compiled)
    install_go_tool "subfinder" "github.com/projectdiscovery/subfinder/cmd/subfinder"
    install_go_tool "katana" "github.com/projectdiscovery/katana/cmd/katana"
    install_go_tool "nuclei" "github.com/projectdiscovery/nuclei/v2/cmd/nuclei"
    install_go_tool "assetfinder" "github.com/tomnomnom/assetfinder" 

    # Git-cloned Tools (Python or wordlists/resources)
    install_git_tool "dirsearch" "https://github.com/maurosoria/dirsearch"
    install_git_tool "ghauri" "https://github.com/r0oth3x49/ghauri" 
    install_git_tool "SecLists" "https://github.com/danielmiessler/SecLists" 
    
    # Responder is a Python tool that relies on the venv
    install_git_tool "Responder" "https://github.com/lgandx/Responder"
    
    # Burp Suite Note for User
    section "Burp Suite Manual Installation"
    echo -e "${YELLOW}Burp Suite (Community or Pro) is a critical web proxy that requires a manual download and installation from PortSwigger's website. Please do this after the script finishes.${RESET}"
}

##############################################
#           CREATE ALIASES FILE
##############################################
create_aliases() {
    section "Creating ~/.noobie_aliases"

cat > "$ALIAS_FILE" << 'EOF'
# ============================
# NOOBIE INSTALLER v1 ALIASES
# ============================

# Quick Menu Launcher
alias noobie="$HOME/Pentest/Tools/noobie-menu"

# Go-compiled Tools (Assumes $HOME/go/bin is in PATH)
alias subfinder="$HOME/go/bin/subfinder" 
alias katana="$HOME/go/bin/katana"
alias nuclei="$HOME/go/bin/nuclei"
alias assetfinder="$HOME/go/bin/assetfinder"

# Python Tools (Using noobie_venv interpreter)
alias dirsearch="$HOME/Pentest/noobie_venv/bin/python $HOME/Pentest/Tools/dirsearch/dirsearch.py"
alias gh="$HOME/Pentest/noobie_venv/bin/python $HOME/Pentest/Tools/ghauri/ghauri.py"
alias responder="$HOME/Pentest/noobie_venv/bin/python $HOME/Pentest/Tools/Responder/Responder.py" 

# Utility
alias msf="msfconsole"

# Disclaimer Reminder
alias noobie_disclaimer="echo -e \"\n[!!!] DISCLAMER: Any hacking or exploitation, the developer has no legal obligation. Use at your own risk.\n\""

EOF

    echo -e "${GREEN}[✔] Aliases created.${RESET}"
}

##############################################
#     ENSURE ~/.bashrc SOURCES THE ALIASES AND GO PATH
##############################################
add_alias_source() {
    section "Configuring Shell Environment"
    
    if ! grep -q "source ~/.noobie_aliases" "$HOME/.bashrc"; then
        echo "source ~/.noobie_aliases" >> "$HOME/.bashrc"
        log "Added alias source to .bashrc"
        echo -e "${GREEN}[✔] Added alias source to ~/.bashrc.${RESET}"
    else
        echo -e "${YELLOW}Alias source is already in ~/.bashrc. Skipping.${RESET}"
    fi

    # Add Go binary path to PATH if not present
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

    echo -e "\n${CYAN}5. Subfinder (Subdomain Discovery - Active)${RESET}"
    echo "Subfinder finds valid subdomains using active techniques like search engine scraping and certificate transparency: ${YELLOW}subfinder -d example.com${RESET}"

    echo -e "\n${CYAN}6. Assetfinder (Subdomain Discovery - Passive)${RESET}"
    echo "Assetfinder focuses on passive data sources like Crt.sh and VirusTotal to find domain-related assets: ${YELLOW}assetfinder example.com${RESET}"
    
    echo -e "\n${CYAN}7. Dirsearch (Web Directory Bruteforcer)${RESET}"
    echo "Dirsearch is used to bruteforce directories and files on a web server: ${YELLOW}dirsearch -u http://example.com -e php,html,js${RESET}"

    echo -e "\n${CYAN}8. Katana (Crawler/Linkfinder)${RESET}"
    echo "Katana is a fast web crawler to find all links from an initial URL. Output links only: ${YELLOW}katana -u http://example.com -jc${RESET}"

    echo -e "\n${CYAN}9. Nuclei (Vulnerability Scanner)${RESET}"
    echo "Nuclei sends requests based on open-source templates to scan for security issues. Run a basic scan against a target: ${YELLOW}nuclei -u http://example.com${RESET}"
    
    echo -e "\n${CYAN}10. Ghauri (Advanced SQL Injector)${RESET}"
    echo "Ghauri uses the same principles as sqlmap but a different approach, often useful when sqlmap fails: ${YELLOW}gh -u 'http://site.com/param=1'${RESET}"

    echo -e "\n${CYAN}11. Responder (LLMNR/NBT-NS/mDNS poisoner)${RESET}"
    echo "Responder is used to force endpoints to authenticate against the attacker by poisoning name services: ${YELLOW}responder -I eth0 -wF${RESET}"
    
    echo -e "\nPress [Enter] to return to the main menu."
    read -r
}


while true; do
    clear
    echo -e "${CYAN}--- NOOBIE MENU ---${RESET}"
    echo -e "${CYAN}--- Tools Section ---${RESET}"
    echo -e "1) ${GREEN}Nmap${RESET} (Network Scanner)"
    echo -e "2) ${GREEN}Sqlmap${RESET} (SQL Injection)"
    echo -e "3) ${GREEN}WPScan${RESET} (WordPress Scanner)"
    echo -e "4) ${GREEN}Metasploit${RESET} (Exploitation Console)"
    echo -e "-------------------------"
    echo -e "5) ${GREEN}Subfinder${RESET} (Subdomain Discovery - Active)"
    echo -e "6) ${GREEN}Assetfinder${RESET} (Subdomain Discovery - Passive)"
    echo -e "7) ${GREEN}Dirsearch${RESET} (Web Directory Bruteforcer)"
    echo -e "8) ${GREEN}Katana${RESET} (Crawler/Linkfinder)"
    echo -e "9) ${GREEN}Nuclei${RESET} (Vulnerability Scanner)"
    echo -e "10) ${GREEN}Ghauri${RESET} (Advanced SQL Injector)"
    echo -e "11) ${GREEN}Responder${RESET} (Name Resolution Attack Tool)"
    echo -e "${MAGENTA}====================================================${RESET}"
    echo -e "${MAGENTA}--- Option Section ---${RESET}"
    echo -e "M) ${YELLOW}View Tool Manuals & Usage Guide${RESET}"
    echo -e "A) ${YELLOW}About NOOBIE Installer${RESET}"          
    echo -e "E) ${RED}Exit${RESET}"
    echo -e "-------------------------"

    # Display Disclaimer
    echo -e "${RED}DISCLAIMER: Any hacking or exploitation, the developer has no legal obligation. Use at your own risk.${RESET}"
    
    read -rp "> Enter choice (e.g., 'msf', '1', 'M', or 'A'): " ch
    ch=$(echo "$ch" | tr '[:upper:]' '[:lower:]') # Convert to lowercase for case-insensitive check

    case "$ch" in
        1|"nmap") nmap ;;
        2|"sqlmap") sqlmap ;;
        3|"wpscan") wpscan ;;
        4|"metasploit"|"msf") msfconsole ;; 
        5|"subfinder") subfinder ;;
        6|"assetfinder") assetfinder ;;
        7|"dirsearch") dirsearch ;;
        8|"katana") katana ;;
        9|"nuclei") nuclei ;;
        10|"ghauri"|"gh") gh ;;
        11|"responder") responder ;;
        "m"|"manual") view_manuals ;;
        "a"|"about"|"info") view_info ;;  
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
#            CREATE UNINSTALLER
##############################################
create_uninstaller() {
    UNINSTALLER="$TOOLS_DIR/noobie-uninstall.sh"

cat > "$UNINSTALLER" << 'EOF'
#!/usr/bin/env bash

# File paths
ALIAS_FILE="$HOME/.noobie_aliases"
BASHRC_FILE="$HOME/.bashrc"
PENTEST_DIR="$HOME/Pentest"
PIPX_PACKAGES=("impacket")

RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
RESET="\e[0m"

echo -e "${YELLOW}This script will remove the $PENTEST_DIR directory, including the tools, virtual environment, and $ALIAS_FILE file.${RESET}"
echo -e "${YELLOW}It will also attempt to remove 'impacket' if installed via pipx and remove the alias/path sources from $BASHRC_FILE.${RESET}"

read -rp "Continue? (y/n): " y

if [[ "$y" == "y" ]]; then
    echo -e "${RED}Deleting $PENTEST_DIR...${RESET}"
    rm -rf "$PENTEST_DIR"
    
    echo -e "${RED}Deleting $ALIAS_FILE...${RESET}"
    rm -f "$ALIAS_FILE"
    
    echo -e "${YELLOW}Removing alias source and Go PATH from ~/.bashrc...${RESET}"
    # Use sed to remove the lines referencing the alias file and the Go path
    if command -v sed >/dev/null 2>&1; then
        sed -i '/source ~\/\.noobie_aliases/d' "$HOME/.bashrc"
        sed -i '/export PATH="\$PATH:\$HOME\/go\/bin"/d' "$HOME/.bashrc"
    else
        echo -e "${RED}Could not find 'sed'. Please manually remove 'source ~/.noobie_aliases'\n and the Go PATH line from your shell configuration file.${RESET}"
    fi

    if command -v pipx >/dev/null 2>&1; then
        for pkg in "${PIPX_PACKAGES[@]}"; do
            echo -e "${YELLOW}Attempting to uninstall pipx package: $pkg...${RESET}"
            pipx uninstall "$pkg" 2>/dev/null
        done
    fi

    echo -e "\n${GREEN}[✔] Uninstallation complete.${RESET}"
    echo -e "NOTE: System packages (nmap, metasploit, etc.) installed via 'sudo apt' were not removed."
else
    echo -e "${GREEN}Operation cancelled.${RESET}"
fi

EOF

    chmod +x "$UNINSTALLER"
    echo -e "${GREEN}[✔] Uninstaller created at $UNINSTALLER.${RESET}"
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

install_jq
install_apt_tools
setup_venv                 # Setup the virtual environment
install_python_libs        # Installs libs into the venv and pipx system-wide
install_advanced_tools 

create_aliases
add_alias_source
create_menu
create_uninstaller

section "INSTALLATION COMPLETE"

echo -e "You've successfully run the Noobie Installer v1."
echo -e "\nIMPORTANT NEXT STEPS:"
echo -e "1. ${GREEN}Restart your terminal or run 'source ~/.bashrc'${RESET} to load the new tool aliases."
echo -e "2. ${GREEN}Launch the menu tool at any time by simply typing 'noobie'${RESET} in your terminal."
echo -e "3. ${YELLOW}Manually install Burp Suite (Community or Pro) from PortSwigger's website, as it is a graphical Java application.${RESET}"
echo -e "\n${RED}Noobie Installer v1${RESET}"
echo -e "${RED}Developer: Noobie Emci from Noobie Team, a group dedicated to promoting ethical hacking.${RESET}"
