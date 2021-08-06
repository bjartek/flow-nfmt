import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import NFTMetadata from "../contracts/NFTMetadata.cdc"
import GenericNFT from "../contracts/GenericNFT.cdc"
import Profile from "../contracts/Profile.cdc"


transaction() {
  prepare(account: AuthAccount) {

      let admin=account.borrow<&GenericNFT.Admin>(from: GenericNFT.AdminStoragePath)!


      account.save<@GenericNFT.PagedCollection>(<- GenericNFT.createEmptyPagedCollection(pageSize: 2), to: /storage/sharedContent)
      account.link<&{GenericNFT.CollectionPublic}>(/private/sharedContent, target: /storage/sharedContent)



      //todo init profile here
      let profileCap =account.getCapability<&{Profile.Public}>(Profile.publicPath)
      let minter <- admin.createMinter(platform: GenericNFT.MinterPlatform( owner: profileCap, minter: profileCap, ownerPercentCut: 0.01))
        
      account.save<@GenericNFT.PagedCollection>(<- GenericNFT.createEmptyPagedCollection(pageSize: 2), to: /storage/nft)
      account.link<&{NonFungibleToken.CollectionPublic}>(/public/nft, target: /storage/nft)
      account.link<&{GenericNFT.CollectionPublic}>(/public/paged, target: /storage/nft)

      let sharedContentCap =account.getCapability<&{GenericNFT.CollectionPublic}>(/private/sharedContent)
      
      let creativeWork=NFTMetadata.CreativeWork(artist: "Bjarte", name: "GenericNFT", description:"This is a shared content schema that will be stored with the tenant and shared with all editions or similar kind of constructs", type: "Text"  )
      let sharedNFT <- minter.mintNFT(name: "Art", schemas: { "creativeWork" : creativeWork}, sharedData: {})

      let sharedPointer= GenericNFT.GenericNFTPointer(collection: sharedContentCap, id: sharedNFT.id, schema: "creativeWork")

      sharedContentCap.borrow()!.deposit(token: <- sharedNFT)
      
      let publicPagedCollection=account.borrow<&GenericNFT.PagedCollection>(from: /storage/nft)!

      publicPagedCollection.deposit(token:  <- minter.mintNFT(name: "test art0", schemas: {
            "editions" : NFTMetadata.Editioned(edition: 1, maxEdition:3) 
            }, sharedData: { "shared/metadata/createiveWork" : sharedPointer}))

      publicPagedCollection.deposit(token:  <- minter.mintNFT(name: "test art1", schemas: {
          "editions" : NFTMetadata.Editioned(edition: 2, maxEdition:3)
          }, sharedData: { "shared/metadata/createiveWork" : sharedPointer}))


      publicPagedCollection.deposit(token:  <- minter.mintNFT(name: "test art2", schemas: {
          "editions" : NFTMetadata.Editioned(edition: 3, maxEdition:3)
          }, sharedData: { "shared/metadata/createiveWork" : sharedPointer}))



        destroy minter
  }

}


