package main

import (
	"github.com/bjartek/go-with-the-flow/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowDevNet()

	flow.TransactionFromFile("nfmt").
		SignProposeAndPayAs("emulator-account").
		RunPrintEventsFull()

}