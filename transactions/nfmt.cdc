import Art from "../contracts/versus/Art.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"


transaction() {
     prepare(account: AuthAccount) {

		let artCollectionCap=account.getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
		let artCollection=artCollectionCap.borrow()!

        let art <-  Art.createArtWithContent(
            name: "Test art",
            artist: "test creator", 
            artistAddress: account.address,
            description: "This is a test", 
            url: "https://this.is/bullshit",
            type: "png",
            royalty: {})

        artCollection.deposit(token: <- art)

    }
    
}


