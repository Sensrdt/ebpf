// main.go
package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"os"
	"os/signal"

	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/ringbuf"
)

type event struct {
	Pid  uint32
	Ppid uint32
	Comm [16]byte
	Type uint8
	_    [3]byte // padding
}

func main() {
	objs := struct {
		HandleFork *ebpf.Program `ebpf:"handle_fork"`
		HandleExit *ebpf.Program `ebpf:"handle_exit"`
		Events     *ebpf.Map     `ebpf:"events"`
	}{}

	spec, err := ebpf.LoadCollectionSpec("./trace_bpfel.o")
	if err != nil {
		panic(err)
	}
	if err := spec.LoadAndAssign(&objs, nil); err != nil {
		panic(err)
	}
	defer objs.HandleFork.Close()
	defer objs.HandleExit.Close()

	// Attach to tracepoints
	lfork, err := link.Tracepoint("sched", "sched_process_fork", objs.HandleFork, nil)
	if err != nil {
		panic(err)
	}
	lexit, err := link.Tracepoint("sched", "sched_process_exit", objs.HandleExit, nil)
	if err != nil {
		panic(err)
	}
	defer lfork.Close()
	defer lexit.Close()

	rb, err := ringbuf.NewReader(objs.Events)
	if err != nil {
		panic(err)
	}
	defer rb.Close()

	fmt.Println("Listening for process events...")

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, os.Interrupt)

	go func() {
		for {
			record, err := rb.Read()
			if err != nil {
				continue
			}

			var e event
			err = binary.Read(bytes.NewBuffer(record.RawSample), binary.LittleEndian, &e)
			if err != nil {
				continue
			}

			action := map[uint8]string{1: "FORK", 2: "EXIT"}[e.Type]
			fmt.Printf("[%s] PID: %d PPID: %d COMM: %s\n", action, e.Pid, e.Ppid, bytes.Trim(e.Comm[:], "\x00"))
		}
	}()

	<-sig
	fmt.Println("Exiting.")
}
