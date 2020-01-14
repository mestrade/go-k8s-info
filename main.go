package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/", HelloServer)
	http.ListenAndServe(":8080", nil)
}

func HelloServer(w http.ResponseWriter, r *http.Request) {

	fmt.Fprintf(w, "Hello world - test pr!")

	vars := os.Environ()

	for _, env := range vars {
		fmt.Fprintf(w, "Found env var: %s\n", env)
	}

}
