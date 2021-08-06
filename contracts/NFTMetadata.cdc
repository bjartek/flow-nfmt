
import FungibleToken from "../contracts/FungibleToken.cdc"

pub contract NFTMetadata {


  pub struct ForSale{
    pub let wallet:Capability<&{FungibleToken.Receiver}> 
    pub let type: String
    pub var saleSum: UFix64

    init(type: String, saleSum:UFix64, wallet: Capability<&{FungibleToken.Receiver}>) {

      self.type=type
      self.saleSum=saleSum
      self.wallet=wallet
    }

    pub fun changePrice(_ saleSum: UFix64) {
      self.saleSum=saleSum
    }
  }

	pub struct Royalties{
		pub let royalty: [Royalty]
		init(royalty: [Royalty]) {
			self.royalty=royalty
		}
	}


    pub enum RoyaltyType: UInt8{
      pub case fixed
      pub case percentage
     }

    pub struct Royalty{
        pub let wallet:Capability<&{FungibleToken.Receiver}> 
        pub let cut: UFix64

        //can be percentage
        pub let type: RoyaltyType

        init(wallet:Capability<&{FungibleToken.Receiver}>, cut: UFix64, type:RoyaltyType ){
           self.wallet=wallet
           self.cut=cut
           self.type=type
        }
    }

	pub struct CreativeWork {
		pub let artist: String
		pub let name: String
		pub let description: String
		pub let type: String

		init(artist: String, name: String, description: String, type: String) {
			self.artist=artist
			self.name=name
			self.description=description
			self.type=type
		}
	}

	pub struct Editioned {
		pub let edition: UInt64
		pub let maxEdition: UInt64

		init(edition:UInt64, maxEdition:UInt64){
			self.edition=edition
			self.maxEdition=maxEdition
		}
	}
}
