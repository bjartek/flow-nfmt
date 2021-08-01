# NonFungibleMetadataToken - FIP

This is a proposal for a new NFT standard with more fields. 


This proposal adds 3 new methods to NonFungibleToken and ads a default implementations to them. Thus it does not break compatibility.

```
getName() : String
getSchemas() : [String]
resolveSchema(_ schema: String) : AnyStruct
```

I did not add any fields since you cannot upgrade a contract by adding a new field. 

