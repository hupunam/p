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

# Get system info
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
        sudo apt install curl iptables build-essential git wget lz4 jq make gcc postgresql-client nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev tar clang bsdmainutils ncdu unzip libleveldb-dev libclang-dev ninja-build python3-pip -y || { handle_error "Failed to install packages"; return 1; }
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
    if command_exists pip3; then
        pip3 install yt-dlp || show_warning "Failed to install yt-dlp, YouTube download won't work"
    fi
    
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

# Get file size in human readable format
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
    show_banner
    echo -e "${CYAN}📺 YouTube Video Download${NC}"
    echo "═══════════════════════════════════════"
    
    if ! command_exists yt-dlp; then
        show_warning "yt-dlp not installed. Installing now..."
        pip3 install yt-dlp || { handle_error "Failed to install yt-dlp"; return 1; }
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
    
    local output_file
    local yt_format
    
    case $format_choice in
        1)
            output_file="$filename.mp4"
            yt_format="best[ext=mp4]"
            ;;
        2)
            output_file="$filename.mp3"
            yt_format="bestaudio[ext=m4a]/best[ext=mp4]"
            ;;
        *)
            handle_error "Invalid choice"
            return 1
            ;;
    esac
    
    show_loading "Downloading video" 3
    
    if [ "$format_choice" = "2" ]; then
        yt-dlp -f "$yt_format" --extract-audio --audio-format mp3 -o "$output_file" "$youtube_url" || { handle_error "Download failed"; return 1; }
    else
        yt-dlp -f "$yt_format" -o "$output_file" "$youtube_url" || { handle_error "Download failed"; return 1; }
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
