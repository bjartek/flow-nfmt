import Art from "../contracts/versus/Art.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"


transaction() {
     prepare(account: AuthAccount) {

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

    }
    
}


