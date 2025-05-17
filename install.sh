#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command exists
check_command() {
    local cmd=$1
    local alt_cmd=$2

    # If an alternative command is provided, check that too
    if [ -n "$alt_cmd" ] && command -v $alt_cmd &> /dev/null; then
        echo -e "${GREEN}✓${NC} $cmd found"
        return 0
    fi

    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is not installed${NC}"
        return 1
    fi
    echo -e "${GREEN}✓${NC} $cmd found"
    return 0
}

# Function to check system requirements
check_requirements() {
    echo "Checking system requirements..."
    
    # Check Linux kernel version (minimum 5.8)
    kernel_version=$(uname -r | cut -d. -f1,2)
    if (( $(echo "$kernel_version < 5.8" | bc -l) )); then
        echo -e "${RED}Error: Kernel version $kernel_version is not supported. Minimum required is 5.8${NC}"
        return 1
    fi
    echo -e "${GREEN}✓${NC} Kernel version $kernel_version supported"

    # Check for required tools
    check_command "clang" || return 1
    check_command "llvm" "llvm-config" || return 1
    check_command "bpftool" || return 1

    return 0
}

# Function to install the agent
install_agent() {
    echo "Installing eBPF process tracer agent..."

    # Create installation directory
    INSTALL_DIR="/opt/ebpf-tracer"
    sudo mkdir -p $INSTALL_DIR
    
    # Copy binary and eBPF object file
    sudo cp trace_bpfel.o $INSTALL_DIR/
    sudo cp ebpf-tracer $INSTALL_DIR/
    
    # Create systemd service
    cat << EOF | sudo tee /etc/systemd/system/ebpf-tracer.service > /dev/null
[Unit]
Description=eBPF Process Tracer
After=network.target

[Service]
Type=simple
ExecStart=/opt/ebpf-tracer/ebpf-tracer
Restart=always
RestartSec=5
WorkingDirectory=/opt/ebpf-tracer

[Install]
WantedBy=multi-user.target
EOF

    # Set permissions
    sudo chmod 755 $INSTALL_DIR/ebpf-tracer
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable ebpf-tracer
    
    echo -e "${GREEN}✓${NC} Installation completed"
}

# Main installation process
echo "eBPF Process Tracer Installer"
echo "============================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Check system requirements
if ! check_requirements; then
    exit 1
fi

# Install the agent
install_agent

# Start the service
echo "Starting eBPF tracer service..."
sudo systemctl start ebpf-tracer

# Check service status
if systemctl is-active --quiet ebpf-tracer; then
    echo -e "${GREEN}✓${NC} eBPF tracer service is running"
    echo -e "\nInstallation successful! The agent will start automatically on system boot."
    echo "Use these commands to manage the service:"
    echo "  sudo systemctl status ebpf-tracer  # Check status"
    echo "  sudo systemctl stop ebpf-tracer    # Stop the agent"
    echo "  sudo systemctl start ebpf-tracer   # Start the agent"
    echo "  sudo journalctl -u ebpf-tracer     # View logs"
else
    echo -e "${RED}Error: Service failed to start. Check logs with: journalctl -u ebpf-tracer${NC}"
    exit 1
fi 