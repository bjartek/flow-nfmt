
import FungibleToken from "../contracts/FungibleToken.cdc"

pub contract NFTMetadata {


	pub struct Royalties{
		pub let royalty: [Royalty]
		init(royalty: [Royalty]) {
			self.royalty=royalty
		}
	}

    pub struct Royalty{
        pub let wallet:Capability<&{FungibleToken.Receiver}> 
        pub let cut: UFix64

        init(wallet:Capability<&{FungibleToken.Receiver}>, cut: UFix64 ){
           self.wallet=wallet
           self.cut=cut
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
