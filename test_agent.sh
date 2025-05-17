#!/bin/bash

# Function to perform a task and exit
perform_task() {
    local task_id=$1
    echo "[Task $task_id] Process started (PID: $$)"
    # Do some work
    sleep 0.5
    # Exit with a random status
    exit $((RANDOM % 2))
}

# Function to spawn processes periodically
spawn_processes() {
    local count=$1
    for ((i=1; i<=count; i++)); do
        (perform_task $i) &
    done
    wait
}

# Trap Ctrl+C to exit gracefully
trap 'echo -e "\nShutting down..."; exit 0' SIGINT

echo "Starting continuous fork/exit operations..."
echo "Press Ctrl+C to stop"

counter=0
while true; do
    # Spawn 3 processes every second
    counter=$((counter + 1))
    echo -e "\n=== Iteration $counter ==="
    
    # Spawn some short-lived processes
    (echo "Quick process $$"; sleep 0.1) &
    
    # Spawn some processes that do work
    spawn_processes 3
    
    # Run some common commands to trigger exec
    (date > /dev/null) &
    (ps aux | head -n 1 > /dev/null) &
    
    # Create a small process tree
    (
        echo "Parent $$"
        (
            echo "Child $$"
            (echo "Grandchild $$"; sleep 0.2) &
        ) &
    ) &
    
    # Wait a bit before next iteration
    sleep 1
done 