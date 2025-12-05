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
WORDLISTS_DIR="$PENTEST_DIR/Wordlists"
VENV_DIR="$PENTEST_DIR/noobie_venv"
LOGFILE="$PENTEST_DIR/noobie-install.log"
ALIAS_FILE="$HOME/.noobie_aliases"

# Ensure directories exist
mkdir -p "$TOOLS_DIR" "$WORDLISTS_DIR" 2>/dev/null || true

##############################################
#            COLOR CODES
##############################################
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
BLUE="\e[34m"
RESET="\e[0m"
BOLD="\e[1m"

##############################################
#            LOGGING FUNCTION
##############################################
log() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") :: $1" | tee -a "$LOGFILE" 2>/dev/null || echo -e "$(date +"%Y-%m-%d %H:%M:%S") :: $1"
}

##############################################
#     RUN COMMAND WITH RETRY
##############################################
run_cmd() {
    local cmd="$1"
    local retries=2
    local count=0

    echo -e "${CYAN}Executing: $cmd${RESET}"

    until eval "$cmd" >>"$LOGFILE" 2>&1; do
        count=$((count+1))
        if [ $count -ge $retries ]; then
            echo -e "${YELLOW}[!] Failed after $count retries: $cmd${RESET}"
            log "Failed after retries: $cmd"
            return 1
        fi
        echo -e "${YELLOW}[!] Retry $count for: ${cmd}${RESET}"
        sleep 3
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
#        ENSURE jq INSTALLED
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
#           FIX APT REPOSITORIES
##############################################
fix_apt_repos() {
    section "Fixing APT Repositories"
    
    echo -e "${YELLOW}Updating APT sources...${RESET}"
    run_cmd "sudo apt update --fix-missing"
    run_cmd "sudo apt install -y software-properties-common apt-transport-https ca-certificates"
    
    # Add universe/multiverse for Ubuntu
    run_cmd "sudo add-apt-repository universe -y" 2>/dev/null || true
    run_cmd "sudo add-apt-repository multiverse -y" 2>/dev/null || true
    
    run_cmd "sudo apt update"
}

##############################################
#           INSTALL APT TOOLS (Core Tools)
##############################################
install_apt_tools() {
    section "Installing APT Packages"

    run_cmd "sudo apt update"

    # Split tools into groups for better error handling
    APT_ESSENTIAL=(
        nmap dnsutils whois net-tools wireshark tshark tcpdump
        sqlmap ffuf gobuster john hashcat aircrack-ng hcxtools
        python3 python3-pip python3-venv git build-essential golang-go ruby-full zlib1g-dev
        netcat-openbsd htop curl wget tree jq unzip whatweb nikto masscan crunch cewl
        hydra
    )

    APT_OPTIONAL=(
        metasploit-framework
        exploitdb
        theharvester
        wordlists
        seclists
    )

    echo -e "${CYAN}Installing essential tools (always try)...${RESET}"
    for tool in "${APT_ESSENTIAL[@]}"; do
        echo -e "${CYAN}Installing $tool...${RESET}"
        if run_cmd "sudo apt install -y $tool"; then
            echo -e "${GREEN}✓ $tool installed${RESET}"
        else
            echo -e "${YELLOW}✗ $tool failed, continuing...${RESET}"
        fi
    done

    echo -e "\n${CYAN}Installing optional tools (may fail on some systems)...${RESET}"
    for tool in "${APT_OPTIONAL[@]}"; do
        echo -e "${CYAN}Trying $tool...${RESET}"
        if sudo apt install -y "$tool" 2>/dev/null; then
            echo -e "${GREEN}✓ $tool installed${RESET}"
        else
            echo -e "${YELLOW}✗ $tool not available via APT${RESET}"
        fi
    done
}

##############################################
#        INSTALL METASPLOIT ALTERNATIVE
##############################################
install_metasploit_alt() {
    section "Installing Metasploit (Alternative Method)"
    
    if command -v msfconsole >/dev/null 2>&1; then
        echo -e "${GREEN}Metasploit is already installed.${RESET}"
        return 0
    fi
    
    echo -e "${YELLOW}Metasploit APT installation failed. Trying alternative methods...${RESET}"
    
    # Method 1: Official installer
    echo -e "${CYAN}Trying official Metasploit installer...${RESET}"
    MSF_TEMP="/tmp/msf_install"
    
    if curl -s https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > "$MSF_TEMP" 2>/dev/null; then
        chmod 755 "$MSF_TEMP"
        if "$MSF_TEMP"; then
            echo -e "${GREEN}✓ Metasploit installed via official installer${RESET}"
            rm -f "$MSF_TEMP"
            return 0
        fi
    fi
    
    # Method 2: Git clone
    echo -e "${CYAN}Trying Git clone method...${RESET}"
    local msf_dir="$TOOLS_DIR/metasploit-framework"
    
    if [ ! -d "$msf_dir" ]; then
        if run_cmd "git clone https://github.com/rapid7/metasploit-framework.git $msf_dir"; then
            echo -e "${YELLOW}Metasploit cloned to $msf_dir${RESET}"
            echo -e "${YELLOW}Run manually: cd $msf_dir && ./msfconsole${RESET}"
        fi
    fi
    
    echo -e "${YELLOW}Metasploit installation may require manual setup.${RESET}"
    return 1
}

##############################################
#        INSTALL EXPLOITDB ALTERNATIVE
##############################################
install_exploitdb_alt() {
    section "Installing ExploitDB/Searchsploit"
    
    if command -v searchsploit >/dev/null 2>&1; then
        echo -e "${GREEN}Searchsploit is already installed.${RESET}"
        return 0
    fi
    
    echo -e "${YELLOW}ExploitDB APT installation failed. Trying alternative...${RESET}"
    
    # Method 1: Clone exploitdb
    echo -e "${CYAN}Cloning ExploitDB...${RESET}"
    local exploitdb_dir="$TOOLS_DIR/exploitdb"
    
    if [ ! -d "$exploitdb_dir" ]; then
        if run_cmd "git clone https://github.com/offensive-security/exploitdb.git $exploitdb_dir"; then
            sudo ln -sf "$exploitdb_dir/searchsploit" /usr/local/bin/searchsploit 2>/dev/null || true
            sudo chmod +x /usr/local/bin/searchsploit 2>/dev/null || true
            echo -e "${GREEN}✓ ExploitDB cloned${RESET}"
            echo -e "${YELLOW}Use: $exploitdb_dir/searchsploit or searchsploit${RESET}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}Searchsploit may not be fully installed.${RESET}"
    return 1
}

##############################################
#        INSTALL THEHARVESTER ALTERNATIVE
##############################################
install_theharvester_alt() {
    section "Installing TheHarvester"
    
    if command -v theHarvester >/dev/null 2>&1; then
        echo -e "${GREEN}TheHarvester is already installed.${RESET}"
        return 0
    fi
    
    echo -e "${YELLOW}TheHarvester APT installation failed. Trying Git clone...${RESET}"
    
    local harvester_dir="$TOOLS_DIR/theHarvester"
    
    if [ ! -d "$harvester_dir" ]; then
        if run_cmd "git clone https://github.com/laramies/theHarvester.git $harvester_dir"; then
            if [ -f "$harvester_dir/requirements.txt" ]; then
                run_cmd "$VENV_DIR/bin/pip install -r $harvester_dir/requirements.txt"
            fi
            echo -e "${GREEN}✓ TheHarvester cloned${RESET}"
            echo -e "${YELLOW}Use: $VENV_DIR/bin/python $harvester_dir/theHarvester.py${RESET}"
            return 0
        fi
    fi
    
    return 1
}

##############################################
#        INSTALL WORDLISTS
##############################################
install_wordlists() {
    section "Installing Wordlists"
    
    # 1. SecLists
    echo -e "${CYAN}Installing SecLists...${RESET}"
    local seclists_dir="$TOOLS_DIR/SecLists"
    
    if [ ! -d "$seclists_dir" ]; then
        if run_cmd "wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O /tmp/SecList.zip 2>/dev/null"; then
            run_cmd "unzip -q /tmp/SecList.zip -d $TOOLS_DIR 2>/dev/null"
            run_cmd "mv $TOOLS_DIR/SecLists-master $seclists_dir 2>/dev/null || true"
            run_cmd "rm -f /tmp/SecList.zip 2>/dev/null"
        else
            run_cmd "git clone --depth 1 https://github.com/danielmiessler/SecLists.git $seclists_dir 2>/dev/null" || \
            echo -e "${YELLOW}SecLists clone failed${RESET}"
        fi
    fi
    
    # 2. Additional wordlists
    echo -e "${CYAN}Installing additional wordlists...${RESET}"
    local wordlists_dir="$TOOLS_DIR/wordlists"
    
    if [ ! -d "$wordlists_dir" ]; then
        run_cmd "git clone --depth 1 https://github.com/kkrypt0nn/wordlists.git $wordlists_dir 2>/dev/null" || \
        echo -e "${YELLOW}Wordlists clone failed${RESET}"
    fi
    
    # 3. Copy to Wordlists directory
    echo -e "${CYAN}Organizing wordlists...${RESET}"
    mkdir -p "$WORDLISTS_DIR" 2>/dev/null || true
    
    if [ -d "$seclists_dir" ]; then
        [ -d "$seclists_dir/Discovery" ] && cp -r "$seclists_dir/Discovery/"* "$WORDLISTS_DIR/" 2>/dev/null || true
        [ -d "$seclists_dir/Passwords" ] && cp -r "$seclists_dir/Passwords/"* "$WORDLISTS_DIR/" 2>/dev/null || true
        [ -d "$seclists_dir/Fuzzing" ] && cp -r "$seclists_dir/Fuzzing/"* "$WORDLISTS_DIR/" 2>/dev/null || true
    fi
    
    if [ -d "$wordlists_dir" ]; then
        cp -r "$wordlists_dir/"* "$WORDLISTS_DIR/" 2>/dev/null || true
    fi
}

##############################################
#        INSTALL ROCKYOU.TXT WORDLIST
##############################################
install_rockyou() {
    section "Installing RockYou Wordlist"
    
    ROCKYOU_PATH="$WORDLISTS_DIR/rockyou.txt"
    
    # Ensure directory exists
    mkdir -p "$WORDLISTS_DIR" 2>/dev/null || true
    
    if [ -f "$ROCKYOU_PATH" ]; then
        echo -e "${GREEN}RockYou already exists in Pentest folder.${RESET}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing RockYou wordlist...${RESET}"
    
    # Try multiple sources
    SOURCES=(
        "/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt"
        "/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.gz"
        "/usr/share/wordlists/rockyou.txt"
        "/usr/share/wordlists/rockyou.txt.gz"
    )
    
    for source in "${SOURCES[@]}"; do
        if [ -f "$source" ]; then
            echo -e "${CYAN}Found at: $source${RESET}"
            if [[ "$source" == *.gz ]]; then
                run_cmd "gunzip -c \"$source\" > \"$ROCKYOU_PATH\" 2>/dev/null"
            else
                run_cmd "cp \"$source\" \"$ROCKYOU_PATH\" 2>/dev/null"
            fi
            
            if [ -f "$ROCKYOU_PATH" ] && [ -s "$ROCKYOU_PATH" ]; then
                run_cmd "chmod 644 \"$ROCKYOU_PATH\" 2>/dev/null"
                echo -e "${GREEN}✓ RockYou installed from system${RESET}"
                return 0
            fi
        fi
    done
    
    # Download if not found
    echo -e "${CYAN}Downloading RockYou from external source...${RESET}"
    
    if run_cmd "wget -q -O \"$ROCKYOU_PATH.gz\" https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt.gz 2>/dev/null"; then
        gunzip -f "$ROCKYOU_PATH.gz" 2>/dev/null
        if [ -f "$ROCKYOU_PATH" ]; then
            echo -e "${GREEN}✓ RockYou downloaded${RESET}"
            return 0
        fi
    fi
    
    # Create placeholder if all else fails
    echo -e "${YELLOW}Creating RockYou placeholder file...${RESET}"
    echo "# RockYou wordlist placeholder" > "$ROCKYOU_PATH"
    echo "# Actual RockYou.txt should be placed here" >> "$ROCKYOU_PATH"
    echo "# Download from: https://github.com/brannondorsey/naive-hashcat/releases" >> "$ROCKYOU_PATH"
    echo -e "${YELLOW}Created placeholder. You may need to add RockYou manually.${RESET}"
}

##############################################
#        INSTALL WPScan (via Ruby Gem)
##############################################
install_wpscan() {
    section "Installing WPScan"
    
    if command -v wpscan >/dev/null 2>&1; then
        echo -e "${GREEN}WPScan is already installed.${RESET}"
    else
        echo -e "${CYAN}Installing WPScan via gem...${RESET}"
        run_cmd "sudo gem install wpscan" || \
        echo -e "${YELLOW}WPScan gem installation failed${RESET}"
    fi
}

##############################################
#       SETUP PYTHON VIRTUAL ENVIRONMENT
##############################################
setup_venv() {
    section "Setting up Python Virtual Environment"

    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${CYAN}Creating virtual environment...${RESET}"
        run_cmd "python3 -m venv $VENV_DIR 2>/dev/null || python3 -m venv --without-pip $VENV_DIR 2>/dev/null"
        
        # Upgrade pip if available
        if [ -f "$VENV_DIR/bin/pip" ]; then
            run_cmd "$VENV_DIR/bin/pip install --upgrade pip 2>/dev/null"
        fi
    else
        echo -e "${YELLOW}Virtual environment already exists.${RESET}"
    fi
}

##############################################
#         INSTALL PYTHON LIBRARIES
##############################################
install_python_libs() {
    section "Installing Python Dependencies"
    
    PY_LIBS=(requests bs4 paramiko colorama termcolor)
    
    for lib in "${PY_LIBS[@]}"; do
        echo -e "${CYAN}Installing $lib...${RESET}"
        run_cmd "$VENV_DIR/bin/pip install $lib 2>/dev/null" || \
        run_cmd "python3 -m pip install $lib 2>/dev/null" || \
        echo -e "${YELLOW}Failed to install $lib${RESET}"
    done
}

##############################################
#           INSTALL GIT TOOLS
##############################################
install_git_tool() {
    local name="$1"
    local repo="$2"
    local target="$TOOLS_DIR/$name"

    echo -e "${CYAN}--- Installing $name ---${RESET}"

    if [ ! -d "$target" ]; then
        run_cmd "git clone --depth 1 \"$repo\" \"$target\" 2>/dev/null" || \
        echo -e "${YELLOW}Failed to clone $name${RESET}"
    else
        echo -e "${YELLOW}$name exists, pulling updates...${RESET}"
        run_cmd "git -C \"$target\" pull 2>/dev/null" || true
    fi
    
    # Install requirements if they exist
    if [ -f "$target/requirements.txt" ]; then
        echo -e "${CYAN}Installing requirements for $name...${RESET}"
        run_cmd "$VENV_DIR/bin/pip install -r $target/requirements.txt 2>/dev/null" || \
        echo -e "${YELLOW}Failed to install requirements for $name${RESET}"
    fi
}

##############################################
#           INSTALL GO TOOLS - WITH SYMLINKS
##############################################
install_go_tool() {
    local name="$1"
    local repo="$2"
    local BINARY_PATH="$HOME/go/bin/$name"

    echo -e "${CYAN}--- Installing $name ---${RESET}"
    
    # Check if already in /usr/local/bin (symlink)
    if command -v "$name" >/dev/null 2>&1 && [ -L "/usr/local/bin/$name" ]; then
        echo -e "${GREEN}$name already available in /usr/local/bin${RESET}"
        return 0
    fi
    
    if [ -f "$BINARY_PATH" ] && [ -x "$BINARY_PATH" ]; then
        echo -e "${GREEN}$name already installed in ~/go/bin${RESET}"
        # Create symlink if not exists
        sudo ln -sf "$BINARY_PATH" "/usr/local/bin/$name" 2>/dev/null || true
        return 0
    fi

    if ! command -v go >/dev/null 2>&1; then
        echo -e "${YELLOW}Go not found, installing...${RESET}"
        run_cmd "sudo apt install -y golang-go 2>/dev/null" || {
            echo -e "${RED}Failed to install Go. Skipping $name${RESET}"
            return 1
        }
    fi

    # Set GOPATH if not set
    if [ -z "$GOPATH" ]; then
        export GOPATH="$HOME/go"
        export PATH="$PATH:$GOPATH/bin"
    fi
    
    echo -e "${YELLOW}Installing $name...${RESET}"
    
    # Install Go tool
    run_cmd "go install -v $repo@latest 2>/dev/null" || true
    
    # Create symlink to /usr/local/bin
    if [ -f "$BINARY_PATH" ]; then
        sudo ln -sf "$BINARY_PATH" "/usr/local/bin/$name" 2>/dev/null || true
        echo -e "${GREEN}✓ $name installed and linked to /usr/local/bin${RESET}"
    else
        echo -e "${YELLOW}⚠ $name may not have installed correctly${RESET}"
    fi
}

##############################################
#          INSTALL ALL TOOLS
##############################################
install_all_tools() {
    section "Installing Pentesting Tools"

    # Go tools - install with symlinks
    GO_TOOLS=(
        "subfinder:github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
        "assetfinder:github.com/tomnomnom/assetfinder"
        "httprobe:github.com/tomnomnom/httprobe"
        "waybackurls:github.com/tomnomnom/waybackurls"
        "katana:github.com/projectdiscovery/katana/cmd/katana"
        "nuclei:github.com/projectdiscovery/nuclei/v2/cmd/nuclei"
        "gau:github.com/lc/gau/v2/cmd/gau"
        "amass:github.com/owasp-amass/amass/v3/..."
    )

    echo -e "${CYAN}Installing Go tools (with symlinks to /usr/local/bin)...${RESET}"
    for tool_info in "${GO_TOOLS[@]}"; do
        name="${tool_info%%:*}"
        repo="${tool_info#*:}"
        install_go_tool "$name" "$repo"
    done

    # Git tools
    GIT_TOOLS=(
        "dirsearch:https://github.com/maurosoria/dirsearch"
        "ghauri:https://github.com/r0oth3x49/ghauri"
        "Responder:https://github.com/lgandx/Responder"
        "xsstrike:https://github.com/s0md3v/XSStrike"
        "linpeas:https://github.com/carlospolop/PEASS-ng"
        "recon-ng:https://github.com/lanmaster53/recon-ng"
        "sqlmap:https://github.com/sqlmapproject/sqlmap"
        "joomscan:https://github.com/rezasp/joomscan"
        "drupwn:https://github.com/immunIT/drupwn"
        "theHarvester:https://github.com/laramies/theHarvester"
    )

    echo -e "\n${CYAN}Installing Git tools...${RESET}"
    for tool_info in "${GIT_TOOLS[@]}"; do
        name="${tool_info%%:*}"
        repo="${tool_info#*:}"
        install_git_tool "$name" "$repo"
    done

    # Install alternative methods for failed APT tools
    install_metasploit_alt
    install_exploitdb_alt
    install_theharvester_alt
    
    # Install wordlists
    install_wordlists
    install_rockyou
}

##############################################
#           FORCE CREATE GLOBAL NOOBIE COMMAND
##############################################
force_noobie_command() {
    section "FORCING Global 'noobie' Command"
    
    # Create the command in multiple locations
    cat > /tmp/noobie-global << 'EOF'
#!/usr/bin/env bash

PENTEST_DIR="$HOME/Pentest"
TOOLS_DIR="$PENTEST_DIR/Tools"

# Check if menu exists
if [ -f "$TOOLS_DIR/noobie-menu" ]; then
    exec "$TOOLS_DIR/noobie-menu" "$@"
else
    echo "Noobie Pentest Toolkit"
    echo "Menu not found at: $TOOLS_DIR/noobie-menu"
    echo "Please run the installer again."
    exit 1
fi
EOF
    
    # Install in multiple locations for redundancy
    sudo cp /tmp/noobie-global /usr/local/bin/noobie 2>/dev/null || true
    sudo chmod +x /usr/local/bin/noobie 2>/dev/null || true
    
    cp /tmp/noobie-global /bin/noobie 2>/dev/null || true
    chmod +x /bin/noobie 2>/dev/null || true
    
    cp /tmp/noobie-global /usr/bin/noobie 2>/dev/null || true
    chmod +x /usr/bin/noobie 2>/dev/null || true
    
    # Also create in user's home
    cp /tmp/noobie-global ~/noobie 2>/dev/null || true
    chmod +x ~/noobie 2>/dev/null || true
    
    echo -e "${GREEN}✓ 'noobie' command forced to global PATH${RESET}"
}

##############################################
#           CREATE ALIASES FILE
##############################################
create_aliases() {
    section "Creating Aliases"

cat > "$ALIAS_FILE" << 'EOF'
# ============================
# NOOBIE INSTALLER ALIASES
# ============================

# Main menu - MULTIPLE FALLBACKS
alias noobie='/usr/local/bin/noobie 2>/dev/null || /bin/noobie 2>/dev/null || /usr/bin/noobie 2>/dev/null || ~/noobie 2>/dev/null || ~/Pentest/Tools/noobie-menu 2>/dev/null'

# Force PATH for Go tools
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin:/usr/local/bin"

# Go tools (now in /usr/local/bin via symlinks)
alias subfinder='subfinder'
alias katana='katana'
alias nuclei='nuclei'
alias assetfinder='assetfinder'
alias httprobe='httprobe'
alias waybackurls='waybackurls'
alias gau='gau'
alias amass='amass'

# Python tools
alias dirsearch='python3 $HOME/Pentest/Tools/dirsearch/dirsearch.py'
alias ghauri='python3 $HOME/Pentest/Tools/ghauri/ghauri.py'
alias Responder='python3 $HOME/Pentest/Tools/Responder/Responder.py'
alias xsstrike='python3 $HOME/Pentest/Tools/xsstrike/xsstrike.py'
alias recon-ng='python3 $HOME/Pentest/Tools/recon-ng/recon-ng'
alias joomscan='python3 $HOME/Pentest/Tools/joomscan/joomscan.py'
alias drupwn='python3 $HOME/Pentest/Tools/drupwn/drupwn'
alias theHarvester='python3 $HOME/Pentest/Tools/theHarvester/theHarvester.py'

# System tools
alias nmap='nmap'
alias sqlmap='sqlmap'
alias wpscan='wpscan'
alias ffuf='ffuf'
alias gobuster='gobuster'
alias msfconsole='msfconsole'
alias searchsploit='searchsploit'
alias msfvenom='msfvenom'
alias whatweb='whatweb'
alias nikto='nikto'
alias masscan='masscan'
alias crunch='crunch'
alias cewl='cewl'
alias nc='nc'

# Navigation
alias pentest='cd $HOME/Pentest'
alias tools='cd $HOME/Pentest/Tools'
alias wordlists='cd $HOME/Pentest/Wordlists'

# Wordlists
alias rockyou='echo "$HOME/Pentest/Wordlists/rockyou.txt"'

# Disclaimer
alias noobie_disclaimer='echo -e "\n[!!!] DISCLAIMER: Use only on authorized systems!\n"'

EOF

    echo -e "${GREEN}[✔] Aliases created${RESET}"
}

##############################################
#            CONFIGURE ENVIRONMENT
##############################################
configure_env() {
    section "Configuring Environment"
    
    # Force PATH update for current shell
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin:/usr/local/bin:/usr/bin:/bin"
    
    # Add aliases to bashrc
    if ! grep -q "source ~/.noobie_aliases" "$HOME/.bashrc" 2>/dev/null; then
        echo "source ~/.noobie_aliases" >> "$HOME/.bashrc"
        echo -e "${GREEN}Added aliases to .bashrc${RESET}"
    fi
    
    # Add Go to PATH in bashrc
    if ! grep -q 'export GOPATH="$HOME/go"' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export GOPATH="$HOME/go"' >> "$HOME/.bashrc"
        echo 'export PATH="$PATH:$GOPATH/bin:/usr/local/bin"' >> "$HOME/.bashrc"
        echo -e "${GREEN}Added Go and /usr/local/bin to PATH in .bashrc${RESET}"
    fi
    
    # Force source it now
    source "$ALIAS_FILE" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Environment configured${RESET}"
}

##############################################
#            CREATE MENU LAUNCHER - YOUR INTERFACE
##############################################
create_menu() {
    MENU_PATH="$TOOLS_DIR/noobie-menu"
    
cat > "$MENU_PATH" << 'EOF'
#!/usr/bin/env bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
BLUE="\e[34m"
RESET="\e[0m"
BOLD="\e[1m"

PENTEST_DIR="$HOME/Pentest"
TOOLS_DIR="$PENTEST_DIR/Tools"
VENV_DIR="$PENTEST_DIR/noobie_venv"
WORDLISTS_DIR="$PENTEST_DIR/Wordlists"

clear_screen() {
    clear 2>/dev/null || printf "\033c"
}

show_header() {
    clear_screen
    echo -e "${CYAN}"
cat << "EOF"

    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║     ███╗   ██╗ ██████╗  ██████╗ ██████╗ ██╗███████╗         ║
    ║     ████╗  ██║██╔═══██╗██╔═══██╗██╔══██╗██║██╔════╝         ║
    ║     ██╔██╗ ██║██║   ██║██║   ██║██████╔╝██║█████╗           ║
    ║     ██║╚██╗██║██║   ██║██║   ██║██╔══██╗██║██╔══╝           ║
    ║     ██║ ╚████║╚██████╔╝╚██████╔╝██║  ██║██║███████╗         ║
    ║     ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝         ║
    ║                                                              ║
    ║                P E N T E S T   T O O L K I T                 ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    echo -e "${MAGENTA}                  P E N T E S T   M E N U                  ${RESET}"
    echo -e "${YELLOW}==============================================================${RESET}"
    echo -e "${CYAN}    Developer: Noobie Emci | Version: 2.0 | $(date)${RESET}"
    echo -e "${YELLOW}==============================================================${RESET}\n"
}

show_disclaimer() {
    echo -e "${RED}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                      ⚠️   D I S C L A I M E R   ⚠️           ║
    ║  Use these tools ONLY on systems you own or have explicit    ║
    ║  written permission to test. Unauthorized access is ILLEGAL. ║
    ║                                                              ║
    ║  Developer has NO legal obligation for your actions.         ║
    ║  You are SOLELY responsible for ethical use.                 ║
    ║  ╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    echo -e "${YELLOW}Press any key to continue...${RESET}"
    read -n 1 -s
}

show_main_menu() {
    echo -e "${GREEN}┌──────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${GREEN}│                     M A I N   M E N U                        │${RESET}"
    echo -e "${GREEN}├──────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${GREEN}│                                                              │${RESET}"
    echo -e "${GREEN}│  ${CYAN}1) ${YELLOW}Information Gathering Tools                          ${GREEN}│${RESET}"
    echo -e "${GREEN}│  ${CYAN}2) ${YELLOW}Web Application Testing                              ${GREEN}│${RESET}"
    echo -e "${GREEN}│  ${CYAN}3) ${YELLOW}Wireless & Network Tools                             ${GREEN}│${RESET}"
    echo -e "${GREEN}│  ${CYAN}4) ${YELLOW}Password Attacks                                      ${GREEN}│${RESET}"
    echo -e "${GREEN}│  ${CYAN}5) ${YELLOW}Exploitation Tools                                    ${GREEN}│${RESET}"
    echo -e "${GREEN}│  ${CYAN}6) ${YELLOW}Post-Exploitation                                     ${GREEN}│${RESET}"
    echo -e "${GREEN}│  ${CYAN}7) ${YELLOW}Wordlists & Resources                                 ${GREEN}│${RESET}"
    echo -e "${GREEN}│  ${CYAN}8) ${YELLOW}Update All Tools                                      ${GREEN}│${RESET}"
    echo -e "${GREEN}│  ${CYAN}9) ${YELLOW}Quick Aliases (List All Commands)                     ${GREEN}│${RESET}"
    echo -e "${GREEN}│  ${CYAN}0) ${RED}Exit Menu                                           ${GREEN}│${RESET}"
    echo -e "${GREEN}│                                                              │${RESET}"
    echo -e "${GREEN}└──────────────────────────────────────────────────────────────┘${RESET}"
    echo -e "\n${CYAN}Enter your choice [0-9]: ${RESET}"
}

run_tool() {
    local tool_name="$1"
    local tool_cmd="$2"
    
    echo -e "\n${YELLOW}Launching $tool_name...${RESET}"
    echo -e "${CYAN}Command: $tool_cmd${RESET}"
    echo -e "${YELLOW}Press Ctrl+C to return to menu${RESET}\n"
    
    # Execute the tool
    eval "$tool_cmd" 2>/dev/null || echo -e "${RED}Failed to run $tool_name${RESET}"
    
    echo -e "\n${GREEN}$tool_name execution completed.${RESET}"
    echo -e "${YELLOW}Press any key to return to menu...${RESET}"
    read -n 1 -s
}

info_gathering_menu() {
    while true; do
        clear_screen
        echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║               INFORMATION GATHERING TOOLS                    ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
        echo -e "${RESET}"
        
        echo -e "${YELLOW}Network Scanning:${RESET}"
        echo -e "  ${CYAN}1) ${GREEN}nmap${RESET} - Network discovery and security auditing"
        echo -e "  ${CYAN}2) ${GREEN}masscan${RESET} - Mass IP port scanner"
        echo -e "  ${CYAN}3) ${GREEN}whatweb${RESET} - Website technology identifier"
        
        echo -e "\n${YELLOW}Subdomain Enumeration:${RESET}"
        echo -e "  ${CYAN}4) ${GREEN}subfinder${RESET} - Subdomain discovery tool"
        echo -e "  ${CYAN}5) ${GREEN}amass${RESET} - In-depth DNS enumeration"
        echo -e "  ${CYAN}6) ${GREEN}assetfinder${RESET} - Find domains and subdomains"
        
        echo -e "\n${YELLOW}Web Reconnaissance:${RESET}"
        echo -e "  ${CYAN}7) ${GREEN}theHarvester${RESET} - OSINT tool for emails, names, subdomains"
        echo -e "  ${CYAN}8) ${GREEN}recon-ng${RESET} - Web reconnaissance framework"
        
        echo -e "\n${YELLOW}Back to Main Menu:${RESET}"
        echo -e "  ${CYAN}0) ${RED}Return to Main Menu${RESET}"
        
        echo -e "\n${CYAN}Select tool number to launch, or 0 to return: ${RESET}"
        read -r choice
        
        case $choice in
            1) run_tool "Nmap" "nmap --help" ;;
            2) run_tool "Masscan" "masscan --help" ;;
            3) run_tool "WhatWeb" "whatweb --help" ;;
            4) 
                if command -v subfinder >/dev/null 2>&1; then
                    run_tool "Subfinder" "subfinder --help"
                else
                    echo -e "${RED}Subfinder not found. Try: go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            5) 
                if command -v amass >/dev/null 2>&1; then
                    run_tool "Amass" "amass --help"
                else
                    echo -e "${RED}Amass not found. Try: go install github.com/owasp-amass/amass/v3/...@latest${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            6) 
                if command -v assetfinder >/dev/null 2>&1; then
                    run_tool "Assetfinder" "assetfinder --help"
                else
                    echo -e "${RED}Assetfinder not found. Try: go install github.com/tomnomnom/assetfinder@latest${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            7) 
                if command -v theHarvester >/dev/null 2>&1; then
                    run_tool "TheHarvester" "theHarvester --help"
                elif [ -f "$TOOLS_DIR/theHarvester/theHarvester.py" ]; then
                    run_tool "TheHarvester" "python3 $TOOLS_DIR/theHarvester/theHarvester.py --help"
                else
                    echo -e "${RED}TheHarvester not found.${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            8) 
                if [ -f "$TOOLS_DIR/recon-ng/recon-ng" ]; then
                    run_tool "Recon-ng" "python3 $TOOLS_DIR/recon-ng/recon-ng --help"
                else
                    echo -e "${RED}Recon-ng not found.${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please enter 0-8.${RESET}"
                sleep 2
                ;;
        esac
    done
}

web_app_menu() {
    while true; do
        clear_screen
        echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                WEB APPLICATION TESTING                       ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
        echo -e "${RESET}"
        
        echo -e "${YELLOW}Web Vulnerability Scanners:${RESET}"
        echo -e "  ${CYAN}1) ${GREEN}sqlmap${RESET} - SQL injection automation"
        echo -e "  ${CYAN}2) ${GREEN}nikto${RESET} - Web server scanner"
        echo -e "  ${CYAN}3) ${GREEN}wpscan${RESET} - WordPress vulnerability scanner"
        echo -e "  ${CYAN}4) ${GREEN}dirsearch${RESET} - Web path scanner"
        echo -e "  ${CYAN}5) ${GREEN}gobuster${RESET} - Directory/file & DNS busting"
        
        echo -e "\n${YELLOW}Other Web Tools:${RESET}"
        echo -e "  ${CYAN}6) ${GREEN}ffuf${RESET} - Fast web fuzzer"
        echo -e "  ${CYAN}7) ${GREEN}xsstrike${RESET} - Advanced XSS detection"
        echo -e "  ${CYAN}8) ${GREEN}nuclei${RESET} - Vulnerability scanner"
        
        echo -e "\n${YELLOW}Back to Main Menu:${RESET}"
        echo -e "  ${CYAN}0) ${RED}Return to Main Menu${RESET}"
        
        echo -e "\n${CYAN}Select tool number to launch, or 0 to return: ${RESET}"
        read -r choice
        
        case $choice in
            1) run_tool "SQLMap" "sqlmap --hh" ;;
            2) run_tool "Nikto" "nikto --help" ;;
            3) 
                if command -v wpscan >/dev/null 2>&1; then
                    run_tool "WPScan" "wpscan --help"
                else
                    echo -e "${RED}WPScan not found. Try: sudo gem install wpscan${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            4) 
                if [ -f "$TOOLS_DIR/dirsearch/dirsearch.py" ]; then
                    run_tool "Dirsearch" "python3 $TOOLS_DIR/dirsearch/dirsearch.py --help"
                else
                    echo -e "${RED}Dirsearch not found.${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            5) run_tool "Gobuster" "gobuster --help" ;;
            6) run_tool "FFUF" "ffuf --help" ;;
            7) 
                if [ -f "$TOOLS_DIR/xsstrike/xsstrike.py" ]; then
                    run_tool "XSStrike" "python3 $TOOLS_DIR/xsstrike/xsstrike.py --help"
                else
                    echo -e "${RED}XSStrike not found.${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            8) 
                if command -v nuclei >/dev/null 2>&1; then
                    run_tool "Nuclei" "nuclei --help"
                else
                    echo -e "${RED}Nuclei not found. Try: go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please enter 0-8.${RESET}"
                sleep 2
                ;;
        esac
    done
}

wireless_menu() {
    while true; do
        clear_screen
        echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║              WIRELESS & NETWORK TOOLS                        ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
        echo -e "${RESET}"
        
        echo -e "${YELLOW}Wireless Testing:${RESET}"
        echo -e "  ${CYAN}1) ${GREEN}aircrack-ng${RESET} - WiFi security auditing tools"
        echo -e "  ${CYAN}2) ${GREEN}hcxtools${RESET} - WiFi penetration testing tools"
        
        echo -e "\n${YELLOW}Network Analysis:${RESET}"
        echo -e "  ${CYAN}3) ${GREEN}tcpdump${RESET} - Packet analyzer"
        echo -e "  ${CYAN}4) ${GREEN}wireshark${RESET} - Network protocol analyzer"
        
        echo -e "\n${YELLOW}Network Attacks:${RESET}"
        echo -e "  ${CYAN}5) ${GREEN}Responder${RESET} - LLMNR/NBT-NS poisoner"
        
        echo -e "\n${YELLOW}Back to Main Menu:${RESET}"
        echo -e "  ${CYAN}0) ${RED}Return to Main Menu${RESET}"
        
        echo -e "\n${CYAN}Select tool number to launch, or 0 to return: ${RESET}"
        read -r choice
        
        case $choice in
            1) run_tool "Aircrack-ng" "aircrack-ng --help" ;;
            2) 
                if command -v hcxdumptool >/dev/null 2>&1; then
                    run_tool "Hcxtools" "hcxdumptool --help"
                else
                    echo -e "${RED}Hcxtools not found. Try: sudo apt install hcxtools${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            3) run_tool "Tcpdump" "tcpdump --help" ;;
            4) run_tool "Wireshark" "wireshark --help" ;;
            5) 
                if [ -f "$TOOLS_DIR/Responder/Responder.py" ]; then
                    run_tool "Responder" "python3 $TOOLS_DIR/Responder/Responder.py --help"
                else
                    echo -e "${RED}Responder not found.${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please enter 0-5.${RESET}"
                sleep 2
                ;;
        esac
    done
}

password_menu() {
    while true; do
        clear_screen
        echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                    PASSWORD ATTACKS                          ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
        echo -e "${RESET}"
        
        echo -e "${YELLOW}Password Cracking:${RESET}"
        echo -e "  ${CYAN}1) ${GREEN}john${RESET} - John the Ripper password cracker"
        echo -e "  ${CYAN}2) ${GREEN}hashcat${RESET} - Advanced password recovery"
        
        echo -e "\n${YELLOW}Wordlist Tools:${RESET}"
        echo -e "  ${CYAN}3) ${GREEN}crunch${RESET} - Wordlist generator"
        echo -e "  ${CYAN}4) ${GREEN}cewl${RESET} - Custom wordlist generator from URLs"
        
        echo -e "\n${YELLOW}Back to Main Menu:${RESET}"
        echo -e "  ${CYAN}0) ${RED}Return to Main Menu${RESET}"
        
        echo -e "\n${CYAN}Select tool number to launch, or 0 to return: ${RESET}"
        read -r choice
        
        case $choice in
            1) run_tool "John the Ripper" "john --help" ;;
            2) run_tool "Hashcat" "hashcat --help" ;;
            3) run_tool "Crunch" "crunch --help" ;;
            4) run_tool "CeWL" "cewl --help" ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please enter 0-4.${RESET}"
                sleep 2
                ;;
        esac
    done
}

exploitation_menu() {
    while true; do
        clear_screen
        echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                   EXPLOITATION TOOLS                         ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
        echo -e "${RESET}"
        
        echo -e "${YELLOW}Frameworks:${RESET}"
        echo -e "  ${CYAN}1) ${GREEN}msfconsole${RESET} - Metasploit framework console"
        echo -e "  ${CYAN}2) ${GREEN}msfvenom${RESET} - Metasploit payload generator"
        
        echo -e "\n${YELLOW}Exploit Databases:${RESET}"
        echo -e "  ${CYAN}3) ${GREEN}searchsploit${RESET} - Exploit-DB command line search"
        
        echo -e "\n${YELLOW}Back to Main Menu:${RESET}"
        echo -e "  ${CYAN}0) ${RED}Return to Main Menu${RESET}"
        
        echo -e "\n${CYAN}Select tool number to launch, or 0 to return: ${RESET}"
        read -r choice
        
        case $choice in
            1) 
                if command -v msfconsole >/dev/null 2>&1; then
                    run_tool "Metasploit" "msfconsole -q"
                else
                    echo -e "${RED}Metasploit not found. Try: sudo apt install metasploit-framework${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            2) 
                if command -v msfvenom >/dev/null 2>&1; then
                    run_tool "MSFVenom" "msfvenom --help"
                else
                    echo -e "${RED}MSFVenom not found. Install Metasploit first.${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            3) 
                if command -v searchsploit >/dev/null 2>&1; then
                    run_tool "Searchsploit" "searchsploit --help"
                elif [ -f "$TOOLS_DIR/exploitdb/searchsploit" ]; then
                    run_tool "Searchsploit" "$TOOLS_DIR/exploitdb/searchsploit --help"
                else
                    echo -e "${RED}Searchsploit not found. Try: sudo apt install exploitdb${RESET}"
                    echo -e "${YELLOW}Press any key to continue...${RESET}"
                    read -n 1 -s
                fi
                ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please enter 0-3.${RESET}"
                sleep 2
                ;;
        esac
    done
}

post_exploit_menu() {
    while true; do
        clear_screen
        echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                  POST-EXPLOITATION                           ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
        echo -e "${RESET}"
        
        echo -e "${YELLOW}Privilege Escalation:${RESET}"
        echo -e "  ${CYAN}1) ${GREEN}linpeas${RESET} - Linux Privilege Escalation Awesome Script"
        
        echo -e "\n${YELLOW}Back to Main Menu:${RESET}"
        echo -e "  ${CYAN}0) ${RED}Return to Main Menu${RESET}"
        
        echo -e "\n${CYAN}Select tool number: ${RESET}"
        read -r choice
        
        case $choice in
            1) 
                if [ -f "$TOOLS_DIR/linpeas/linpeas.sh" ]; then
                    echo -e "${GREEN}LinPEAS found at: $TOOLS_DIR/linpeas/linpeas.sh${RESET}"
                    echo -e "${YELLOW}To run: bash $TOOLS_DIR/linpeas/linpeas.sh${RESET}"
                    echo -e "\n${CYAN}Press any key to return...${RESET}"
                    read -n 1 -s
                else
                    echo -e "${RED}LinPEAS not found. Cloning...${RESET}"
                    git clone https://github.com/carlospolop/PEASS-ng.git "$TOOLS_DIR/linpeas-temp" 2>/dev/null && \
                    find "$TOOLS_DIR/linpeas-temp" -name "linpeas.sh" -exec cp {} "$TOOLS_DIR/linpeas.sh" \; 2>/dev/null && \
                    rm -rf "$TOOLS_DIR/linpeas-temp" 2>/dev/null
                    
                    if [ -f "$TOOLS_DIR/linpeas.sh" ]; then
                        echo -e "${GREEN}LinPEAS downloaded to: $TOOLS_DIR/linpeas.sh${RESET}"
                        echo -e "${YELLOW}To run: bash $TOOLS_DIR/linpeas.sh${RESET}"
                    else
                        echo -e "${RED}Failed to download LinPEAS.${RESET}"
                    fi
                    echo -e "\n${CYAN}Press any key to return...${RESET}"
                    read -n 1 -s
                fi
                ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please enter 0-1.${RESET}"
                sleep 2
                ;;
        esac
    done
}

wordlists_menu() {
    while true; do
        clear_screen
        echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                 WORDLISTS & RESOURCES                       ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
        echo -e "${RESET}"
        
        echo -e "${YELLOW}Wordlist Locations:${RESET}"
        echo -e "  ${CYAN}1) ${GREEN}View RockYou wordlist${RESET}"
        echo -e "  ${CYAN}2) ${GREEN}View SecLists directory${RESET}"
        echo -e "  ${CYAN}3) ${GREEN}List all wordlists${RESET}"
        
        echo -e "\n${YELLOW}Wordlist Tools:${RESET}"
        echo -e "  ${CYAN}4) ${GREEN}crunch${RESET} - Wordlist generator"
        echo -e "  ${CYAN}5) ${GREEN}cewl${RESET} - Custom wordlist generator"
        
        echo -e "\n${YELLOW}Back to Main Menu:${RESET}"
        echo -e "  ${CYAN}0) ${RED}Return to Main Menu${RESET}"
        
        echo -e "\n${CYAN}Select option number: ${RESET}"
        read -r choice
        
        case $choice in
            1) 
                if [ -f "$WORDLISTS_DIR/rockyou.txt" ]; then
                    echo -e "${GREEN}RockYou found: $WORDLISTS_DIR/rockyou.txt${RESET}"
                    echo -e "${YELLOW}Size: $(du -h "$WORDLISTS_DIR/rockyou.txt" 2>/dev/null | cut -f1 || echo "unknown")${RESET}"
                    echo -e "${YELLOW}Press any key to return...${RESET}"
                    read -n 1 -s
                else
                    echo -e "${RED}RockYou not found in $WORDLISTS_DIR/${RESET}"
                    echo -e "${YELLOW}Try: sudo apt install seclists${RESET}"
                    echo -e "${YELLOW}Press any key to return...${RESET}"
                    read -n 1 -s
                fi
                ;;
            2) 
                if [ -d "$TOOLS_DIR/SecLists" ]; then
                    echo -e "${GREEN}SecLists found at: $TOOLS_DIR/SecLists${RESET}"
                    ls -la "$TOOLS_DIR/SecLists/" 2>/dev/null | head -20 || echo "Cannot list directory"
                    echo -e "${YELLOW}Press any key to return...${RESET}"
                    read -n 1 -s
                elif [ -d "/usr/share/seclists" ]; then
                    echo -e "${GREEN}SecLists found at: /usr/share/seclists${RESET}"
                    ls -la "/usr/share/seclists/" 2>/dev/null | head -20 || echo "Cannot list directory"
                    echo -e "${YELLOW}Press any key to return...${RESET}"
                    read -n 1 -s
                else
                    echo -e "${RED}SecLists not found${RESET}"
                    echo -e "${YELLOW}Try: sudo apt install seclists${RESET}"
                    echo -e "${YELLOW}Press any key to return...${RESET}"
                    read -n 1 -s
                fi
                ;;
            3) 
                echo -e "${GREEN}Wordlists in $WORDLISTS_DIR/${RESET}"
                ls -la "$WORDLISTS_DIR/" 2>/dev/null | head -20 || echo "No wordlists found"
                echo -e "${YELLOW}Press any key to return...${RESET}"
                read -n 1 -s
                ;;
            4) run_tool "Crunch" "crunch --help" ;;
            5) run_tool "CeWL" "cewl --help" ;;
            0) break ;;
            *) 
                echo -e "${RED}Invalid choice. Please enter 0-5.${RESET}"
                sleep 2
                ;;
        esac
    done
}

update_tools() {
    clear_screen
    echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                   UPDATE ALL TOOLS                           ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    
    echo -e "${YELLOW}Updating system packages...${RESET}"
    sudo apt update && sudo apt upgrade -y 2>/dev/null || echo -e "${RED}Failed to update system packages${RESET}"
    
    echo -e "\n${YELLOW}Updating Git tools...${RESET}"
    for dir in "$TOOLS_DIR"/*/; do
        if [ -d "$dir/.git" ]; then
            tool_name=$(basename "$dir")
            echo -e "${CYAN}Updating $tool_name...${RESET}"
            if git -C "$dir" pull 2>/dev/null; then
                echo -e "${GREEN}✓ $tool_name updated${RESET}"
            else
                echo -e "${RED}✗ Failed to update $tool_name${RESET}"
            fi
        fi
    done
    
    echo -e "\n${GREEN}✓ Update process completed${RESET}"
    echo -e "\n${YELLOW}Press any key to continue...${RESET}"
    read -n 1 -s
}

show_aliases() {
    clear_screen
    echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                   QUICK ALIASES                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    
    echo -e "${YELLOW}Main Commands:${RESET}"
    echo -e "  ${GREEN}noobie${RESET} - Launch this menu"
    echo -e "  ${GREEN}pentest${RESET} - Go to ~/Pentest directory"
    echo -e "  ${GREEN}tools${RESET} - Go to ~/Pentest/Tools directory"
    echo -e "  ${GREEN}wordlists${RESET} - Go to ~/Pentest/Wordlists directory"
    
    echo -e "\n${YELLOW}Information Gathering:${RESET}"
    echo -e "  ${GREEN}nmap${RESET}, ${GREEN}subfinder${RESET}, ${GREEN}amass${RESET}, ${GREEN}theHarvester${RESET}"
    
    echo -e "\n${YELLOW}Web Application Testing:${RESET}"
    echo -e "  ${GREEN}sqlmap${RESET}, ${GREEN}dirsearch${RESET}, ${GREEN}gobuster${RESET}, ${GREEN}ffuf${RESET}"
    echo -e "  ${GREEN}nikto${RESET}, ${GREEN}wpscan${RESET}, ${GREEN}xsstrike${RESET}, ${GREEN}nuclei${RESET}"
    
    echo -e "\n${YELLOW}Wireless & Network:${RESET}"
    echo -e "  ${GREEN}aircrack-ng${RESET}, ${GREEN}Responder${RESET}, ${GREEN}tcpdump${RESET}"
    
    echo -e "\n${YELLOW}Password Attacks:${RESET}"
    echo -e "  ${GREEN}john${RESET}, ${GREEN}hashcat${RESET}, ${GREEN}crunch${RESET}, ${GREEN}cewl${RESET}"
    
    echo -e "\n${YELLOW}Exploitation:${RESET}"
    echo -e "  ${GREEN}msfconsole${RESET}, ${GREEN}msfvenom${RESET}, ${GREEN}searchsploit${RESET}"
    
    echo -e "\n${CYAN}======================================================${RESET}"
    echo -e "${YELLOW}Tip: Type the alias name directly in terminal${RESET}"
    echo -e "${YELLOW}Example: ${GREEN}nmap -sV target.com${RESET}"
    echo -e "\n${YELLOW}Press any key to continue...${RESET}"
    read -n 1 -s
}

# Main program loop
main() {
    show_disclaimer
    
    while true; do
        show_header
        show_main_menu
        read -r choice
        
        case $choice in
            1) info_gathering_menu ;;
            2) web_app_menu ;;
            3) wireless_menu ;;
            4) password_menu ;;
            5) exploitation_menu ;;
            6) post_exploit_menu ;;
            7) wordlists_menu ;;
            8) update_tools ;;
            9) show_aliases ;;
            0)
                echo -e "\n${GREEN}Thank you for using Noobie Pentest Toolkit!${RESET}"
                echo -e "${YELLOW}Remember: With great power comes great responsibility.${RESET}"
                echo -e "${CYAN}Exiting...${RESET}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 0-9.${RESET}"
                sleep 2
                ;;
        esac
    done
}

# Run main function
main
EOF

    chmod +x "$MENU_PATH"
    echo -e "${GREEN}[✔] YOUR INTERFACE Menu created${RESET}"
}

##############################################
#            CREATE UNINSTALLER
##############################################
create_uninstaller() {
    UNINSTALLER_PATH="$TOOLS_DIR/noobie-uninstall.sh"
    
cat > "$UNINSTALLER_PATH" << 'EOF'
#!/usr/bin/env bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

PENTEST_DIR="$HOME/Pentest"
ALIAS_FILE="$HOME/.noobie_aliases"

echo -e "${CYAN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                  UNINSTALL NOOBIE TOOLS                      ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

echo -e "${RED}⚠️  WARNING: This will remove the Noobie Pentest Toolkit installation.${RESET}"
echo -e "${YELLOW}The following will be affected:${RESET}"
echo -e "  • $PENTEST_DIR/ directory"
echo -e "  • Aliases in $ALIAS_FILE"
echo -e "  • .bashrc modifications"
echo -e "  • Python virtual environment"
echo -e "  • Installed tools in $PENTEST_DIR/Tools/"
echo -e "  • Wordlists in $PENTEST_DIR/Wordlists/"

echo -e "\n${CYAN}Are you sure you want to continue? [y/N]: ${RESET}"
read -r confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Uninstall cancelled.${RESET}"
    exit 0
fi

echo -e "\n${YELLOW}Starting uninstallation...${RESET}"

# Remove aliases from .bashrc
if grep -q "source ~/.noobie_aliases" "$HOME/.bashrc" 2>/dev/null; then
    echo -e "${CYAN}Removing aliases from .bashrc...${RESET}"
    sed -i '/source ~\/.noobie_aliases/d' "$HOME/.bashrc" 2>/dev/null
fi

# Remove Go from PATH if added by installer
if grep -q 'export PATH="$PATH:$HOME/go/bin"' "$HOME/.bashrc" 2>/dev/null; then
    echo -e "${CYAN}Removing Go from PATH in .bashrc...${RESET}"
    sed -i '/export PATH="\$PATH:\$HOME\/go\/bin"/d' "$HOME/.bashrc" 2>/dev/null
fi

# Remove alias file
if [ -f "$ALIAS_FILE" ]; then
    echo -e "${CYAN}Removing alias file...${RESET}"
    rm -f "$ALIAS_FILE"
fi

# Remove noobie command from multiple locations
echo -e "${CYAN}Removing noobie command...${RESET}"
sudo rm -f /usr/local/bin/noobie 2>/dev/null || true
sudo rm -f /bin/noobie 2>/dev/null || true
sudo rm -f /usr/bin/noobie 2>/dev/null || true
rm -f ~/noobie 2>/dev/null || true

# Remove Go tool symlinks
for tool in subfinder assetfinder httprobe waybackurls katana nuclei gau amass; do
    sudo rm -f "/usr/local/bin/$tool" 2>/dev/null || true
done

# Remove Pentest directory
if [ -d "$PENTEST_DIR" ]; then
    echo -e "${CYAN}Removing Pentest directory...${RESET}"
    rm -rf "$PENTEST_DIR"
fi

echo -e "\n${GREEN}✓ Uninstallation complete!${RESET}"
echo -e "\n${YELLOW}To completely remove changes:${RESET}"
echo -e "  1. ${GREEN}Restart your terminal or run: source ~/.bashrc${RESET}"
echo -e "  2. ${GREEN}APT packages installed are still available${RESET}"
echo -e "  3. ${GREEN}Go tools in ~/go/bin/ are still available${RESET}"
echo -e "\n${CYAN}Note: To reinstall, run the installer script again.${RESET}"
EOF

    chmod +x "$UNINSTALLER_PATH"
    echo -e "${GREEN}[✔] Uninstaller created${RESET}"
}

##############################################
#        INSTALLATION COMPLETE - YOUR STYLE
##############################################
show_completion() {
    section "🎉 INSTALLATION COMPLETE - READY FOR ACTION 🎉"

    echo -e "${GREEN}"
cat << "EOF"

    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║     ███╗   ██╗ ██████╗  ██████╗ ██████╗ ██╗███████╗         ║
    ║     ████╗  ██║██╔═══██╗██╔═══██╗██╔══██╗██║██╔════╝         ║
    ║     ██╔██╗ ██║██║   ██║██║   ██║██████╔╝██║█████╗           ║
    ║     ██║╚██╗██║██║   ██║██║   ██║██╔══██╗██║██╔══╝           ║
    ║     ██║ ╚████║╚██████╔╝╚██████╔╝██║  ██║██║███████╗         ║
    ║     ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝         ║
    ║                                                              ║
    ║                P E N T E S T   T O O L K I T                 ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"

    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}📋 INSTALLATION SUMMARY:${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

    # Quick summary
    echo -e "${YELLOW}📁 Installation Directory:${RESET} ${GREEN}$PENTEST_DIR${RESET}"
    echo -e "${YELLOW}🛠️  Tools Installed:${RESET} ${GREEN}$(ls -1 "$TOOLS_DIR" 2>/dev/null | wc -l) tools${RESET}"
    echo -e "${YELLOW}📚 Wordlists:${RESET} ${GREEN}$(find "$WORDLISTS_DIR" -type f 2>/dev/null | wc -l) wordlists${RESET}"
    echo -e "${YELLOW}🐍 Python Environment:${RESET} ${GREEN}$VENV_DIR${RESET}"
    echo -e "${YELLOW}📝 Log File:${RESET} ${GREEN}$LOGFILE${RESET}"

    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}🚀 IMMEDIATE NEXT STEPS (CRITICAL):${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

    echo -e "${RED}🔴 STEP 1 - RELOAD YOUR TERMINAL CONFIG:${RESET}"
    echo -e "   Run this command: ${GREEN}source ~/.bashrc${RESET}"
    echo -e "   Or simply: ${GREEN}close and reopen your terminal${RESET}"
    echo -e "   ${YELLOW}Why? This activates all aliases and PATH settings${RESET}"

    echo -e "\n${RED}🔴 STEP 2 - LAUNCH THE MAIN MENU:${RESET}"
    echo -e "   Type exactly: ${GREEN}noobie${RESET}"
    echo -e "   ${YELLOW}This will bring up the interactive tool selection menu${RESET}"

    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}🎮 HOW TO USE THE NOOBIE MENU:${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

    echo -e "${GREEN}After typing 'noobie', you'll see:${RESET}"
    echo -e "  ${CYAN}1) ${YELLOW}Information Gathering Tools${RESET} (Nmap, subfinder, etc.)"
    echo -e "  ${CYAN}2) ${YELLOW}Web Application Testing${RESET} (SQLMap, Dirsearch, etc.)"
    echo -e "  ${CYAN}3) ${YELLOW}Wireless & Network Tools${RESET} (Aircrack-ng, Responder)"
    echo -e "  ${CYAN}4) ${YELLOW}Password Attacks${RESET} (John, Hashcat, Hydra)"
    echo -e "  ${CYAN}5) ${YELLOW}Exploitation Tools${RESET} (Metasploit, Searchsploit)"
    echo -e "  ${CYAN}6) ${YELLOW}Post-Exploitation${RESET} (LinPEAS, privilege escalation)"
    echo -e "  ${CYAN}7) ${YELLOW}Wordlists & Resources${RESET} (RockYou, SecLists)"
    echo -e "  ${CYAN}8) ${YELLOW}Update All Tools${RESET}"
    echo -e "  ${CYAN}9) ${YELLOW}Quick Aliases${RESET} (see all available tools)"
    echo -e "  ${CYAN}0) ${RED}Exit${RESET}"

    echo -e "\n${YELLOW}📌 Simply type the number and press ENTER to launch any tool!${RESET}"

    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}🛠️  DIRECT TOOL ACCESS (QUICK COMMANDS):${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

    echo -e "${YELLOW}You can also run tools directly without the menu:${RESET}"
    echo -e "  ${GREEN}nmap${RESET} - Network scanning"
    echo -e "  ${GREEN}sqlmap${RESET} - SQL injection testing"
    echo -e "  ${GREEN}msfconsole${RESET} - Metasploit framework"
    echo -e "  ${GREEN}dirsearch${RESET} - Directory brute forcing"
    echo -e "  ${GREEN}subfinder${RESET} - Subdomain enumeration"

    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}📂 IMPORTANT LOCATIONS:${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

    echo -e "${YELLOW}Navigate to these folders:${RESET}"
    echo -e "  ${GREEN}cd ~/Pentest${RESET} - Main pentest directory"
    echo -e "  ${GREEN}cd ~/Pentest/Tools${RESET} - All installed tools"
    echo -e "  ${GREEN}cd ~/Pentest/Wordlists${RESET} - Wordlists (rockyou.txt here!)"
    echo -e "  ${GREEN}cd ~/Pentest/Tools/dirsearch${RESET} - Example: go into specific tool"

    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}⚠️  TROUBLESHOOTING & NOTES:${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

    echo -e "${YELLOW}If 'noobie' command doesn't work:${RESET}"
    echo -e "  1. Run: ${GREEN}source ~/.bashrc${RESET}"
    echo -e "  2. Or run directly: ${GREEN}~/Pentest/Tools/noobie-menu${RESET}"
    echo -e "  3. Check logs: ${GREEN}cat ~/Pentest/noobie-install.log${RESET}"

    echo -e "\n${YELLOW}Some tools may need additional setup:${RESET}"
    echo -e "  • Burp Suite: Download from https://portswigger.net/burp"
    echo -e "  • Custom configurations: Edit tool configs in Tools/ folder"

    echo -e "\n${RED}🔒 LEGAL & ETHICAL REMINDER:${RESET}"
    echo -e "${YELLOW}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                      ⚠️  DISCLAIMER ⚠️                      ║
    ║  Use these tools ONLY on systems you own or have explicit    ║
    ║  written permission to test. Unauthorized access is ILLEGAL. ║
    ║                                                              ║
    ║  Developer has NO legal obligation for your actions.         ║
    ║  You are SOLELY responsible for ethical use.                 ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"

    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}📞 GETTING HELP:${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

    echo -e "${YELLOW}For tool help:${RESET}"
    echo -e "  ${GREEN}toolname --help${RESET} or ${GREEN}toolname -h${RESET}"
    echo -e "  ${GREEN}man toolname${RESET} (for man page if available)"
    echo -e "  Check GitHub repo for each tool"

    echo -e "\n${YELLOW}Example learning commands:${RESET}"
    echo -e "  ${GREEN}nmap --help${RESET}"
    echo -e "  ${GREEN}sqlmap --hh${RESET} (extensive help)"
    echo -e "  ${GREEN}msfconsole -q${RESET} (quiet start)"

    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}🎯 FINAL COMMANDS TO RUN NOW:${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

    echo -e "${RED}"
    echo "  1. source ~/.bashrc"
    echo "  2. noobie"
    echo -e "${RESET}"

    echo -e "${GREEN}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                     🚀 HAPPY HACKING! 🚀                     ║
    ║           (The legal, ethical, authorized kind)              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"

    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${RED}Noobie Installer v2.0 | Developer: Noobie Emci${RESET}"
    echo -e "${RED}Installation completed at: $(date)${RESET}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

##############################################
#                  MAIN EXECUTION
##############################################
clear
echo -e "${CYAN}###################################${RESET}"
echo -e "${CYAN}#  N O O B   I N S T A L L E R    #${RESET}"
echo -e "${CYAN}###################################${RESET}"
echo -e "${YELLOW}Version 2.0 - Enhanced with Go tool symlinks and robust error handling${RESET}\n"
echo -e "${RED}Disclaimer: Use only on systems you own or have permission to test.${RESET}\n"

# Start log
echo "=== Noobie Installer Started ===" > "$LOGFILE"
echo "Date: $(date)" >> "$LOGFILE"
echo "User: $USER" >> "$LOGFILE"

# Main installation flow
fix_apt_repos
install_jq
install_apt_tools
install_wpscan
setup_venv
install_python_libs
install_all_tools
create_aliases
configure_env
create_menu
create_uninstaller
force_noobie_command

# Show completion section
show_completion

# Final log entry
echo "=== Noobie Installer Completed Successfully ===" >> "$LOGFILE"
echo "Completion Time: $(date)" >> "$LOGFILE"
echo "Total tools installed: $(ls -1 "$TOOLS_DIR" 2>/dev/null | wc -l)" >> "$LOGFILE"
