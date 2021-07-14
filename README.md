# NonFungibleMetadataToken - FIP

This is a proposal for a new NFT standard with more fields. 


This proposal adds a new interface NonFungibleMetadataToken that has the following methods

```
getName() : String
getDescription() : String
getSchemas() : [String]
resolveSchema(_ schema: String) : AnyStruct
```


I did not add any fields since you cannot upgrade a contract by adding a new field. 

