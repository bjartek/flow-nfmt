import Art from "../contracts/versus/Art.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import NFTMetadata from "../contracts/NFTMetadata.cdc"
import GenericNFT from "../contracts/GenericNFT.cdc"


transaction() {
  prepare(account: AuthAccount) {

    let genericCollection=account.getCapability<&{NonFungibleToken.CollectionPublic}>(GenericNFT.CollectionPublicPath)
      let artCollectionCap=account.getCapability<&{NonFungibleToken.CollectionPublic}>(Art.CollectionPublicPath)
      let wallet= account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
      let artCollection=artCollectionCap.borrow()!

      let royalty = {
        "artist" : Art.Royalty(wallet: wallet, cut: 0.05),
        "minter" : Art.Royalty(wallet: wallet, cut: 0.025)
      }

    let art <-  Art.createArtWithContent(
        name: "Test art",
        artist: "test creator", 
        artistAddress: account.address,
        description: "This is a test", 
        url: "https://this.is/bullshit",
        type: "png",
        royalty:royalty) 

      artCollection.deposit(token: <- art)


      let generic <- GenericNFT.createGenericNFT(name: "test art", schemas: {
          "editions" : NFTMetadata.Editioned(edition: 1, maxEdition:10)
          })

    genericCollection.borrow()!.deposit(token: <- generic)


      account.save<@GenericNFT.PagedCollection>(<- GenericNFT.createEmptyPagedCollection(pageSize: 2), to: /storage/nft)
      account.link<&{NonFungibleToken.CollectionPublic}>(/public/nft, target: /storage/nft)
      account.link<&{GenericNFT.CollectionPublic}>(/public/paged, target: /storage/nft)

      let publicPagedCollection=account.borrow<&GenericNFT.PagedCollection>(from: /storage/nft)!

      publicPagedCollection.deposit(token:  <- GenericNFT.createGenericNFT(name: "test art0", schemas: {
            "editions" : NFTMetadata.Editioned(edition: 1, maxEdition:3)
            }))

      publicPagedCollection.deposit(token:  <- GenericNFT.createGenericNFT(name: "test art1", schemas: {
          "editions" : NFTMetadata.Editioned(edition: 2, maxEdition:3)
          }))


      publicPagedCollection.deposit(token:  <- GenericNFT.createGenericNFT(name: "test art2", schemas: {
          "editions" : NFTMetadata.Editioned(edition: 3, maxEdition:3)
          }))


  }

}


