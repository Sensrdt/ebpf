#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Building eBPF Process Tracer..."

# Step 1: Compile eBPF program
echo "Compiling eBPF program..."
clang -O2 -g -Wall -target bpf -c bpf-c/trace.c -o trace_bpfel.o
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to compile eBPF program${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} eBPF program compiled"

# Step 2: Build Go binary
echo "Building Go binary..."
go build -o ebpf-tracer main.go
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build Go binary${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Go binary built"

# Step 3: Create release package
echo "Creating release package..."
RELEASE_DIR="release"
mkdir -p $RELEASE_DIR

# Copy files to release directory
cp trace_bpfel.o $RELEASE_DIR/
cp ebpf-tracer $RELEASE_DIR/
cp install.sh $RELEASE_DIR/

# Create tarball
tar -czf ebpf-tracer.tar.gz -C $RELEASE_DIR .

echo -e "${GREEN}✓${NC} Release package created: ebpf-tracer.tar.gz"
echo
echo "To deploy to a VM:"
echo "1. Copy ebpf-tracer.tar.gz to the target system"
echo "2. Extract: tar xzf ebpf-tracer.tar.gz"
echo "3. Run: sudo ./install.sh" 