package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{} // use default options

func main() {
	http.HandleFunc("/echo", echo)
	http.HandleFunc("/", HelloServer)
	http.ListenAndServe(":8080", nil)
}

func echo(w http.ResponseWriter, r *http.Request) {
	c, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Print("upgrade:", err)
		return
	}
	defer c.Close()
	for {
		mt, message, err := c.ReadMessage()
		if err != nil {
			log.Println("read:", err)
			break
		}
		log.Printf("recv: %s", message)
		err = c.WriteMessage(mt, message)
		if err != nil {
			log.Println("write:", err)
			break
		}
	}
}

func HelloServer(w http.ResponseWriter, r *http.Request) {

	fmt.Fprintf(w, "Hello world - test pr!")

	vars := os.Environ()

	for _, env := range vars {
		fmt.Fprintf(w, "Found env var: %s\n", env)
	}

}
