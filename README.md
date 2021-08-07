# Generic NFT contract


A generic NFT contract where the owner of the platform can create a minter and give/sell it to somebody. 

They can then mint art and a certain % of sales will go to the owner of the platform. For now only simple buy direct sales are added.

Builds upon the NFT metadata purposal so the web3 style links from below still work. 

Take a look at the `transactions/nfmt.cdc` file for information on how to min things.

[NB](NB)! Currently as can be seen in go.mod this needs a local version of flow-cli and cadence. 

 - The cadence version is https://github.com/bluesign/cadence with the patch in cadence-patch
 - flow-cli is latest with patch in flow-cli-patch

## Features
 - provide all schemas for the NFT when you mint
 - provide shared schemas that link to a NFT stored in minter
 - any schema is supported
 - support listing for sale inside the NFT collection
   - platform owner will take small cut off all sales
   - buy directly in the collecrion
 - support royalties using the royalties schema
 - discover data through web3 like urls
   - 0xf8d6e0586b0a20c7/art : show all ids
   - 0xf8d6e0586b0a20c7/art/1 : show all schemas for nft 1
   - 0xf8d6e0586b0a20c7/art/1/metadata|royalty: resolve a schema





## TODO:
 - add profile in example 
 - method to filter all nfts on a tenant.
 - add mutated state that others cannor change later
 - discover collections through profile


