# eBPF Process Monitor

This program uses eBPF to monitor process creation (fork) and exit events on a Linux system. It attaches to kernel tracepoints and reports process events in real-time.

## Prerequisites

The following packages need to be installed on your system:

```bash
# For Amazon Linux 2023
sudo dnf install -y clang llvm kernel-devel bpftool libbpf-devel golang
```

## Building the Program

1. First, generate the vmlinux header file:
```bash
sudo bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
```

2. Install Go dependencies:
```bash
go mod init ebpf-example  # Only if go.mod doesn't exist
go get github.com/cilium/ebpf
```

3. Generate eBPF code:
```bash
mkdir -p bpf-c
GOPACKAGE=main bpf2go -cc clang -cflags "-O2 -g -Wall" Trace bpf-c/trace.c -- -I/usr/include/bpf -I.
```

4. Build the program:
```bash
go build -o trace
```

## Running the Program

Since the program needs to attach to kernel tracepoints, it requires root privileges:

```bash
sudo ./trace
```

The program will start monitoring process events and display them in the following format:
```
[FORK] PID: <pid> PPID: <parent_pid> COMM: <command_name>
[EXIT] PID: <pid> PPID: <parent_pid> COMM: <command_name>
```

Press Ctrl+C to stop monitoring.

## Program Structure

- `main.go`: The main Go program that loads and manages the eBPF programs
- `bpf-c/trace.c`: The eBPF C code that implements the tracepoint handlers
- `trace_bpfel.o`: Generated eBPF object file
- `trace_bpfel.go`: Generated Go code for loading the eBPF program

## Requirements

- Linux kernel 5.x or later
- Root privileges (for attaching to tracepoints)
- Go 1.19 or later
- Clang/LLVM for compiling eBPF programs 