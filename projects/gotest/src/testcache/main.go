package main

import "fmt"
import "time"
import "math/rand"

type userPassword struct {
	version  string
	user     string
	password string
}

type userPassword1 struct {
	version  int
	user     string
	password string
}

var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func RandStringRunes(n int) string {
    b := make([]rune, n)
    for i := range b {
        b[i] = letterRunes[rand.Intn(len(letterRunes))]
    }
    return string(b)
}

func prepare_s(c *LRUCache) {
	v := "1234567890123456789012345678901234567890"
	k := userPassword{v, "vova", "asdasd"}
	c.Set(k, "b")
	for i := 0; i < 100; i++ {
		k = userPassword{v, RandStringRunes(8), RandStringRunes(8)}
		c.Set(k, "b")
	}
}

func prepare_i(c *LRUCache) {
	v := 1234
	k := userPassword1{v, "vova", "asdasd"}
	c.Set(k, "b")
	for i := 0; i < 100; i++ {
		k = userPassword1{v, RandStringRunes(8), RandStringRunes(8)}
		c.Set(k, "b")
	}
}

func sget(c *LRUCache, user, password string) (interface{}, bool) {
	k := userPassword{"1234567890123456789012345678901234567890", user, password}
	return c.Get(k)
}

func iget(c *LRUCache, user, password string) (interface{}, bool) {
	k := userPassword1{1234, user, password}
	return c.Get(k)
}

func testS() time.Duration {
	c := NewLRUCache(200)
	prepare_s(c)

	start := time.Now()
	for i := 0; i < 10000000; i++ {
		sget(c, "vova", "asdasd")
	}
	elapsed := time.Since(start)
	fmt.Printf("TEST S %s\n", elapsed)
	return elapsed
}

func testI() time.Duration {
	c := NewLRUCache(200)
	prepare_i(c)

	start := time.Now()
	for i := 0; i < 10000000; i++ {
		iget(c, "vova", "asdasd")
	}
	elapsed := time.Since(start)
	fmt.Printf("TEST I %s\n", elapsed)
	return elapsed
}

func test() {
	aS := testS().Seconds()
	aI := testI().Seconds()
	fmt.Printf("PERCENT %v\n", (aS - aI) * 100 / aS)
}

func main() {
	rand.Seed(time.Now().UnixNano())
	test()
	test()
	test()
	test()
	test()
}
