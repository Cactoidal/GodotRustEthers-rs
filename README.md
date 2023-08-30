# GDNative Implementation of Ethers-rs

**This guide is written for Godot 3.5.**  

A guide for Godot 4+ could potentially be written in the future, once I have a better understanding of GDExtension.

In this guide, you will learn how to create and use a [Godot Rust](https://github.com/godot-rust/gdnative) library, how to implement blockchain and smart contract interaction in your game using [Ethers-rs](https://github.com/gakonst/ethers-rs), and you will compile a Godot project where players can change the color of a shared mesh using an on-chain transaction.

The example in this guide uses a [pre-deployed smart contract](https://github.com/Cactoidal/GodotRustEthers-rs/blob/main/ColorChain.sol).  If you are new to smart contracts and want a brief overview of what they are, and some design considerations to keep in mind when creating them, please refer to [the section at the end of this guide](https://github.com/Cactoidal/GodotRustEthers-rs/tree/main#smart-contracts-and-game-design).

### WARNING:
**As with any game engine, Godot has OS-level functions, and you should not download games from sources you do not trust.  This is especially true when combining crypto with games, as crypto security can be easily compromised by malicious programs.  Business involving personal custody of funds and valuables should be conducted on a secure device devoted to that purpose, not on a computer used for playing games.**

### WARNING:
**This guide was created for educational purposes, for use in experimentation, game jams, and hackathons.  The process described here has not been independently audited, and should not be used in production without thorough examination of the underlying mechanisms.  Use at your own risk.**


## Setting up Godot Rust

I strongly recommend referring to the [Godot Rust documentation](https://godot-rust.github.io/book/gdnative/intro/setup.html).

To reiterate,

1) [Download](https://godotengine.org/download/3.x) or [compile](https://github.com/godotengine/godot/releases/tag/3.5.2-stable) Godot 3.5.

2) Download [Rust](https://rustup.rs/) and [LLVM](https://releases.llvm.org/) (and [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) if using Windows)

3) Create the library for your project.  From the terminal:

```cargo init --lib project-name-lib```

4) Set up cargo.toml.


```
crate-type = ["cdylib"]

[dependencies]
gdnative = { version = "0.11", features = ["async"] }
ethers = "2.0.4"
ethers-contract = "2.0.4"
tokio = { version = "1.28.1, features = ["full] }
```


Useful utilities you may wish to add:

```
serde_json = "1.0.163"
hex = "0.4.3"
openssl = "0.10.52"
```

5. Set up your library by declaring classes and their methods, then initializing.




6. Once you've written your library, compile it with `cargo build`, then import it into Godot with the following steps:

* Create a GDNative library resource, and link it to your compiled library file.

* Create a GDNative script, and link it to a class defined in your library.

* Now go to Autoload in Project Settings, and enable the GDNative script you just created.


7. You can now call your Godot Rust library from anywhere by using the name of the class and the name of the method you want to call.


## Private Keys

Godot itself can generate a private key with `get_random_bytes(32)`.  This relies on the [Mbed-TLS library](https://github.com/Mbed-TLS/mbedtls), specifically the `mbedtls_ctr_drbg_random()` function.  

An implementation in gdscript could check for the player's keystore, and if one is not found, it will be created:

```
func check_keystore():
	var file = File.new()
	if file.file_exists("user://keystore") != true:
		var bytekey = Crypto.new()
		var content = bytekey.generate_random_bytes(32)
		file.open("user://keystore", File.WRITE)
		file.store_buffer(content)
		file.close()
```


Note that the private key is stored on the user's local machine, and will be exposed if the machine is compromised.  Additional security can be added by asking the player to enter a password when creating their keystore.

It is conceivably possible to import an externally-generated private key into the game, but that is outside the scope of this guide.



## Using the Private Key

Ethers-rs can instantiate a wallet from an array of 32 bytes.  By reading the bytes as a buffer from the keystore file, and passing the buffer as a string to our Godot Rust library, the game can perform blockchain operations:

get_address example
get_balance example




## Interacting with Blockchains

Ethers-rs is capable of many things, and I invite you to [read the documentation](https://docs.rs/ethers/latest/ethers/) to learn more about what you can do.  First, I'll go over some basic functions, such as retrieving the player's address and gas balance:



Note that you can use Ethers-rs to interact with any EVM chain, simply by passing the chain ID and an RPC node URL.



## Smart Contracts

You can interact with a specific smart contract by providing its ABI to your Godot Rust library.  The abigen! macro is the easiest way to do this, which simply takes an ABI.json and creates a contract object your library can interact with:


Read and write functions are very similar in setup, but have outcomes that need to be handled differently.  In both cases, you will need to instantiate the player's wallet, select the appropriate chain and provide an RPC URL, create the contract object, convert any parameters from Godot types into Ethers types, then call the function using its name and parameters listed in the ABI.  

important to set an error case
because transactions do fail
due to RPC node downtime, lack of gas, invalid input, and so on


### Reading


To read back into gdscript, you will need to convert the type into a variant.
for structs, you will need to turn it into a json
then use the parse_json function from gdscript

sometimes you will need to convert from hex into the desired value


### Writing

Please note that you will need gas to send write transactions.  Testnet gas is available from faucets, such as the Sepolia PoW faucet.




## ColorChain - a sample implementation:

I've provided a small project as an example.  To use it, clone this repository, then compile the Rust library.  Drag the compiled library into res://, import it into the Godot project by following the steps above, then run the game.

Copy the address that is generated for you, mine some gas from the Sepolia PoW faucet (this may take around 10 minutes), then choose a color for the cube and submit the transaction.

The cube's color will change to whichever color has been submitted.  Because every copy of this sample game uses the same smart contract, every player will see the same cube, and other players will see the color you picked (and can overwrite the color if they wish!)




## Exporting the Project

When exporting your game, you will need to compile the Godot Rust library for the target system.  This is most easily achieved by compiling on the target system itself.  Cross-compilation is also possible, but is outside the scope of this guide.  Please refer to the Godot Rust docs for more information.




## Improvements

### Lag

Every read and write causes the game to lag while it waits for a response from the RPC node.  Performance would be much better if transactions were sent by a separate thread, and if their outcomes were transmitted back to the main thread using a Signal or some other means.  Currently, I estimate the time it will take for a transaction to confirm, then have the game periodically check the blockchain until it observes a state change.  Advice on this front would be much appreciated.

### Receipts

Ethers-rs transactions produce a receipt containing useful information like the transaction hash.  However, my current implementation just unwraps the expected result of the transaction.  It instead could be helpful to handle the receipt in a way the game can use, such as linking to a block explorer to look up the transaction hash.

### Confirmations

While invisible frictionless transactions have their appeal, you may want to ask the player to confirm a transaction before executing it, just as you would with a web wallet.  Gas spikes are of particular concern, and it could be wise to have your game check for abnormally high gas estimates and warn the player if a transaction would be more expensive than usual.

### RPC Nodes

Certainly this is a long-range goal, but games in the future could contain embedded light clients that give the player a more direct connection to the blockchain, instead of needing to rely on an RPC node.  In the meantime, you may wish to give the player an in-game option to change the RPC they use, or hardcode a fallback RPC if the main one isn't operational.




## Smart Contracts and Game Design

### Overview

A smart contract is a modular, on-chain program that runs on demand.  The chief benefits of a smart contract are its shared, immutable state (serverless sharing) and its immutable rules (serverless validation).

In the context of EVM (Ethereum Virtual Machine) blockchains, smart contracts are typically written in the Solidity programming language.

It is highly recommended that you not only read the documentation, but read about the many spectacular failures that have occurred over time, so that you may avoid making the same mistakes.

Once written, smart contracts are deployed on-chain, where their functions can be called by anyone who has permissions to call them.  All characteristics of a contract — its variables, its functions, its permissions — are fixed at the moment of deployment, and cannot be changed unless the contract has been coded to allow specific changes.

There are certain patterns, such as the Diamond pattern and Proxy pattern, that allow for post-deployment changes, with the cost of eroding the previously-stated benefits, as such contracts are no longer fully immutable.  Such contracts often keep their core logic immutable, to prevent tampering, or rely on a multisignature security mechanism that prevents changes unless a majority of trusted signers agree to the change.

Some contracts also contain safety features, such as a developer-controlled pause function, to temporarily shut down operations if an exploit is detected.

Contracts intended for production need to be heavily tested and audited before they are deployed on mainnet.



### Don't Trust the Player

Competitive multiplayer games are designed with the expectation that players will try to cheat.  A game server maintains its own version of the game's state, only accepts player inputs, and is programmed to detect and reject faulty inputs.  Players who successfully circumvent these protections are able to trick the server and achieve a game state that should not be possible.

Players can also gain an unfair advantage by reading information from the server that their game client otherwise tries to hide from them, such as the location and status of other players.

Imagine the blockchain environment as one massive multiplayer game, and always assume that there are players looking to break the game.  Always assume an adversarial mindset when drafting your smart contracts.  How might your contract be gamed by a bot, or cleverly exploited?  What requirements and restrictions can you impose to protect your game's mechanics?  How exposed is your contract to trust assumptions, and how can you eliminate them?



### Keep Contracts Simple

Also be aware of the computational power of the chain.   In the familiar server model, the server's owner bears the cost of computation.  On a blockchain, the user must use gas to pay for computation on demand.

Each block can perform simple validations and record modest amounts of data, they are not intended for heavy computation or data ingestion.  Ignoring this rule will make your contract unusable, due to the extreme expense of interacting with it.  



### Keeping Secrets

Always know that anything you put on-chain is public, permanently, and cannot be erased from the chain's history.  Do not put information on-chain that should be secret (such as a player's position, in a competitive game).  There are certain techniques you can use to obscure secret information, such as the commit-reveal technique, where a player puts a hash on-chain and later validates the hash to prove it was made using certain values.


### Areas of Interest


The following things are outside the scope of this guide, but are of personal interest for their potential application in games:

* The use of zero knowledge proofs to prove the player has obtained some kind of secret information (such as the answer to a puzzle) without revealing what that information is.  The player can pass this proof to an on-chain prover, and cause a state change if their proof is valid.  There are ZKP crates + circom proofs

* Passing secrets to a specific individual by encrypting the secret using their public key.  That person will be able to decrypt the secret using their private key.  To do this, you would need to use high level encryption crates like openSSL and ECDSA


* use of oracles
to trustlessly execute code too complex for the blockchain (or containing secret information)


* And finally,
homomorphic encryption
a way of performing operations directly on secret values
without revealing what those values are




## Testing

You can use a webwallet like Metamask and a browser IDE like Remix to quickly deploy and test contracts of your own.  Hardhat, Brownie, and Truffle are also available for deploying and testing.  Remember to keep your developer key separate from your other keys, and never use it for anything other than testing.



