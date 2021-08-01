package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {
	//flow := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")

	flow := gwtf.NewGoWithTheFlowInMemoryEmulator()

	flow.TransactionFromFile("nfmt").
		SignProposeAndPayAsService().
		RunPrintEventsFull()

	result, _ := flow.ScriptFromFile("art").AccountArgument("account").UInt64Argument(0).RunReturns()
	fmt.Println(result)

	result, _ = flow.ScriptFromFile("creativework").AccountArgument("account").UInt64Argument(0).RunReturns()
	fmt.Println(result)

	result, _ = flow.ScriptFromFile("editioned").AccountArgument("account").UInt64Argument(0).RunReturns()
	fmt.Println(result)

	result, _ = flow.ScriptFromFile("royalty").AccountArgument("account").UInt64Argument(0).RunReturns()
	fmt.Println(result)
}
