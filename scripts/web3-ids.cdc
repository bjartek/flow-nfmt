import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
pub fun main(address: Address, path: PublicPath) : [UInt64] {

let account=getAccount(address)
  return  getAccount(address)
   .getCapability(path)
   .borrow<&{NonFungibleToken.CollectionPublic}>()!
   .getIDs()

}

