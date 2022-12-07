package main

import (
	"fmt"
	"os"
	"runtime"

	"github.com/containernetworking/plugins/pkg/ns"
)

// https://github.com/containernetworking/plugins/tree/master/pkg/ns

func main() {
	runtime.LockOSThread()

	targetNS, err := ns.GetNS("/proc/3863130/ns/net")
	if err != nil {
		fmt.Fprintf(os.Stderr, "GetNS() failed: %s\n", err)
		os.Exit(1)
	}

	targetNS.Do(func(h))
}
