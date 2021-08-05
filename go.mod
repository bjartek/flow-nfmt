module github.com/bjartek/flow-nftm

go 1.16

replace github.com/onflow/cadence => /Users/bjartek/dev/cadence

replace github.com/onflow/cadence/languageserver => /Users/bjartek/dev/cadence/languageserver

replace github.com/onflow/flow-cli => /Users/bjartek/dev/flow-cli

//"replace github.com/bjartek/go-with-the-flow => /Users/bjartek/dev/go-with-the-flow

require (
	github.com/bjartek/go-with-the-flow/v2 v2.1.2
	github.com/onflow/cadence v0.18.1-0.20210621144040-64e6b6fb2337
)
