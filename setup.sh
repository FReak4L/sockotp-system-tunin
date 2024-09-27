#!/bin/bash

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root. Please use sudo."
        exit 1
    fi
}

# Function to install required packages
install_packages() {
    apt update
    apt install -y git make gcc iperf3 iproute2 jq
}

# Function to clone the repository
clone_repo() {
    git clone https://github.com/FReak4L/sockotp-system-tunin.git
    cd sockotp-system-tunin
}

# Function to compile C programs
compile_programs() {
    make
}

# Main execution
main() {
    check_root
    
    echo "Installing required packages..."
    install_packages
    
    echo "Cloning the repository..."
    clone_repo
    
    echo "Compiling C programs..."
    compile_programs
    
    echo "Running the main script..."
    bash src/main.sh
}

# Run the main function
main
