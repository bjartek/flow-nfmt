# Generic NFT contract


A generic NFT contract where the owner of the platform can create a minter and give/sell it to somebody. 

They can then mint art and a certain % of sales will go to the owner of the platform. For now only simple buy direct sales are added.

Builds upon the NFT metadata purposal so the web3 style links from below still work. 


Take a look at the `transactions/nfmt.cdc` file for information on how to min things.

[NB](NB)! Currently as can be seen in go.mod this needs a local version of flow-cli and cadence. 

 - The cadence version is https://github.com/bluesign/cadence with the patch in cadence-patch
 - flow-cli is latest with patch in flow-cli-patch


## Support for web3 like urls 


If you make your NFT collection link to `NonFungibleToken.PublicCollection` support for web3 style links are very easy.
 ```
url="0xf8d6e0586b0a20c7/versusArtCollection" go run web3/main.go
```
will return all the ids you have in this collection

 ```
url="0xf8d6e0586b0a20c7/versusArtCollection/1" go run web3/main.go
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
url="0xf8d6e0586b0a20c7/versusArtCollection/0/metadata|editions"
```

to get editions output like
```
{
    "edition": "1",
    "maxEdition": "1"
}
```



## TODO:
 - add profile in example 
 - method to filter all nfts on a tenant.
