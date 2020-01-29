package main

import (
	"fmt"
	"os/exec"
	"strings"
	"strconv"
	"os"
	"time"
)

func main() {
	killMemcached()
}

func killMemcached() {
	cmd := exec.Command("ps", "-e")
	out, err := cmd.CombinedOutput()
	if err != nil {
		panic(err)
	}
	lines := strings.Split(string(out), "\n")
	for _, l := range lines {
		if strings.Contains(l, "n_2/config/memcached.json") {
			killProc(l)
		}
	}
}

func killDisksupProcesses() {
	for {
		killDisksupProcesses()
		time.Sleep(time.Second)
	}
}

func doKillDisksupProcesses() {
	cmd := exec.Command("ps", "-e")
	out, err := cmd.CombinedOutput()
	if err != nil {
		panic(err)
	}
	lines := strings.Split(string(out), "\n")
	for _, l := range lines {
		if strings.Contains(l, "disksup") && (!strings.Contains(l, "ns_disksup")) {
			killProc(l)
		}
	}
}

func killProc(l string) {
	runes := []rune(l)
	pid, err := strconv.Atoi(strings.TrimSpace(string(runes[0:5])))
	if err != nil {
		panic(err)
	}
	proc, err := os.FindProcess(pid)
	if err != nil {
		panic(err)
	}
	fmt.Println("Killing ", l)
	proc.Kill()
}
