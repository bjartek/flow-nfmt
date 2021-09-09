import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NFTMetadata from "../contracts/NFTMetadata.cdc"


pub fun main(address: Address, path: PublicPath, id: UInt64) : AnyStruct {
	//this should be an arg
let schema= Type<NFTMetadata.Editioned>()

let account=getAccount(address)
  return  getAccount(address)
   .getCapability(path)
   .borrow<&{NonFungibleToken.CollectionPublic}>()!
   .borrowNFT(id: id)
   .resolveView(schema)

}

