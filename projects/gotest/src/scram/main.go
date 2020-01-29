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
	"time"
	"reflect"
	"github.com/pkg/errors"
)


func main() {
	tr := &http.Transport{
		MaxIdleConns:       10,
	}
	client := &http.Client{Timeout: 20 * time.Second, Transport: tr}

	doIt(client)
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

type stackTracer interface {
	StackTrace() errors.StackTrace
}

func doIt(client *http.Client) {
	req := postAudit()

	log.Println("START")
	res, err := scramsha.DoScramSha(req, "foobar", "asdasd", client)
	log.Println("FIN")
	//res, err := doBasic(req, "Administrator", "asdasd", client)
	if err != nil {
		if err, ok := err.(stackTracer); ok {
			for _, f := range err.StackTrace() {
				fmt.Printf("%+s:%d", f)
			}
		}
		log.Printf("ERR %v", reflect.TypeOf(err))
		panic(err)
	}

	log.Println("Status code : ", res.StatusCode)
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
