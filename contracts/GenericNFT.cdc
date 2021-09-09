
//so doing imports like this is strictly not neccesary in contracts, but it is easier that they are the same in transactions/scripts/contracts
//import NonFungibleToken from "./NonFungibleToken.cdc" would work here aswell

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import NFTMetadata from "../contracts/NFTMetadata.cdc"
import Profile from "../contracts/Profile.cdc"

/* 
A NFT contrat to mint and handle GenericNFTs.

- an NFT is generic because when you mint it you can add whatever schemas you want to it. 
- you can also add shared shemas if you want to store content one place and refer them in other GenericNFTs. NB! Note that you should store these shared NFTS in a schema that has a private capability path so that you avoid transfering them away easily. If you do thinks will break and people will not like you. 
-- all shared schemas must by convenience start with shared/ to avoid confusion
- there are some given schemas that are always present with an GenericNFT 
--  minter will tell you the name of this minter, the percentage that the owner of the platform will take on sales and link to profile capabilities
-- profile/minter will give you the profile of the minter
-- profile/platform will give you the profile of the platform. The entity that deployed this contract
*/

//modified by making all protected methods public for convenience
pub contract GenericNFT: NonFungibleToken {

	pub let AdminStoragePath: StoragePath
	pub let forSaleSchemeName : String
	pub let minterSchemeName : String
	pub let minterProfilechemeName : String
	pub let platformProfileSchemeName : String

	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Editioned(id: UInt64, from: UInt64, edition: UInt64, maxEdition: UInt64)


	pub struct ViewInfo {
		access(contract) let typ: Type
		access(contract) let result: AnyStruct

		init(typ:Type, result:AnyStruct) {
			self.typ=typ
			self.result=result
		}
	}

	pub resource NFT: NonFungibleToken.INFT {
		pub let id: UInt64
		access(contract) let schemas: {String : ViewInfo}
		access(contract) let sharedData: {String : SchemaPointer}
		access(contract) let name: String
		access(contract) let minterPlatform: MinterPlatform

		init(initID: UInt64, name: String, schemas: {String: ViewInfo}, sharedData: {String: SchemaPointer}, minterPlatform: MinterPlatform) {
			for sharedKey in sharedData.keys {
				let length=sharedKey.length
				assert(length > 7,message:"Is to short, must end with  |shared is ".concat(sharedKey)) 
				let slice =sharedKey.slice(from:length-7, upTo:length)
				assert(slice == "|shared", message: "Does not end with |shared is".concat(slice))
			}
			self.id = initID
			self.schemas=schemas
			self.name=name
			self.sharedData=sharedData
			self.minterPlatform=minterPlatform
		}

		pub fun getViews() : [Type] {

			var views : [Type]=[]
			for s in self.schemas.keys {
				views.append(self.schemas[s]!.typ)

			}
			return views

			/*
			var schema= self.schemas.keys
			schema.appendAll(self.sharedData.keys)
			schema.append(GenericNFT.minterSchemeName)
			schema.append(GenericNFT.minterProfilechemeName)
			schema.append(GenericNFT.platformProfileSchemeName)
			return schema
			*/
		}

		//Note that when resolving schemas shared data are loaded last, so use schema names that are unique. ie prefix with shared/ or something
		pub fun resolveViews(_ type: Type): AnyStruct {
			return self.schemas[type.identifier]?.result

			/*
			if schema == GenericNFT.minterSchemeName {
				return self.minterPlatform
			} else if schema == GenericNFT.minterProfilechemeName {
				return self.minterPlatform.minter.borrow()!.asProfile()
			} else if schema == GenericNFT.platformProfileSchemeName {
				return self.minterPlatform.platform.borrow()!.asProfile()
			} else if self.schemas.keys.contains(schema) {
				return self.schemas[schema]
			} else if self.sharedData.keys.contains(schema) {
				return self.sharedData[schema]!.resolve()
			}

			return ""
			*/
		}

	}


	pub resource interface CollectionPublic {

		pub fun deposit(token: @NonFungibleToken.NFT)
		pub fun getIDs(): [UInt64]
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
//		pub fun purchase(tokenId: UInt64, vault: @FungibleToken.Vault, target: Capability<&{NonFungibleToken.Receiver}>)

	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		init () {
			self.ownedNFTs <- {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @GenericNFT.NFT

			let id: UInt64 = token.id

			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)

			destroy oldToken
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return &self.ownedNFTs[id] as &NonFungibleToken.NFT
		}


		/*
		// Could this be added to the standard? That it is possible for the owner of an NFT to mixin things to it after it is created?
		//Add the posibility for the owner of an NFT to mixin new data to it. Note that it is explicit that this is mixed in and the user that mixed it in
		pub fun mixin(tokenId: UInt64, schema:String, resolution: AnyStruct) {
				if self.owner == nil {
					panic("Must be owned to mixin")
				}

				let schemaName=schema.concat("|mixin|").concat(self.owner!.address.toString())

				if self.ownedNFTs[tokenId] != nil {
					let ref = &self.ownedNFTs[tokenId] as auth &NonFungibleToken.NFT
					let nft = ref as! &GenericNFT.NFT

					nft.schemas[schemaName] = resolution
			} 
		}
		
		/// Could this be added to the standard? That it is possible for the owner of an NFT to remove a Mixin things to it after it is created?
		pub fun removeMixin(tokenId: UInt64, schema:String) {
				if self.owner == nil {
					panic("Must be owned to mixin")
				}

				let schemaName=schema.concat("|mixin|").concat(self.owner!.address.toString())

				if self.ownedNFTs[tokenId] != nil {
					let ref = &self.ownedNFTs[tokenId] as auth &NonFungibleToken.NFT
					let nft = ref as! &GenericNFT.NFT

					if !nft.getSchemas().contains(schemaName) {
						panic("Cannot remove mixin")
					}
					nft.schemas.remove(key: schemaName)
			} 
		}


		//TODO: do we need borrowGeneric here?
		//TODO: add more safety here
		pub fun changePrice(tokenId: UInt64, price: UFix64) {
			if self.ownedNFTs[tokenId] != nil {
				let ref = &self.ownedNFTs[tokenId] as auth &NonFungibleToken.NFT
				let nft = ref as! &GenericNFT.NFT
				let forSale=nft.schemas[GenericNFT.forSaleSchemeName] as! NFTMetadata.ForSale
				forSale.changePrice(price)
			} 
		}


		pub fun removeForSale(tokenId: UInt64) {
			if self.ownedNFTs[tokenId] != nil {
				let ref = &self.ownedNFTs[tokenId] as auth &NonFungibleToken.NFT
				let nft = ref as! &GenericNFT.NFT
				nft.schemas.remove(key: GenericNFT.forSaleSchemeName)
			} 
		}

		pub fun forSale(tokenId: UInt64, saleInfo: NFTMetadata.ForSale) {
			if self.ownedNFTs[tokenId] != nil {
				let ref = &self.ownedNFTs[tokenId] as auth &NonFungibleToken.NFT
				let nft = ref as! &GenericNFT.NFT
				nft.schemas[GenericNFT.forSaleSchemeName]=saleInfo
			} 
		}

		pub fun purchase(tokenId: UInt64, vault: @FungibleToken.Vault, target: Capability<&{NonFungibleToken.Receiver}>) {
			let nft <-  self.withdraw(withdrawID:tokenId)

			let schemas = nft.getSchemas()
			if !schemas.contains(GenericNFT.forSaleSchemeName) {
				panic("This NFT is not for sale")
			}


			let forSale = nft.resolveSchema(GenericNFT.forSaleSchemeName) as! NFTMetadata.ForSale
			var salePrice= forSale.saleSum
			if vault.balance !=  salePrice {
				panic("Vault sum does not match sale price")
			}


			if schemas.contains("0xf8d6e0586b0a20c7.NFTMetadata.Royalties") {
				let royalties = nft.resolveSchema("0xf8d6e0586b0a20c7.NFTMetadata.Royalties") as! NFTMetadata.Royalties
				for royalty in royalties.royalty {

					if let receiver = royalty.wallet.borrow() {
						if royalty.type == NFTMetadata.RoyaltyType.percentage {
							let amount= salePrice * royalty.cut
							royalty.wallet.borrow()?.deposit(from: <- vault.withdraw(amount:amount))
						} else if  royalty.type == NFTMetadata.RoyaltyType.fixed {
							royalty.wallet.borrow()?.deposit(from: <- vault.withdraw(amount:royalty.cut))
						}

					} else {
						//TOOD: emit event that wallet was not linked anymore
					}
				}
			}


			//the owner of the generic NFT plattform can take a cut
			let minter = nft.resolveSchema(GenericNFT.minterSchemeName) as! MinterPlatform 
			let platformOwnerCut=salePrice * minter.platformPercentCut
			//TODO: check that it can accept the type of token and else emit an event
			if platformOwnerCut != 0.0 {
				minter.platform.borrow()?.deposit(from: <- vault.withdraw(amount: platformOwnerCut))
			}

			//deposit rest of money
			forSale.wallet.borrow()!.deposit(from: <- vault)

			//deposit the NFT
			target.borrow()!.deposit(token: <- nft)

			//TODO: error handling
		}
		*/
		destroy() {
			destroy self.ownedNFTs
		}
	}

	//TODO: add support for shared resources across nfts that are stored with the minter
	pub resource Minter {
		access(contract) let platform: MinterPlatform

		init(platform: MinterPlatform) {
			self.platform=platform
		}


		pub fun mintNFT(name: String, schemas: [AnyStruct], sharedData: {String: SchemaPointer}) : @GenericNFT.NFT {
			let views : {String: ViewInfo} = {}
			for s in schemas {
				views[s.getType().identifier]=ViewInfo(typ:s.getType(), result: s)
			}
	
			let nft <-  create NFT(initID: GenericNFT.totalSupply, name: name, schemas:views, sharedData:sharedData, minterPlatform: self.platform)
			GenericNFT.totalSupply = GenericNFT.totalSupply + 1
			return <-  nft
		}

	}

	pub resource interface MinterProxyPublic {
		pub fun setMinterCapability(cap: Capability<&Minter>)
	}

	// MinterProxy
	//
	// Resource object holding a capability that can be used to mint new tokens.
	// The resource that this capability represents can be deleted by the admin
	// in order to unilaterally revoke minting capability if needed.

	pub resource MinterProxy: MinterProxyPublic {

		// access(self) so nobody else can copy the capability and use it.
		access(self) var minterCapability: Capability<&Minter>?

		// Anyone can call this, but only the admin can create Minter capabilities,
		// so the type system constrains this to being called by the admin.
		pub fun setMinterCapability(cap: Capability<&Minter>) {
			self.minterCapability = cap
		}

		pub fun mintNFT(name: String, schemas: [AnyStruct], sharedData: {String: SchemaPointer}): @GenericNFT.NFT {
			return <- self.minterCapability!.borrow()!.mintNFT(name: name, schemas: schemas, sharedData: sharedData)
		}

		init() {
			self.minterCapability = nil
		}

	}

	// createMinterProxy
	//
	// Function that creates a MinterProxy.
	// Anyone can call this, but the MinterProxy cannot mint without a Minter capability,
	// and only the admin can provide that.
	//
	pub fun createMinterProxy(): @MinterProxy {
		return <- create MinterProxy()
	}


	pub resource Admin {
		pub fun createMinter(platform: MinterPlatform) : @GenericNFT.Minter {
			return <- create Minter(platform:platform)
		}
	}


	/*
	A pointer into the schema of an NFT stored in another GenericNFT collection
	*/
	pub struct SchemaPointer{
		pub let collection: Capability<&{GenericNFT.CollectionPublic}>
		pub let id: UInt64
		pub let scheme: String

		init(collection: Capability<&{GenericNFT.CollectionPublic}>, id: UInt64, scheme:String) {
			self.collection=collection
			self.id=id
			self.scheme=scheme
		}

		pub fun resolve() : AnyStruct {
			return nil
//			return self.collection.borrow()!.borrowNFT(id: self.id).resolveSchema(self.scheme)
		
		}
	}

	pub struct MinterPlatform {
		pub let platform: Capability<&{Profile.Public}>
		pub let minter: Capability<&{Profile.Public}>
		pub let platformPercentCut: UFix64
		pub let name: String

		init(name: String, platform:Capability<&{Profile.Public}>, minter: Capability<&{Profile.Public}>, platformPercentCut: UFix64) {
			self.platform=platform
			self.minter=minter
			self.platformPercentCut=platformPercentCut
			self.name=name
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	init() {
		self.forSaleSchemeName="0xf8d6e0586b0a20c7.NFTMetadata.ForSale|forSale"
		self.minterSchemeName="string|minterName"
		self.minterProfilechemeName="0xf8d6e0586b0a20c7.Profile.UserProfile|minterProfile"
		self.platformProfileSchemeName="0xf8d6e0586b0a20c7.Profile.UserProfile|platformProfile"
		// Initialize the total supply
		self.totalSupply = 0

		self.AdminStoragePath = /storage/genericNFTAdmin

		//Ideally I would not want this here in the same account that owns the contract, hope we can have multiple signers for init contract soon
		let admin <- create Admin()
		self.account.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}

