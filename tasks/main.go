package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {
	//	flow := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")

	flow := gwtf.NewGoWithTheFlowInMemoryEmulator()

	flow.TransactionFromFile("nfmt").
		SignProposeAndPayAsService().
		RunPrintEventsFull()

	result := flow.ScriptFromFile("art").AccountArgument("account").UInt64Argument(0).RunReturnsJsonString()
	fmt.Println(result)
}
