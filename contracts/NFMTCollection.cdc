import NonFungibleMetadataToken from "./NonFungibleMetadataToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"

pub contract NFMTCollection {


    //Standard NFT collectionPublic interface that can also borrowArt as the correct type
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowNFMT(id: UInt64): &{NonFungibleMetadataToken.INFT}?
    }

 // FIP:Added the new interface here
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, NonFungibleMetadataToken.CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            //TODO: Check that it implements to proper interface
            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }


        // FIP: Implemented the new method
        //borrowNFMT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFMT(id: UInt64): &{NonFungibleMetadataToken.INFT}?  {
             if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &NonFungibleMetadataToken.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NFMTCollection.Collection {
        return <- create Collection()
    }
}