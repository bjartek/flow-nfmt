import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import NFTMetadata from "../contracts/NFTMetadata.cdc"
import Profile from "../contracts/Profile.cdc"

//A NFT contract to store art
//modified by making all protected methods public for convenience
pub contract GenericNFT: NonFungibleToken {

  pub let AdminStoragePath: StoragePath
  pub let forSaleSchemeName : String
  pub let minterSchemeName : String
  pub let minterOwnerSchemeName : String
  pub let minterTenantSchemeName : String

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Editioned(id: UInt64, from: UInt64, edition: UInt64, maxEdition: UInt64)


    pub resource NFT: NonFungibleToken.INFT {
      pub let id: UInt64
      access(contract) let schemas: {String : AnyStruct}
      access(contract) let sharedData: {String : GenericNFTPointer}
      access(contract) let name: String
      access(contract) let minterPlatform: MinterPlatform

      init(initID: UInt64, 
            name: String,
            schemas: {String: AnyStruct}, 
            sharedData: {String: GenericNFTPointer}, 
            minterPlatform: MinterPlatform) {

          self.id = initID
            self.schemas=schemas
            self.name=name
            self.sharedData=sharedData
            self.minterPlatform=minterPlatform
        }



      pub fun getName() : String {
        return self.name
      }

      pub fun getSchemas() : [String] {
        var schema= self.schemas.keys
          schema.appendAll(self.sharedData.keys)
          schema.append(GenericNFT.minterSchemeName)
//          schema.append(GenericNFT.minterTenantSchemeName)
//          schema.append(GenericNFT.minterOwnerSchemeName)
          return schema
      }

      //Note that when resolving schemas shared data are loaded last, so use schema names that are unique. ie prefix with shared/ or something
      pub fun resolveSchema(_ schema: String): AnyStruct {
        if !self.getSchemas().contains(schema) {
          panic("Cannot resolve for unknown schema")
        }

        if schema == GenericNFT.minterSchemeName {
          //todo expand plattforms in verbose mode?
          return self.minterPlatform
        } else if self.schemas.keys.contains(schema) {
          return self.schemas[schema]
        } else if self.sharedData.keys.contains(schema) {
          return self.sharedData[schema]!.resolve()
        }

        return ""
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


      //the owner of the generic NFT plattform can take a cut
      let platform = nft.resolveSchema(GenericNFT.minterSchemeName) as! MinterPlatform 
      let platformOwnerCut=salePrice * platform.ownerPercentCut
      if platformOwnerCut != 0.0 {
        platform.owner.borrow()?.deposit(from: <- vault.withdraw(amount: platformOwnerCut))
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

  //TODO: add support for shared resources across nfts that are stored with the minter
  pub resource Minter {
    access(contract) let platform: MinterPlatform

      init(platform: MinterPlatform) {
        self.platform=platform
      }


    pub fun mintNFT(name: String, schemas: {String: AnyStruct}, sharedData: {String: GenericNFTPointer}) : @GenericNFT.NFT {
        let nft <-  create NFT(initID: GenericNFT.totalSupply, name: name, schemas:schemas, sharedData:sharedData, minterPlatform: self.platform)
        GenericNFT.totalSupply = GenericNFT.totalSupply + 1
        return <-  nft
    }

  }

  pub resource interface MinterProxyPublic {
    pub fun setMinterCapability(cap: Capability<&Minter>)
  }

  // MinterProxy
  //
  // Resource object holding a capability that can be used to mint new tokens.
  // The resource that this capability represents can be deleted by the admin
  // in order to unilaterally revoke minting capability if needed.

  pub resource MinterProxy: MinterProxyPublic {

    // access(self) so nobody else can copy the capability and use it.
    access(self) var minterCapability: Capability<&Minter>?

      // Anyone can call this, but only the admin can create Minter capabilities,
      // so the type system constrains this to being called by the admin.
      pub fun setMinterCapability(cap: Capability<&Minter>) {
        self.minterCapability = cap
      }

    pub fun mintNFT(name: String, schemas: {String: AnyStruct}, sharedData: {String: GenericNFTPointer}): @GenericNFT.NFT {
      return <- self.minterCapability!
        .borrow()!
        .mintNFT(name: name, schemas: schemas, sharedData: sharedData)
    }

    init() {
      self.minterCapability = nil
    }

  }

  // createMinterProxy
  //
  // Function that creates a MinterProxy.
  // Anyone can call this, but the MinterProxy cannot mint without a Minter capability,
  // and only the admin can provide that.
  //
  pub fun createMinterProxy(): @MinterProxy {
    return <- create MinterProxy()
  }


  pub resource Admin {
    pub fun createMinter(platform: MinterPlatform) : @GenericNFT.Minter {
      return <- create Minter(platform:platform)
    }

  }

  pub struct GenericNFTPointer{
      pub let collection: Capability<&{GenericNFT.CollectionPublic}>
      pub let id: UInt64
      pub let scheme: String

      init(collection: Capability<&{GenericNFT.CollectionPublic}>, id: UInt64, scheme:String) {
        self.collection=collection
          self.id=id
          self.scheme=scheme
      }

    pub fun resolve() : AnyStruct {
      return self.collection.borrow()!.borrowNFT(id: self.id).resolveSchema(self.scheme)
    }
  }

  pub struct MinterPlatform {
      pub let owner: Capability<&{Profile.Public}>
      pub let tenant: Capability<&{Profile.Public}>
      pub let ownerPercentCut: UFix64

      init(owner:Capability<&{Profile.Public}>, tenant: Capability<&{Profile.Public}>, ownerPercentCut: UFix64) {
          self.owner=owner
          self.tenant=tenant
          self.ownerPercentCut=ownerPercentCut
      }
  }

  // public function that anyone can call to create a new empty collection
  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }


  //create a empty paged colleciton that will auto grow and store nfts in <pageSize> number of pages
  //not really sure if this is needed here, but here it is
  pub fun createEmptyPagedCollection(pageSize:UInt64) : @GenericNFT.PagedCollection {
    return <- create PagedCollection(pageSize: pageSize)
  }


  init() {
      self.forSaleSchemeName="metadata/forSale"
      self.minterSchemeName="minter"
      self.minterOwnerSchemeName="minter/Owner"
      self.minterTenantSchemeName="minter/Tenant"
      // Initialize the total supply
      self.totalSupply = 0

      self.AdminStoragePath = /storage/fusdAdmin

      //Ideally I would not want this here in the same account that owns the contract, hope we can have multiple signers for init contract soon
      let admin <- create Admin()
      self.account.save(<-admin, to: self.AdminStoragePath)
      emit ContractInitialized()
  }
}

