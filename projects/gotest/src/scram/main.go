package main

import (
	"fmt"
	"net/http"
	"log"
	"io"
	"io/ioutil"
	"github.com/couchbase/goutils/scramsha"
	"net/url"
	"strings"
)


func main() {
	doIt()
	fmt.Println("Main: Completed.")
}

func postAudit() *scramsha.Request {
	form := url.Values{}
	form.Add("logPath", "/blah")

	req, err := scramsha.NewRequest("POST",
		"http://localhost:9000/settings/audit",
		strings.NewReader(form.Encode()))
	if err != nil {
		panic("cannot create request")
	}
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")
	return req
}

func doIt() {
	client := &http.Client{}

	//var jsonStr = []byte(`{"bucket":"test","bucketUUID":"0"}`)
	//req, err := http.NewRequest("GET", "http://localhost:9000/settings/web", nil)
	//req, err := http.NewRequest("POST",
	//	"http://localhost:9500/_pre_replicate",
	//	bytes.NewBuffer(jsonStr))
	//req.Header.Set("Content-Type", "application/json")
	req := postAudit()

	log.Println("START")
	res, err := scramsha.DoScramSha(req, "test", "asdasd", client)
	if err != nil {
		panic(err)
	}

	if res.StatusCode != http.StatusOK {
		log.Println("Wrong status code : ", res.StatusCode)
	}

	b, err := readBody(res)
	if err != nil {
		panic(err)
	}
	log.Println("Body : ", string(b[:]))
}

func readBody(res *http.Response) ([]byte, error) {
	defer res.Body.Close()
	return ioutil.ReadAll(io.LimitReader(res.Body, res.ContentLength))
}
