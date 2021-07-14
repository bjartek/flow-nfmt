/**

## The Flow Non-Fungible Token standard

## `NonFungibleToken` contract interface

The interface that all non-fungible token contracts could conform to.
If a user wants to deploy a new nft contract, their contract would need
to implement the NonFungibleToken interface.

Their contract would have to follow all the rules and naming
that the interface specifies.

## `NFT` resource

The core resource type that represents an NFT in the smart contract.

## `Collection` Resource

The resource that stores a user's NFT collection.
It includes a few functions to allow the owner to easily
move tokens in and out of the collection.

## `Provider` and `Receiver` resource interfaces

These interfaces declare functions with some pre and post conditions
that require the Collection to follow certain naming and behavior standards.

They are separate because it gives the user the ability to share a reference
to their Collection that only exposes the fields and functions in one or more
of the interfaces. It also gives users the ability to make custom resources
that implement these interfaces to do various things with the tokens.

By using resources and interfaces, users of NFT smart contracts can send
and receive tokens peer-to-peer, without having to interact with a central ledger
smart contract.

To send an NFT to another user, a user would simply withdraw the NFT
from their Collection, then call the deposit function on another user's
Collection to complete the transfer.

*/

import NonFungibleToken from "./NonFungibleToken.cdc"

// The main NFT contract interface. Other NFT contracts will
// import and implement this interface
//
pub contract interface NonFungibleMetadataToken {

    // Interface that the NFTs have to conform to
    //
    pub resource interface INFT {
        // The unique ID that each NFT has
        pub let id: UInt64
        pub fun getName(): String
        pub fun getDescription(): String
        pub fun getSchemas() : [String] 
        pub fun resolveSchema(_ schema:String): AnyStruct
        //TODO: add pre that checks that schame must be in getSchemas
    }

    // Requirement that all conforming NFT smart contracts have
    // to define a resource called NFT that conforms to INFT
    pub resource NFT: INFT, NonFungibleToken.INFT {
        pub let id: UInt64
        pub fun getName(): String
        //This method might actually be redudant, since lots of nfts do not have this on chain and it can be easily made with getDescription
        pub fun getDescription(): String

        pub fun getSchemas() : [String]         //FIP: should this resolve to nil and be optional if the schema is not registered?

        pub fun resolveSchema(_ schema:String): AnyStruct{
            pre {
                !self.getSchemas().contains(schema)  : "Must be a valid schema for this NFMT"
            }
        }

    }

    // Interface that an account would commonly 
    // publish for their collection
    pub resource interface CollectionPublic {
        //TODO: Should this return INFT or NFT?
        pub fun borrowNFMT(id: UInt64): &{INFT}? 
    }

    //TODO: This can probably just be removed
    // Requirement for the the concrete resource type
    // to be declared in the implementing contract
    //
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic {

        // Dictionary to hold the NFTs in the Collection
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT)

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64]

        // Returns a borrowed reference to an NFT in the collection
        // so that the caller can read data and call methods from it
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            pre {
                self.ownedNFTs[id] != nil: "NFT does not exist in the collection!"
            }
        }
         // Returns a borrowed reference to an NFT in the collection
        // so that the caller can read data and call methods from it
        pub fun borrowNFMT(id: UInt64): &{INFT}?             {
            pre {
                self.ownedNFTs[id] != nil: "NFT does not exist in the collection!"
            }
        }
    }

}