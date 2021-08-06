import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import NFTMetadata from "../contracts/NFTMetadata.cdc"

//A NFT contract to store art
//modified by making all protected methods public for convenience
pub contract GenericNFT: NonFungibleToken {

  pub let forSaleSchemeName : String

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Editioned(id: UInt64, from: UInt64, edition: UInt64, maxEdition: UInt64)


    pub resource NFT: NonFungibleToken.INFT {
      pub let id: UInt64
      access(contract) let schemas: {String : AnyStruct}
      access(contract) let name: String
        init(
            initID: UInt64, 
            name: String,
            schemas: {String: AnyStruct}) {

          self.id = initID
            self.schemas=schemas
            self.name=name
        }



      pub fun getName() : String {
        return self.name
      }

      pub fun getSchemas() : [String] {
        return self.schemas.keys
      }

      pub fun resolveSchema(_ schema: String): AnyStruct {
        if !self.schemas.keys.contains(schema) {
          panic("Cannot resolve for unknown schema")
        }

        return self.schemas[schema]
      }

    }



  pub resource interface CollectionPublic {

    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun purchase(tokenId: UInt64, vault: @FungibleToken.Vault, target: Capability<&{NonFungibleToken.Receiver}>)

  }

  pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic {
    // dictionary of NFT conforming tokens
    // NFT is a resource type with an `UInt64` ID field
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    init () {
      self.ownedNFTs <- {}
    }

    // withdraw removes an NFT from the collection and moves it to the caller
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

        emit Withdraw(id: token.id, from: self.owner?.address)

        return <-token
    }

    // deposit takes a NFT and adds it to the collections dictionary
    // and adds the ID to the id array
    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <- token as! @GenericNFT.NFT

        let id: UInt64 = token.id

        // add the new token to the dictionary which removes the old one
        let oldToken <- self.ownedNFTs[id] <- token

        emit Deposit(id: id, to: self.owner?.address)

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

    pub fun changePrice(tokenId: UInt64, price: UFix64) {
      if self.ownedNFTs[tokenId] != nil {
        let ref = &self.ownedNFTs[tokenId] as auth &NonFungibleToken.NFT
          let nft = ref as! &GenericNFT.NFT
          let forSale=nft.schemas[GenericNFT.forSaleSchemeName] as! NFTMetadata.ForSale
          forSale.changePrice(price)
      } 
    }


    pub fun removeForSale(tokenId: UInt64) {
      if self.ownedNFTs[tokenId] != nil {
        let ref = &self.ownedNFTs[tokenId] as auth &NonFungibleToken.NFT
          let nft = ref as! &GenericNFT.NFT
          nft.schemas.remove(key: GenericNFT.forSaleSchemeName)
      } 
    }

    pub fun forSale(tokenId: UInt64, saleInfo: NFTMetadata.ForSale) {
      if self.ownedNFTs[tokenId] != nil {
        let ref = &self.ownedNFTs[tokenId] as auth &NonFungibleToken.NFT
          let nft = ref as! &GenericNFT.NFT
          nft.schemas[GenericNFT.forSaleSchemeName]=saleInfo
      } 
    }

    pub fun purchase(tokenId: UInt64, vault: @FungibleToken.Vault, target: Capability<&{NonFungibleToken.Receiver}>) {
      let nft <-  self.withdraw(withdrawID:tokenId)

        let schemas = nft.getSchemas()
        if !schemas.contains(GenericNFT.forSaleSchemeName) {
          panic("This NFT is not for sale")
        }


      let forSale = nft.resolveSchema(GenericNFT.forSaleSchemeName) as! NFTMetadata.ForSale
        var salePrice= forSale.saleSum
        if vault.balance !=  salePrice {
          panic("Vault sum does not match sale price")
        }


      if schemas.contains("metadata/royalties") {
        let royalties = nft.resolveSchema("metadata/royalties") as! NFTMetadata.Royalties
          for royalty in royalties.royalty {

            if let receiver = royalty.wallet.borrow() {
              if royalty.type == NFTMetadata.RoyaltyType.percentage {
                let amount= salePrice * royalty.cut
                  royalty.wallet.borrow()?.deposit(from: <- vault.withdraw(amount:amount))
              } else if  royalty.type == NFTMetadata.RoyaltyType.fixed {
                royalty.wallet.borrow()?.deposit(from: <- vault.withdraw(amount:royalty.cut))
              }

            } else {
              //TOOD: emit event that wallet was not linked anymore
            }
          }
      }


      //deposit rest of money
      forSale.wallet.borrow()!.deposit(from: <- vault)

      //deposit the NFT
        target.borrow()!.deposit(token: <- nft)

      //TODO: error handling
    }
    destroy() {
      destroy self.ownedNFTs
    }
  }


  /*
     I want a collection that has several pages and if reaches max capacity in a page will create a new one
   */
  pub resource PagedCollection : NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic {
    pub var pages: @{UInt64: GenericNFT.Collection}
    pub let pageSize: UInt64

      init(pageSize: UInt64) {
        self.pageSize= pageSize
          self.pages <- { }
      }


    pub fun getIDs(): [UInt64] {

      var ids: [UInt64] = []
        for key in self.pages.keys {
          for id in self.pages[key]?.getIDs() ?? [] {
            ids.append(id)
          }
        }
      return ids
    }

    access(self) fun page(_ id:UInt64) : UInt64 {
      return UInt64(id/self.pageSize)
    }

    pub fun transfer(tokenId: UInt64, target: Capability<&{NonFungibleToken.Receiver}>) {
      let token <- self.withdraw(withdrawID: tokenId)

        target.borrow()!.deposit(token: <- token)
    }


    pub fun changePrice(tokenId: UInt64, price: UFix64) {
          let pageNumber = self.page(tokenId)
        // Remove the collection
        let page <- self.pages.remove(key: pageNumber)!

        page.changePrice(tokenId: tokenId, price: price)
        self.pages[pageNumber] <-! page
    }

    pub fun removeForSale(tokenId: UInt64) {
          let pageNumber = self.page(tokenId)
        // Remove the collection
        let page <- self.pages.remove(key: pageNumber)!

        page.removeForSale(tokenId: tokenId)
        // Put the Collection back in storage
        self.pages[pageNumber] <-! page
   
    }

    pub fun forSale(tokenId: UInt64, saleInfo: NFTMetadata.ForSale) {
      let pageNumber = self.page(tokenId)
        // Remove the collection
        let page <- self.pages.remove(key: pageNumber)!

        page.forSale(tokenId: tokenId, saleInfo: saleInfo)
        // Put the Collection back in storage
        self.pages[pageNumber] <-! page
    }

    pub fun purchase(tokenId: UInt64, vault: @FungibleToken.Vault, target: Capability<&{NonFungibleToken.Receiver}>) {
      let pageNumber = self.page(tokenId)
        // Remove the collection
        let page <- self.pages.remove(key: pageNumber)!

        page.purchase(tokenId: tokenId, vault: <- vault, target: target) 
        // Put the Collection back in storage
        self.pages[pageNumber] <-! page
    }

    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      post {
        result.id == withdrawID: "The ID of the withdrawn NFT is incorrect"
      }

      let page = self.page(withdrawID)
        let token <- self.pages[page]?.withdraw(withdrawID: withdrawID)!

        return <-token
    }

    pub fun deposit(token: @NonFungibleToken.NFT) {

      let pageNumber = self.page(token.id)
        if !self.pages.containsKey(pageNumber) {
          self.pages[pageNumber] <-! GenericNFT.createEmptyCollection() as! @GenericNFT.Collection
        }

      // Remove the collection
      let page <- self.pages.remove(key: pageNumber)!

        // Deposit the nft into the bucket
        page.deposit(token: <-token)

        // Put the Collection back in storage
        self.pages[pageNumber] <-! page
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      post {
        result.id == id: "The ID of the reference is incorrect"
      }

      return self.pages[self.page(id)]?.borrowNFT(id: id)!
    }


    destroy() {
      destroy self.pages
    }

  }

  // public function that anyone can call to create a new empty collection
  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  pub fun createEmptyPagedCollection(pageSize:UInt64) : @GenericNFT.PagedCollection {
    return <- create PagedCollection(pageSize: pageSize)
  }

//TODO: make sure that when creating a minter add a special metadata struct maybe MinterPlattform that has a royalty
//TODO: Admin resource to create minter
   //TODO: shared content
  //TODO protect this with minter
  //This method can only be called from another contract in the same account. In Versus case it is called from the VersusAdmin that is used to administer the solution
  pub fun createGenericNFT(name: String, schemas: {String: AnyStruct}) : @GenericNFT.NFT {
    let nft <-  create NFT(initID: GenericNFT.totalSupply, name: name, schemas:schemas)
      GenericNFT.totalSupply = GenericNFT.totalSupply + 1
      return <-  nft
  }

  init() {
    self.forSaleSchemeName="metadata/forSale"
      // Initialize the total supply
      self.totalSupply = 0
      self.CollectionPublicPath=/public/genericNFT
      self.CollectionStoragePath=/storage/genericNFT

      self.account.save<@NonFungibleToken.Collection>(<- GenericNFT.createEmptyCollection(), to: GenericNFT.CollectionStoragePath)
      self.account.link<&{NonFungibleToken.CollectionPublic}>(GenericNFT.CollectionPublicPath, target: GenericNFT.CollectionStoragePath)
      emit ContractInitialized()
  }
}

