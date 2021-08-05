import NonFungibleToken from "../contracts/NonFungibleToken.cdc"


pub fun main(address: Address, path: PublicPath, id: UInt64) : [String] {

let account=getAccount(address)
  return  getAccount(address)
   .getCapability(path)
   .borrow<&{NonFungibleToken.CollectionPublic}>()!
   .borrowNFT(id: id)
   .getSchemas()

}
