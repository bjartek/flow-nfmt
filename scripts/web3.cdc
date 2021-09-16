import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NFTMetadata from "../contracts/NFTMetadata.cdc"


pub fun main(address: Address, path: PublicPath, id: UInt64, identifier: String) : AnyStruct? {
	//this should be an arg

	let account=getAccount(address)
  let nft=getAccount(address)
   .getCapability(path)
   .borrow<&{NonFungibleToken.CollectionPublic}>()!
   .borrowNFT(id: id)

	 for v in nft.getViews() {
		 if v.identifier== identifier {
			 return nft.resolveView(v)

		 }
	 }
	 return nil

}

