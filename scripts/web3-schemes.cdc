import NonFungibleToken from "../contracts/NonFungibleToken.cdc"


pub fun main(address: Address, path: PublicPath, id: UInt64) : [String] {

let account=getAccount(address)
  let views=  getAccount(address)
   .getCapability(path)
   .borrow<&{NonFungibleToken.CollectionPublic}>()!
   .borrowNFT(id: id)
   .getViews()

	 var viewIdentifiers : [String] = []
	 for v in views {
		 viewIdentifiers.append(v.identifier)
	 }
	 return viewIdentifiers

}

