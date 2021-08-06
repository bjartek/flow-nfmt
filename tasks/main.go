package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {
	flow := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")
	//flow := gwtf.NewGoWithTheFlowInMemoryEmulator()

	flow.TransactionFromFile("nfmt").
		SignProposeAndPayAsService().
		RunPrintEventsFull()
}
