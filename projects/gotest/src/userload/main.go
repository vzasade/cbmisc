package main

import "fmt"
import "time"
import "math/rand"
import "encoding/json"
import "net/http"
import "io/ioutil"
import "net/url"
import "strings"
import "sync"

var prefix = "http://Administrator:asdasd@127.0.0.1:9000"

type Role struct {
	Role string
	BucketName string `json:"bucket_name"`
}

func getRoles() []string {
	resp, err := http.Get(prefix + "/settings/rbac/roles")
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)

	roles := make([]Role, 0)
	err = json.Unmarshal(body, &roles)
	if err != nil {
		panic(err)
	}

	rolesS := make([]string, 0)
	for _, r := range roles {
		if r.BucketName == "" {
			rolesS = append(rolesS, r.Role)
		} else {
			rolesS = append(rolesS, r.Role + "[" + r.BucketName + "]")
		}
	}
	return rolesS
}

func remove(s []string, i int) []string {
    s[len(s)-1], s[i] = s[i], s[len(s)-1]
    return s[:len(s)-1]
}

func getRandRoles(roles []string) []string {
	selectedRoles := make([]string, 0)
	nRoles := rand.Intn(5) + 1
	for i := 0; i < nRoles; i++ {
		roleIndex := rand.Intn(len(roles))
		selectedRoles = append(selectedRoles, roles[roleIndex])
		roles = remove(roles, roleIndex)
	}
	return selectedRoles
}

const letterBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

func randStringBytes(n int) string {
    b := make([]byte, n)
    for i := range b {
        b[i] = letterBytes[rand.Intn(len(letterBytes))]
    }
    return string(b)
}

func putUser(i int, client *http.Client, roles []string) string {
	myRoles := getRandRoles(roles)

	id := fmt.Sprintf("%s_%06d", randStringBytes(5), i)

	name := randStringBytes(rand.Intn(20) + 10)
	password := randStringBytes(rand.Intn(6) + 6)

	postURL := prefix + "/settings/rbac/users/local/" + id
	form := url.Values{}
	form.Add("roles", strings.Join(myRoles, ","))
	form.Add("password", password)
	form.Add("name", name)

	req, err := http.NewRequest("PUT", postURL, strings.NewReader(form.Encode()))
	req.Close = true
	if err != nil {
		panic(err)
	}
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")
	resp, err := client.Do(req)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	return fmt.Sprintf("Posted user %v with %s\n", id, resp.Status)
}

func printFn(c chan string) {
	for msg := range c {
		fmt.Printf(msg)
	}
}

func putUsers(start, num int, printC chan string, wg *sync.WaitGroup, client *http.Client, roles []string) {
	defer wg.Done()
	for i := start; i < start + num; i ++ {
		msg := putUser(i, client, roles)
		printC <- msg
	}
}

func main() {
	start := time.Now()

	times := 20
	batch := 500
//	times := 10
//	batch := 100

	var wg sync.WaitGroup
	rand.Seed(time.Now().UnixNano())
	roles := getRoles()

	client := &http.Client{}
	printC := make(chan string)

	go printFn(printC)
	for i := 0; i < times; i ++ {
		wg.Add(1)
		go putUsers(i * batch, batch, printC, &wg, client, roles)
	}
	fmt.Println("Main: Waiting for workers to finish")
	wg.Wait()

	elapsed := time.Since(start)
	fmt.Println("Main: Completed. ", elapsed)
}
