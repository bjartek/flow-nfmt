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


## Support for web3 like urls 

If you make your NFT collection link to `NonFungibleToken.PublicCollection` support for web3 style links are very easy.
 ```
url="0xf8d6e0586b0a20c7/versusArtCollection/0" go run web3/main.go
```
will return the supported schemes for the nft of user `0xf8d6e0586b0a20c7` in the path of `versusArtCollection` for index 0
The result will here be

```
 [
    "imageUrl",
    "metadata",
    "metadata/royalties",
    "metadata/creativework",
    "metadata/editions"
]
```

to resolve any of these schmes run
```
url="0xf8d6e0586b0a20c7/versusArtCollection/0/metadata|editions" go run web3/main.go
```

to get editions output like
```
{
    "edition": "1",
    "maxEdition": "1"
}
```

