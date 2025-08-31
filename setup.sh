#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Banner
show_banner() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║${WHITE}                🔥 PIPE NETWORK FIRESTARTER 🔥                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║${CYAN}                   One-Click Setup Script                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║${YELLOW}              Automated Installation & Management           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Loading animation
show_loading() {
    local message="$1"
    local duration=${2:-3}
    echo -ne "${CYAN}$message${NC}"
    for i in $(seq 1 $duration); do
        echo -ne "${YELLOW}.${NC}"
        sleep 1
    done
    echo -e " ${GREEN}✓${NC}"
}

# Error handling
handle_error() {
    echo -e "${RED}❌ Error: $1${NC}"
    echo -e "${YELLOW}Please check the logs and try again.${NC}"
    read -p "Press Enter to continue..."
}

# Success message
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Warning message
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Info message
show_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install yt-dlp with multiple fallback methods
install_yt_dlp() {
    if command_exists yt-dlp; then
        show_success "yt-dlp is already installed"
        return 0
    fi
    
    local os_type=$(get_system_info)
    
    # Method 1: Try package manager first (most reliable)
    if [ "$os_type" = "linux" ]; then
        show_info "Trying to install yt-dlp via apt..."
        if sudo apt install -y yt-dlp 2>/dev/null; then
            show_success "yt-dlp installed via apt"
            return 0
        fi
        
        # Method 2: Try pipx (recommended for user applications)
        show_info "Trying to install yt-dlp via pipx..."
        if command_exists pipx; then
            if pipx install yt-dlp 2>/dev/null; then
                show_success "yt-dlp installed via pipx"
                return 0
            fi
        else
            # Install pipx first
            show_info "Installing pipx first..."
            if sudo apt install -y pipx 2>/dev/null; then
                if pipx install yt-dlp 2>/dev/null; then
                    show_success "yt-dlp installed via pipx"
                    return 0
                fi
            fi
        fi
        
        # Method 3: Try pip with virtual environment
        if command_exists python3; then
            show_info "Creating virtual environment for yt-dlp..."
            local venv_path="$HOME/.yt-dlp-venv"
            
            # Ensure python3-full is installed for venv
            sudo apt install -y python3-full python3-venv 2>/dev/null
            
            # Remove existing venv if corrupted
            [ -d "$venv_path" ] && rm -rf "$venv_path"
            
            # Create fresh virtual environment
            if python3 -m venv "$venv_path" 2>/dev/null; then
                show_info "Virtual environment created successfully"
                
                # Install directly using venv pip (no activation needed)
                if "$venv_path/bin/pip" install --upgrade pip >/dev/null 2>&1 && "$venv_path/bin/pip" install yt-dlp >/dev/null 2>&1; then
                    # Create wrapper script
                    mkdir -p "$HOME/.local/bin"
                    cat > "$HOME/.local/bin/yt-dlp" << 'EOF'
#!/bin/bash
VENV_PATH="$HOME/.yt-dlp-venv"
if [ -f "$VENV_PATH/bin/yt-dlp" ]; then
    "$VENV_PATH/bin/yt-dlp" "$@"
else
    echo "yt-dlp virtual environment not found. Please reinstall."
    exit 1
fi
EOF
                    chmod +x "$HOME/.local/bin/yt-dlp"
                    
                    # Add to PATH if not already there
                    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                        export PATH="$HOME/.local/bin:$PATH"
                        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" 2>/dev/null || true
                    fi
                    
                    show_success "yt-dlp installed in virtual environment"
                    return 0
                else
                    show_warning "Failed to install yt-dlp in virtual environment"
                fi
            else
                show_warning "Failed to create virtual environment"
            fi
        fi
        
        # Method 4: Direct download (last resort)
        show_info "Trying direct download of yt-dlp..."
        mkdir -p "$HOME/.local/bin"
        if curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$HOME/.local/bin/yt-dlp" 2>/dev/null; then
            chmod +x "$HOME/.local/bin/yt-dlp"
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                export PATH="$HOME/.local/bin:$PATH"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" 2>/dev/null || true
            fi
            show_success "yt-dlp downloaded directly"
            return 0
        fi
        
    elif [ "$os_type" = "mac" ]; then
        # macOS installation
        if command_exists brew; then
            if brew install yt-dlp 2>/dev/null; then
                show_success "yt-dlp installed via Homebrew"
                return 0
            fi
        fi
    fi
    
    show_warning "All yt-dlp installation methods failed"
    return 1
}
get_system_info() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "mac"
    else
        echo "unknown"
    fi
}

# Install dependencies
install_dependencies() {
    show_info "Installing system dependencies..."
    
    local os_type=$(get_system_info)
    
    if [ "$os_type" = "linux" ]; then
        show_loading "Updating package list" 2
        sudo apt update && sudo apt upgrade -y || { handle_error "Failed to update packages"; return 1; }
        
        show_loading "Installing required packages" 5
        sudo apt install curl iptables build-essential git wget lz4 jq make gcc postgresql-client nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev tar clang bsdmainutils ncdu unzip libleveldb-dev libclang-dev ninja-build python3-pip python3-venv python3-full pipx -y || { handle_error "Failed to install packages"; return 1; }
    elif [ "$os_type" = "mac" ]; then
        show_info "Installing Homebrew if not present..."
        if ! command_exists brew; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { handle_error "Failed to install Homebrew"; return 1; }
        fi
        
        show_loading "Installing required packages via Homebrew" 3
        brew install curl git wget jq make gcc nano automake autoconf tmux htop pkg-config openssl tar clang python3 || { handle_error "Failed to install packages"; return 1; }
    fi
    
    # Install yt-dlp for YouTube downloads
    show_loading "Installing yt-dlp for YouTube downloads" 2
    install_yt_dlp
    
    show_success "Dependencies installed successfully!"
}

# Install Rust
install_rust() {
    show_info "Installing Rust..."
    
    if command_exists rustc; then
        show_warning "Rust is already installed"
        rustc --version
        cargo --version
        return 0
    fi
    
    show_loading "Downloading and installing Rust" 3
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || { handle_error "Failed to install Rust"; return 1; }
    
    source $HOME/.cargo/env || { handle_error "Failed to source Rust environment"; return 1; }
    
    show_success "Rust installed successfully!"
    echo -e "${CYAN}Rust version: $(rustc --version)${NC}"
    echo -e "${CYAN}Cargo version: $(cargo --version)${NC}"
}

# Install Pipe CLI
install_pipe_cli() {
    show_info "Installing Pipe CLI..."
    
    if [ -d "pipe" ]; then
        show_warning "Pipe directory already exists, updating..."
        cd pipe
        git pull || show_warning "Failed to update repository"
    else
        show_loading "Cloning Pipe repository" 2
        git clone https://github.com/PipeNetwork/pipe.git || { handle_error "Failed to clone repository"; return 1; }
        cd pipe
    fi
    
    show_loading "Building Pipe CLI" 5
    source $HOME/.cargo/env
    cargo install --path . || { handle_error "Failed to install Pipe CLI"; return 1; }
    
    show_success "Pipe CLI installed successfully!"
    
    # Verify installation
    if command_exists pipe; then
        echo -e "${GREEN}✅ Pipe CLI verification:${NC}"
        pipe -h | head -5
    else
        handle_error "Pipe CLI installation verification failed"
        return 1
    fi
}

# Setup user
setup_user() {
    show_info "Setting up Pipe user..."
    
    echo -e "${YELLOW}Enter your desired username:${NC}"
    read -p "Username: " username
    
    if [ -z "$username" ]; then
        handle_error "Username cannot be empty"
        return 1
    fi
    
    show_loading "Creating user: $username" 2
    pipe new-user "$username" || { handle_error "Failed to create user"; return 1; }
    
    echo -e "${YELLOW}Set up your password:${NC}"
    pipe set-password || { handle_error "Failed to set password"; return 1; }
    
    show_success "User setup completed!"
    show_info "Your credentials are saved in ~/.pipe-cli.json"
    
    # Apply referral code
    echo -e "${YELLOW}Applying referral code...${NC}"
    pipe referral apply MAYANKGG-D4CJ || show_warning "Failed to apply referral code"
    
    show_success "Setup completed! Please save your Solana Pubkey from the output above."
}

# Show credentials
show_credentials() {
    # Check if Pipe CLI is installed first
    check_pipe_installation || return 1
    
    show_banner
    echo -e "${CYAN}📋 Your Pipe CLI Credentials${NC}"
    echo "═══════════════════════════════════════"
    
    if [ -f ~/.pipe-cli.json ]; then
        echo -e "${GREEN}Credentials file found at: ~/.pipe-cli.json${NC}"
        echo
        cat ~/.pipe-cli.json | jq . 2>/dev/null || cat ~/.pipe-cli.json
    else
        show_warning "Credentials file not found. Please run the installation first."
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Show referral info
show_referral_info() {
    # Check if Pipe CLI is installed first
    check_pipe_installation || return 1
    
    show_banner
    echo -e "${CYAN}🎁 Referral Information${NC}"
    echo "═══════════════════════════════════════"
    
    if ! command_exists pipe; then
        show_warning "Pipe CLI not installed. Please install first."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${YELLOW}Your referral stats:${NC}"
    pipe referral show || show_warning "Failed to fetch referral stats"
    
    echo
    echo -e "${YELLOW}Generate new referral code:${NC}"
    pipe referral generate || show_warning "Failed to generate referral code"
    
    echo
    read -p "Press Enter to continue..."
}

# Check if Pipe CLI is installed
check_pipe_installation() {
    if ! command_exists pipe; then
        show_banner
        echo -e "${RED}⚠️  Pipe Firestarter Node Not Installed!${NC}"
        echo "═══════════════════════════════════════════════════════════"
        echo
        echo -e "${YELLOW}You need to install the Pipe Firestarter Node first before using this feature.${NC}"
        echo
        echo -e "${CYAN}What would you like to do?${NC}"
        echo -e "${WHITE}1.${NC} 🛠️  Install Pipe Firestarter Node Now"
        echo -e "${WHITE}2.${NC} 🔙 Return to Main Menu"
        echo -e "${WHITE}3.${NC} ❌ Exit"
        echo
        read -p "Choice (1-3): " install_choice
        
        case $install_choice in
            1)
                install_pipe_firestarter
                return 0
                ;;
            2)
                return 1
                ;;
            3)
                graceful_exit
                ;;
            *)
                show_warning "Invalid choice. Returning to main menu..."
                sleep 2
                return 1
                ;;
        esac
    fi
    return 0
}
get_file_size() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        if command_exists numfmt; then
            ls -l "$file_path" | awk '{print $5}' | numfmt --to=iec --suffix=B
        else
            ls -lh "$file_path" | awk '{print $5}'
        fi
    else
        echo "File not found"
    fi
}

# Download YouTube video
download_youtube() {
    # Check if Pipe CLI is installed first
    check_pipe_installation || return 1
    
    show_banner
    echo -e "${CYAN}📺 YouTube Video Download${NC}"
    echo "═══════════════════════════════════════"
    
    # Ensure yt-dlp is available - use simple direct method
    if ! command_exists yt-dlp; then
        show_warning "yt-dlp not found. Installing via multiple methods..."
        
        # Try apt first (most reliable on Ubuntu/Debian)
        if sudo apt install -y yt-dlp 2>/dev/null; then
            show_success "yt-dlp installed via apt"
        # Try pipx next
        elif command_exists pipx && pipx install yt-dlp 2>/dev/null; then
            show_success "yt-dlp installed via pipx"
        # Create virtual environment manually
        elif command_exists python3; then
            show_info "Creating virtual environment for yt-dlp..."
            
            # Install required packages
            sudo apt install -y python3-full python3-venv 2>/dev/null
            
            # Create venv
            local venv_path="$HOME/.yt-dlp-venv"
            rm -rf "$venv_path" 2>/dev/null
            
            if python3 -m venv "$venv_path"; then
                # Install using venv pip directly (no shell sourcing)
                if "$venv_path/bin/pip" install --upgrade pip && "$venv_path/bin/pip" install yt-dlp; then
                    # Create wrapper
                    mkdir -p "$HOME/.local/bin"
                    echo '#!/bin/bash' > "$HOME/.local/bin/yt-dlp"
                    echo '"$HOME/.yt-dlp-venv/bin/yt-dlp" "$@"' >> "$HOME/.local/bin/yt-dlp"
                    chmod +x "$HOME/.local/bin/yt-dlp"
                    export PATH="$HOME/.local/bin:$PATH"
                    show_success "yt-dlp installed in virtual environment"
                else
                    show_warning "Virtual environment installation failed"
                fi
            else
                show_warning "Could not create virtual environment"
            fi
        # Direct download as last resort
        elif curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$HOME/.local/bin/yt-dlp" 2>/dev/null; then
            chmod +x "$HOME/.local/bin/yt-dlp"
            export PATH="$HOME/.local/bin:$PATH"
            show_success "yt-dlp downloaded directly"
        else
            show_warning "All installation methods failed"
            echo -e "${YELLOW}Manual installation required:${NC}"
            echo -e "${CYAN}sudo apt install yt-dlp${NC}"
            echo -e "${CYAN}OR: pipx install yt-dlp${NC}"
            echo -e "${CYAN}OR: python3 -m venv ~/.yt-dlp-venv && ~/.yt-dlp-venv/bin/pip install yt-dlp${NC}"
            read -p "Press Enter to continue..."
            return 1
        fi
        
        # Check if installation worked
        if ! command_exists yt-dlp; then
            # Try to find it in common locations
            if [ -f "$HOME/.local/bin/yt-dlp" ]; then
                export PATH="$HOME/.local/bin:$PATH"
            elif [ -f "$HOME/.yt-dlp-venv/bin/yt-dlp" ]; then
                export PATH="$HOME/.yt-dlp-venv/bin:$PATH"
            fi
        fi
        
        # Final check
        if ! command_exists yt-dlp; then
            show_warning "yt-dlp not found in PATH. You may need to restart terminal."
            return 1
        fi
    fi
    
    echo -e "${YELLOW}Enter YouTube URL:${NC}"
    read -p "URL: " youtube_url
    
    if [ -z "$youtube_url" ]; then
        handle_error "URL cannot be empty"
        return 1
    fi
    
    echo -e "${YELLOW}Select format:${NC}"
    echo "1. MP4 (Video)"
    echo "2. MP3 (Audio only)"
    read -p "Choice (1-2): " format_choice
    
    echo -e "${YELLOW}Enter filename (without extension):${NC}"
    read -p "Filename: " filename
    
    if [ -z "$filename" ]; then
        handle_error "Filename cannot be empty"
        return 1
    fi
    
    # Clean filename (remove special characters)
    filename=$(echo "$filename" | sed 's/[^a-zA-Z0-9._-]/_/g')
    
    local output_file
    local yt_format
    local extra_args=""
    
    case $format_choice in
        1)
            output_file="$filename.mp4"
            yt_format="best[height<=720]/best[ext=mp4]/best"
            extra_args="--format-sort res:720"
            ;;
        2)
            output_file="$filename.mp3"
            yt_format="bestaudio[ext=m4a]/bestaudio/best[ext=mp4]"
            extra_args="--extract-audio --audio-format mp3"
            ;;
        *)
            handle_error "Invalid choice"
            return 1
            ;;
    esac
    
    show_loading "Downloading video" 3
    echo -e "${CYAN}Attempting download with bot prevention...${NC}"
    
    # Try multiple download strategies to avoid bot detection
    local download_success=false
    
    # Strategy 1: Use user agent and bypass age gate
    echo -e "${BLUE}🤖 Trying with user agent bypass...${NC}"
    if yt-dlp \
        --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
        --extractor-args "youtube:skip=dash,hls" \
        --no-warnings \
        -f "$yt_format" $extra_args \
        -o "$output_file" \
        "$youtube_url" 2>/dev/null; then
        download_success=true
    fi
    
    # Strategy 2: Try with different extractor args
    if [ "$download_success" = false ]; then
        echo -e "${BLUE}🔄 Trying alternative method...${NC}"
        if yt-dlp \
            --extractor-args "youtube:player_client=web,web_creator" \
            --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
            --no-warnings \
            -f "$yt_format" $extra_args \
            -o "$output_file" \
            "$youtube_url" 2>/dev/null; then
            download_success=true
        fi
    fi
    
    # Strategy 3: Try mobile client
    if [ "$download_success" = false ]; then
        echo -e "${BLUE}📱 Trying mobile client...${NC}"
        if yt-dlp \
            --extractor-args "youtube:player_client=mweb" \
            --no-warnings \
            -f "$yt_format" $extra_args \
            -o "$output_file" \
            "$youtube_url" 2>/dev/null; then
            download_success=true
        fi
    fi
    
    # Strategy 4: Basic download (last resort)
    if [ "$download_success" = false ]; then
        echo -e "${BLUE}🎯 Trying basic download...${NC}"
        if yt-dlp \
            --no-warnings \
            -f "worst[ext=mp4]/worst" \
            -o "$output_file" \
            "$youtube_url" 2>/dev/null; then
            download_success=true
            show_warning "Downloaded in lower quality due to restrictions"
        fi
    fi
    
    if [ "$download_success" = false ]; then
        echo -e "${RED}❌ All download methods failed${NC}"
        echo -e "${YELLOW}This could be due to:${NC}"
        echo "• YouTube bot detection"
        echo "• Video restrictions (private/age-gated)"
        echo "• Network issues"
        echo "• Video no longer available"
        echo
        echo -e "${CYAN}💡 Troubleshooting options:${NC}"
        echo "1. Try a different video URL"
        echo "2. Check if video is public and available"
        echo "3. Try again later (YouTube may be blocking requests temporarily)"
        echo "4. Use browser to download manually, then upload via option 3"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    if [ -f "$output_file" ]; then
        local file_size=$(get_file_size "$output_file")
        show_success "Download completed!"
        echo -e "${CYAN}File: $output_file${NC}"
        echo -e "${CYAN}Size: $file_size${NC}"
        
        echo -e "${YELLOW}Do you want to upload this file to Pipe Network? (y/n):${NC}"
        read -p "Upload: " upload_choice
        
        if [ "$upload_choice" = "y" ] || [ "$upload_choice" = "Y" ]; then
            upload_file_to_pipe "$(pwd)/$output_file" "$filename"
        fi
    else
        handle_error "Download failed - file not found"
    fi
    
    read -p "Press Enter to continue..."
}

# Upload file to Pipe
upload_file_to_pipe() {
    local file_path="$1"
    local file_name="$2"
    
    # Only check installation if called directly (not from other functions)
    if [ -z "$1" ] && [ -z "$2" ]; then
        check_pipe_installation || return 1
    fi
    
    if [ -z "$file_path" ] || [ -z "$file_name" ]; then
        show_banner
        echo -e "${CYAN}📤 Upload File to Pipe Network${NC}"
        echo "═══════════════════════════════════════"
        
        echo -e "${YELLOW}Enter file path:${NC}"
        read -p "File path: " file_path
        
        if [ -z "$file_path" ]; then
            handle_error "File path cannot be empty"
            return 1
        fi
        
        # Expand tilde to home directory
        file_path="${file_path/#\~/$HOME}"
        
        if [ ! -f "$file_path" ]; then
            handle_error "File does not exist: $file_path"
            return 1
        fi
        
        # Get filename from path
        local basename=$(basename "$file_path")
        local extension="${basename##*.}"
        local name_without_ext="${basename%.*}"
        
        echo -e "${YELLOW}Current filename: $basename${NC}"
        echo -e "${YELLOW}Enter new name (without extension, press Enter to keep current):${NC}"
        read -p "New name: " new_name
        
        if [ -z "$new_name" ]; then
            file_name="$basename"
        else
            file_name="$new_name.$extension"
        fi
    fi
    
    if ! command_exists pipe; then
        handle_error "Pipe CLI not installed"
        return 1
    fi
    
    local file_size=$(get_file_size "$file_path")
    echo -e "${CYAN}File: $file_path${NC}"
    echo -e "${CYAN}Upload name: $file_name${NC}"
    echo -e "${CYAN}Size: $file_size${NC}"
    
    show_warning "Do not upload confidential files (wallet keys, personal documents)"
    echo -e "${YELLOW}Continue with upload? (y/n):${NC}"
    read -p "Confirm: " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        show_info "Upload cancelled"
        return 0
    fi
    
    show_loading "Uploading file to Pipe Network" 5
    pipe upload-file "$file_path" "$file_name" || { handle_error "Upload failed"; return 1; }
    
    show_success "File uploaded successfully!"
    
    echo -e "${YELLOW}Create public link for this file? (y/n):${NC}"
    read -p "Create link: " create_link
    
    if [ "$create_link" = "y" ] || [ "$create_link" = "Y" ]; then
        show_loading "Creating public link" 2
        pipe create-public-link "$file_name" || show_warning "Failed to create public link"
    fi
    
    if [ -z "$1" ]; then
        read -p "Press Enter to continue..."
    fi
}

# Swap SOL for PIPE
swap_sol_for_pipe() {
    # Check if Pipe CLI is installed first
    check_pipe_installation || return 1
    
    show_banner
    echo -e "${CYAN}💱 Swap SOL for PIPE${NC}"
    echo "═══════════════════════════════════════"
    
    if ! command_exists pipe; then
        show_warning "Pipe CLI not installed. Please install first."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    show_info "Get SOL Devnet tokens from: https://faucet.solana.com/"
    echo
    echo -e "${YELLOW}Enter amount of SOL to swap (minimum 1):${NC}"
    read -p "Amount: " sol_amount
    
    if [ -z "$sol_amount" ]; then
        handle_error "Amount cannot be empty"
        return 1
    fi
    
    # Basic validation for numeric input
    if ! [[ "$sol_amount" =~ ^[0-9]*\.?[0-9]+$ ]]; then
        handle_error "Please enter a valid number"
        return 1
    fi
    
    show_loading "Swapping $sol_amount SOL for PIPE" 3
    pipe swap-sol-for-pipe "$sol_amount" || { handle_error "Swap failed"; return 1; }
    
    show_success "Swap completed successfully!"
    read -p "Press Enter to continue..."
}

# Show uploaded files info
show_uploaded_files() {
    # Check if Pipe CLI is installed first
    check_pipe_installation || return 1
    
    show_banner
    echo -e "${CYAN}📁 Uploaded Files Information${NC}"
    echo "═══════════════════════════════════════"
    
    if ! command_exists pipe; then
        show_warning "Pipe CLI not installed. Please install first."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Note: This is a placeholder as the actual pipe CLI might not have a list files command
    # You might need to keep track of uploaded files locally
    show_info "Checking for uploaded files..."
    
    # Check if there's a local log of uploaded files
    local upload_log="$HOME/.pipe-uploads.log"
    
    if [ -f "$upload_log" ]; then
        echo -e "${GREEN}Previously uploaded files:${NC}"
        cat "$upload_log"
    else
        show_info "No upload history found locally."
        echo "Files are tracked in Pipe Network. Use 'pipe' commands to manage them."
    fi
    
    echo
    echo -e "${YELLOW}Available Pipe CLI commands:${NC}"
    pipe -h | grep -E "(upload|create-public|list)" || echo "Use 'pipe -h' to see all available commands"
    
    echo
    read -p "Press Enter to continue..."
}

# Full installation process
install_pipe_firestarter() {
    show_banner
    echo -e "${CYAN}🚀 Starting Pipe Firestarter Node Installation${NC}"
    echo "═══════════════════════════════════════════════════════════"
    
    echo -e "${YELLOW}This will install:${NC}"
    echo "• System dependencies"
    echo "• Rust programming language"
    echo "• Pipe CLI"
    echo "• YouTube download capability"
    echo "• User setup with referral code"
    echo
    
    echo -e "${YELLOW}Continue with installation? (y/n):${NC}"
    read -p "Continue: " continue_install
    
    if [ "$continue_install" != "y" ] && [ "$continue_install" != "Y" ]; then
        show_info "Installation cancelled"
        return 0
    fi
    
    # Step 1: Install dependencies
    install_dependencies || return 1
    echo
    
    # Step 2: Install Rust
    install_rust || return 1
    echo
    
    # Step 3: Install Pipe CLI
    install_pipe_cli || return 1
    echo
    
    # Step 4: Setup user
    setup_user || return 1
    echo
    
    show_success "🎉 Pipe Firestarter Node installation completed successfully!"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Get SOL Devnet tokens from: https://faucet.solana.com/"
    echo "2. Swap SOL for PIPE tokens"
    echo "3. Upload files to earn rewards"
    echo "4. Share your referral code to earn more PIPE"
    echo
    echo -e "${GREEN}Your credentials are saved in: ~/.pipe-cli.json${NC}"
    echo
    read -p "Press Enter to return to main menu..."
}

# Graceful exit
graceful_exit() {
    show_banner
    echo -e "${CYAN}Thank you for using Pipe Network Firestarter Setup!${NC}"
    echo
    echo -e "${YELLOW}Useful links:${NC}"
    echo -e "${BLUE}• Pipe Network: https://pipe.network${NC}"
    echo -e "${BLUE}• Documentation: https://docs.pipe.network${NC}"
    echo -e "${BLUE}• SOL Devnet Faucet: https://faucet.solana.com/${NC}"
    echo
    echo -e "${GREEN}Happy building with Pipe Network! 🔥${NC}"
    echo
    exit 0
}

# Main menu
show_main_menu() {
    show_banner
    echo -e "${CYAN}🔥 PIPE NETWORK FIRESTARTER - MAIN MENU${NC}"
    echo "═══════════════════════════════════════════════════════════"
    echo
    echo -e "${WHITE}1.${NC} 🛠️  Install Pipe Firestarter Node"
    echo -e "${WHITE}2.${NC} 📺 Download from YouTube & Upload"
    echo -e "${WHITE}3.${NC} 📤 Upload File Manually"
    echo -e "${WHITE}4.${NC} 💱 Swap SOL for PIPE"
    echo -e "${WHITE}5.${NC} 📋 Show Credentials"
    echo -e "${WHITE}6.${NC} 🎁 Referral Information"
    echo -e "${WHITE}7.${NC} 📁 Show Uploaded Files"
    echo -e "${WHITE}8.${NC} ❌ Exit"
    echo
    echo -e "${YELLOW}Select an option (1-8):${NC}"
}

# Main script execution
main() {
    # Trap CTRL+C for graceful exit
    trap graceful_exit SIGINT
    
    # Create upload log file if it doesn't exist
    touch "$HOME/.pipe-uploads.log" 2>/dev/null
    
    while true; do
        show_main_menu
        read -p "Choice: " choice
        
        case $choice in
            1)
                install_pipe_firestarter
                ;;
            2)
                download_youtube
                ;;
            3)
                upload_file_to_pipe
                ;;
            4)
                swap_sol_for_pipe
                ;;
            5)
                show_credentials
                ;;
            6)
                show_referral_info
                ;;
            7)
                show_uploaded_files
                ;;
            8)
                graceful_exit
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-8.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
