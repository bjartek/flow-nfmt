import Art from "../contracts/versus/Art.cdc"


pub fun main(address: Address, id: UInt64) : Art.Metadata {

	 let account=getAccount(address)

    let artCollection= account.getCapability(Art.CollectionPublicPath).borrow<&{Art.CollectionPublic}>()!
    var art=artCollection.borrowNFT(id: id) 

	return art.resolveSchema("metadata") as! Art.Metadata
}

