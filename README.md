# eBPF Process Tracer

This program uses eBPF to trace process creation (fork) and exit events in real-time. It demonstrates the use of eBPF programs attached to kernel tracepoints.

## Prerequisites

### Ubuntu (20.04 or later)

```bash
# Update package list
sudo apt-get update

# Install essential build tools
sudo apt-get install -y \
    clang \
    llvm \
    libelf-dev \
    linux-tools-common \
    linux-tools-generic \
    linux-tools-$(uname -r) \
    libbpf-dev \
    golang

# Verify installations
clang --version
go version
```

### Amazon Linux 2023

```bash
# Update package list
sudo dnf update -y

# Install essential build tools
sudo dnf install -y \
    clang \
    llvm \
    elfutils-libelf-devel \
    bpftool \
    libbpf-devel \
    golang \
    kernel-devel

# Verify installations
clang --version
go version
```

## Building and Running

1. **Generate vmlinux.h** (required for both distributions)
```bash
# Generate kernel header
sudo bpftool btf dump file /sys/kernel/btf/vmlinux format c > bpf-c/vmlinux.h

# If the above fails, try:
sudo bpftool btf dump file /boot/vmlinux-$(uname -r) format c > bpf-c/vmlinux.h
```

2. **Compile the eBPF program**
```bash
clang -O2 -g -Wall -target bpf -c bpf-c/trace.c -o trace_bpfel.o
```

3. **Run the program**
```bash
sudo go run main.go
```

## Troubleshooting

### Common Issues

1. **Missing vmlinux.h**
   ```
   fatal error: 'vmlinux.h' file not found
   ```
   Solution: Generate vmlinux.h as shown in step 1 above.

2. **Missing bpf_helpers.h**
   ```
   fatal error: 'bpf/bpf_helpers.h' file not found
   ```
   Solution:
   - Ubuntu: `sudo apt-get install -y libbpf-dev`
   - Amazon Linux: `sudo dnf install -y libbpf-devel`

3. **Permission Denied**
   ```
   Error: permission denied
   ```
   Solution: Run the program with sudo privileges.

4. **BTF Error**
   ```
   Error loading BTF
   ```
   Solution: Make sure your kernel is built with BTF support:
   ```bash
   # Check if BTF is available
   ls -l /sys/kernel/btf/vmlinux
   ```

5. **Kernel Headers Missing**
   ```
   Error: could not open kernel header file
   ```
   Solution:
   - Ubuntu: `sudo apt-get install linux-headers-$(uname -r)`
   - Amazon Linux: `sudo dnf install kernel-devel`

### Verifying System Requirements

1. **Check Kernel Version**
```bash
uname -r
```
Ensure you're running a kernel version >= 5.8 for best compatibility.

2. **Check BTF Support**
```bash
# Should show enabled
cat /boot/config-$(uname -r) | grep CONFIG_DEBUG_INFO_BTF
```

3. **Check BPF Subsystem**
```bash
# Should show enabled
cat /boot/config-$(uname -r) | grep CONFIG_BPF
```

### Program Output

When running successfully, you should see output like:
```
Listening for process events...
[FORK] PID: 1234 PPID: 1 COMM: bash
[EXIT] PID: 1234 PPID: 1 COMM: bash
```

### Debugging Tips

1. **Enable Debug Output**
```bash
# Set environment variable before running
sudo LIBBPF_DEBUG=1 go run main.go
```

2. **Check System Logs**
```bash
# View kernel messages
sudo dmesg | tail

# View system logs
sudo journalctl -f
```

3. **Verify eBPF System Settings**
```bash
# Check eBPF settings
sysctl kernel.unprivileged_bpf_disabled
sysctl kernel.bpf_stats_enabled
```

4. **Check Available Tracepoints**
```bash
# List available tracepoints
sudo ls /sys/kernel/debug/tracing/events/sched/
```

## Program Details

This program uses:
- eBPF tracepoints for process events
- Ring buffer for event communication
- Go with libbpf for userspace interaction

The eBPF program attaches to:
- `sched:sched_process_fork`
- `sched:sched_process_exit`

## License

MIT License 