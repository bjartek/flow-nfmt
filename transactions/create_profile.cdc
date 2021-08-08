import FungibleToken from "../contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import FUSD from "../contracts/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"



transaction(name: String, description: String, tags:[String], allowStoringFollowers: Bool, fusd: Bool) {
	prepare(acct: AuthAccount) {

		let profile <-Profile.createUser(name:name, description: description, allowStoringFollowers:allowStoringFollowers, tags:tags)

		let flowReceiver= acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		let flowBalance= acct.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance)
		let flow=acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
    let flowWallet= Profile.Wallet(name:"Flow", receiver: flowReceiver, balance: flowBalance, accept:Type<@FlowToken.Vault>(), tags: ["flow"])
    profile.addWallet(flowWallet)


    //Add exising FUSD or create a new one and add it
		let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if fusd && !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			let fusdType=fusd.getType()
			acct.save(<- fusd, to: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)

			let fusdWallet=Profile.Wallet(
				name:"FUSD", 
				receiver:acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver),
				balance:acct.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance),
				accept: Type<@FUSD.Vault>(),
				tags: ["fusd", "stablecoin"]
			)

			profile.addWallet(fusdWallet)

		}
		acct.save(<-profile, to: Profile.storagePath)
		acct.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)


		let profileCap =acct.borrow<&Profile.User>(from:Profile.storagePath)!
		profileCap.verify("test")

	}
}
