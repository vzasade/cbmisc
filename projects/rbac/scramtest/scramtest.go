package main

import (
	"fmt"
	"crypto/sha256"
	"net/http"
	"encoding/base64"
)

func main() {
	username := "Administrator"
	password := "asdasd"
	url := "http://127.0.0.1:9000/settings/audit"

	scramMgr := newScramClient(sha256.New, username, password)
	scramMgr.Step(nil)
	auth := "SCRAM-SHA-256 data=" + base64.StdEncoding.EncodeToString(scramMgr.Out())

	client := &http.Client{}
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Add("Authorization", auth)
	resp, _ := client.Do(req)

	fmt.Println(resp.StatusCode)
}
