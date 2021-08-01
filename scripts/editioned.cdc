import Art from "../contracts/versus/Art.cdc"
import NFTMetadata from "../contracts/NFTMetadata.cdc"


pub fun main(address: Address, id: UInt64) : NFTMetadata.Editioned {

	 let account=getAccount(address)

    let artCollection= account.getCapability(Art.CollectionPublicPath).borrow<&{Art.CollectionPublic}>()!
    var art=artCollection.borrowNFT(id: id) 

    let schema="metadata/editions"
	return art.resolveSchema(schema) as! NFTMetadata.Editioned
}

