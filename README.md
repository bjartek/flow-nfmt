# NonFungibleMetadataToken - FIP

This is a proposal for a new NFT standard with more fields. 


This proposal adds 3 new methods to NonFungibleToken and ads a default implementations to them. Thus it does not break compatibility.

```
getName() : String
getSchemas() : [String]
resolveSchema(_ schema: String) : AnyStruct
```

I did not add any fields since you cannot upgrade a contract by adding a new field. 


NB! Currently as can be seen in go.mod this needs a local version of flow-cli and cadence. 

 - The cadence version is https://github.com/bluesign/cadence with the patch in cadence-patch
 - flow-cli is latest with patch in flow-cli-patch
