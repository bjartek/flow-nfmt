= NFTv2

The current NFT standard on flow has by design very little shared metadata. There is a long living issue on the flow-nft repo https://github.com/onflow/flow-nft/issues/9 about this topic. 

After a couple of experiment I have landed on an implementation that I feel is simple and yet very powerful. 
The main sumary of the solution can best be described as content negotiation. An NFT exposes what 'schemas' it can be resolved as and then offer a method to resolve the schemas. In code this looks like

```
		pub fun getSchemas() : [String] 

		pub fun resolveSchema(_ schema:String): AnyStruct
```


A key goal of this proposal is to not break backwards compatibility, in order to do that the limitations of the current upgrade contract semantics must be taken into consideration. 

 - We cannot add fields - We can add methods But still if you add a method to an existing NonFungibleToken interface it will break any existing NFT contract. In order to mitigate this the following issue was made after a meeting between Bastian and myself. https://github.com/onflow/cadence/issues/989. Deniz/Bluesign took up the task and implemented it in https://github.com/onflow/cadence/pull/1076 With this fix in place in cadence we can not add methods to any standard interface and provide a default implementation. The above code can thus safely be added as 
  
 ```
    pub fun getSchemas() : [String] { return [] }

		pub fun resolveSchema(_ schema:String): AnyStruct {
			pre {
				self.getSchemas().contains(schema) : "Cannot resolve unknown schema"
			}

			return nil
		}

```

Any existing NonFungibleToken contract will by default not expose any schemas and not resovle anything. The owner of that contract can then implement the methods and thus be compliant with the new standard. 

== Schema names

There is however a big issue to be solved here, and that is. How do you name schemas. 
 - schemas must be human readable and understandable
 - schemas must be parsable in an easy way
 - multiple schemas of the same type should be supported. Tags should be used to distinguish them
  - in this proposal `|` is used as tag separator.   

Below are examples of different scenarios that I feel are valuable


A single struct
```
0xf8d6e0586b0a20c7.NFTMetadata.Editions
```

If you want to read this in cadence you could resolve this using

```
import NFTMeadata from 0xf8d6e0586b0a20c
...
nft.resolveSchema("0xf8d6e0586b0a20c7.NFTMetadata.Editions") as! NFTMetadata.Editions
```

A dictionary of string:string

```
{string:string}|addresses
```

An array of string
```
[string]|addresses
```

A string with a given tag
```
string|minterName
```

A string containing a base64 encoded image url
```
string|base64|image/png
```

A struct with a tag to show some more information about it, in my case here the GenericNFT supports shared data so i signal that something is shared by adding a tag

```
0xf8d6e0586b0a20c7.NFTMetadata.CreativeWork|shared
```		

Another way of using a tag is if you have multiple structs of the same type
```
0xf8d6e0586b0a20c7.Profile.UserProfile|minterProfile
0xf8d6e0586b0a20c7.Profile.UserProfile|platformProfile

```
An url to a png file
```
   "string|url|image/png|https://ipfs.io/ipfs/Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu"
```


An url to a schema.org/person represented as json
```
	 "string|url|json/schema.org/Person/https://url-to-person-json
```

An inline string that is a json representation of a schema.org/person

```
	 "string|json/schema.org/Person
```

