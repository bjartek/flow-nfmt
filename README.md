# Generic NFT contract


A generic NFT contract where the owner of the platform can create a minter and give/sell it to somebody. 

They can then mint art and a certain % of sales will go to the owner of the platform. For now only simple buy direct sales are added.

Builds upon the NFT metadata purposal so the web3 style links from below still work. 

Take a look at the `transactions/nfmt.cdc` file for information on how to mint things.

[NB](NB)! Currently as can be seen in go.mod this needs a local version of flow-cli and cadence. 

 - The cadence version is https://github.com/bluesign/cadence with the patch in cadence-patch
 - flow-cli is latest with patch in flow-cli-patch

## Features
 - setup is done via capability receiver
  - minter creates a MinterProxy
	- platform owner creates a Minter and  stores it using a private capability path in his account
	- he then gives that capability to the MinterProxy
	- minter can not mintNFTS 
 - provide all schemas for the NFT when you mint
 - provide shared schemas that link to a NFT stored in minter
  - shared schemas must be design start their scheme name with 'shared/' to avoid confusion  
 - any schema is supported
 - support listing for sale inside the NFT collection
   - platform owner will take small cut off all sales
   - buy directly in the collecrion
   - support royalties using the royalties schema if present
 - discover data through web3 like urls. requires a Profile
   - 0xf8d6e0586b0a20c7: name of all &{NonFungible.CollectionPublic} collections in the profile
   - 0xf8d6e0586b0a20c7/art : show all ids
   - 0xf8d6e0586b0a20c7/art/1 : show all schemas for art 1
   - 0xf8d6e0586b0a20c7/art/1/metadata|royalty: resolve a schema
 - support mixin content after NFT is minted. When the owner of an NFT mixes inn content the schema for it is forced to me `mixin/<address>/<name provided>/`
  - an owner can later remove a mixing but only if he still owns the NFT 

## TODO:
 - add fragments
  - store nft in shared and link all framents to it
	- fragments have a count and a total number
	- when buying more then one fragment you can call `combineFragments` on one with the other. The fragment counter will be increased and the sent in fragment will be burnt.
  - if a user has all fragments and calls `combineFragment` extract the original NFT from shared and put into his storage and burn the original.
 - combineFragments must then be called from the collection where you send in all the ids to combine into one 
 - do not store the admin in the same account as the contract. multisign when adding contracts please?
 - create examples on how to set up the minter
 - create example no how to list for sale and buy
 - add unit tests.
 - add events. 
	 - think carefully about this!
 - should a GenericNFT be allowed to own a child collection? So that you can create a 'pack' and sell the entire pack.  

