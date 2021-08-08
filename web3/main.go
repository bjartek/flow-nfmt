package main

import (
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
)

func main() {
	flow := gwtf.NewGoWithTheFlowEmulator()

	urlEnv, ok := os.LookupEnv("url")
	if !ok {
		panic("specify url")
	}

	parts := strings.Split(urlEnv, "/")

	account := parts[0]
	if len(parts) == 1 {
		flow.ScriptFromFile("web3-collections").RawAccountArgument(account).Run()
		return
	}
	publicPath := strings.ReplaceAll(parts[1], "|", "/")

	if len(parts) == 2 {
		//	flow.ScriptFromFile("web3-ids").RawAccountArgument(account).Argument(cadence.Path{Domain: "public", Identifier: publicPath}).Run()
		flow.ScriptFromFile("web3-ids-profile").RawAccountArgument(account).StringArgument(publicPath).Run()
		return
	}
	id, err := strconv.ParseUint(parts[2], 10, 64)
	if err != nil {
		log.Fatal(err)
	}

	if len(parts) == 3 {
		flow.ScriptFromFile("web3-schemes").RawAccountArgument(account).Argument(cadence.Path{Domain: "public", Identifier: publicPath}).UInt64Argument(id).Run()
		return
	}
	if len(parts) != 4 {
		panic("Invalid formed web3 url for flow format is <account>/<path|subpath...>/<id>/<scheme|subscheme...>")
	}
	scheme := strings.ReplaceAll(parts[3], "|", "/")

	flow.ScriptFromFile("web3").RawAccountArgument(account).Argument(cadence.Path{Domain: "public", Identifier: publicPath}).UInt64Argument(id).StringArgument(scheme).Run()
}
