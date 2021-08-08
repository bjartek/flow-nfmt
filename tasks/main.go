package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
)

func main() {
	flow := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")
	//flow := gwtf.NewGoWithTheFlowInMemoryEmulator()

	tags := cadence.NewArray([]cadence.Value{
		cadence.String("tag1"),
		cadence.String("tag2"),
	})

	flow.TransactionFromFile("create_profile").
		SignProposeAndPayAsService().
		StringArgument("GenericNFT").
		StringArgument("A generic NFT contract").
		Argument(tags).
		BooleanArgument(true).
		BooleanArgument(true).
		RunPrintEventsFull()

	flow.TransactionFromFile("nfmt").
		SignProposeAndPayAsService().
		RunPrintEventsFull()
}
