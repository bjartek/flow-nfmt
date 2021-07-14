import FungibleToken from 0xee82856bf20e2aa6
import NFMTCollection, NonFungibleMetadataToken, NonFungibleToken, Content, Art, ChainmonstersRewards, TopShot, Evolution,  from 0xf8d6e0586b0a20c7

transaction() {
     prepare(account: AuthAccount) {


        account.save<@NFMTCollection.Collection>(<- NFMTCollection.createEmptyCollection(), to: /storage/NFMTCollection)
        account.link<&{NFMTCollection.CollectionPublic}>(/public/NFTMCollection, target: /storage/NFMTCollection)
        var collection = account.getCapability<&{NFMTCollection.CollectionPublic}>(/public/NFTMCollection).borrow()!

        let art <-  Art.createArtWithContent(
            name: "Test art",
            artist: "test creator", 
            artistAddress: account.address,
            description: "This is a test", 
            url: "https://this.is/bullshit",
            type: "png",
            royality: {})

        collection.deposit(token: <- art)

    }
    
}


