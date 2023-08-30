# GDNative Implementation of Ethers-rs

**This guide is written for Godot 3.5.**  

A guide for Godot 4+ could potentially be written in the future, once I have a better understanding of GDExtension.

In this guide, you will learn how to create and use a [Godot Rust](https://github.com/godot-rust/gdnative) library, how to implement blockchain and smart contract interaction in your game using [Ethers-rs](https://github.com/gakonst/ethers-rs), and you will compile a Godot project where players can change the color of a shared mesh using an on-chain transaction.

If you are already familiar with Godot Rust and just want to try the example project, [jump to the ColorChain section](https://github.com/Cactoidal/GodotRustEthers-rs/tree/main/ColorChain).

The example in this guide uses a [pre-deployed smart contract](https://github.com/Cactoidal/GodotRustEthers-rs/blob/main/ColorChain.sol).  If you are new to smart contracts and want a brief overview of what they are, or if you are interested in design considerations when creating them for use in games, please refer to [the section at the end of this guide](https://github.com/Cactoidal/GodotRustEthers-rs/tree/main#smart-contracts-and-game-design).


### WARNING:
**As with any game engine, Godot has OS-level functions, and you should not download games from sources you do not trust.  This is especially true when combining crypto with games, as crypto security can be easily compromised by malicious programs.  Business involving personal custody of funds and valuables should be conducted on a secure device devoted to that purpose, not on a computer used for playing games.**

### WARNING:
**This guide was created for educational purposes, for use in experimentation, game jams, and hackathons.  The process described here has not been independently audited, may eventually become out-of-date, and should not be used in production without thorough examination of the underlying mechanisms.  Use at your own risk.**


## Setting up Godot Rust

I strongly recommend referring to the [Godot Rust documentation](https://godot-rust.github.io/book/gdnative/intro/setup.html).

To reiterate,

1) [Download](https://godotengine.org/download/3.x) or [compile](https://github.com/godotengine/godot/releases/tag/3.5.2-stable) Godot 3.5.

2) Download [Rust](https://rustup.rs/) and [LLVM](https://releases.llvm.org/) (and [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) if using Windows)

3) Create the library for your project.  From the terminal:

```cargo init --lib project-name-lib```

4) Set up cargo.toml.


```
[lib]
crate-type = ["cdylib"]

[dependencies]
gdnative = { version = "0.11", features = ["async"] }
ethers = "2.0.4"
ethers-contract = "2.0.4"
tokio = { version = "1.28.1", features = ["full"] }
serde = "1.0.163"
serde_json = "1.0.96"
futures = "0.3.28"
```


Useful utilities you may wish to add:

```
hex = "0.4.3"
openssl = "0.10.52"
```

5. Set up lib.rs by declaring classes and their methods, then initialize.  Because we're using tokio to handle the async nature of Ethers-rs, you will also need to create a pool for executing tasks, [as is helpfully described in the Godot Rust docs](https://godot-rust.github.io/book/gdnative/recipes/async-tokio.html).

```
use gdnative::{prelude::*, core_types::ToVariant};
use ethers::{core::{abi::{struct_def::StructFieldType, AbiEncode}, types::*}, signers::*, providers::*, prelude::SignerMiddleware};
use ethers_contract::{abigen};
use std::{convert::TryFrom, sync::Arc};
use tokio::runtime::{Builder, Runtime};
use tokio::task::LocalSet;
use tokio::macros::support::{Pin, Poll};
use futures::Future;
use serde_json::json;

thread_local! {
    static EXECUTOR: &'static SharedLocalPool = {
        Box::leak(Box::new(SharedLocalPool::default()))
    };
}

#[derive(Default)]
struct SharedLocalPool {
    local_set: LocalSet,
}

impl futures::task::LocalSpawn for SharedLocalPool {
    fn spawn_local_obj(
        &self,
        future: futures::task::LocalFutureObj<'static, ()>,
    ) -> Result<(), futures::task::SpawnError> {
        self.local_set.spawn_local(future);

        Ok(())
    }
}


fn init(handle: InitHandle) {
	gdnative::tasks::register_runtime(&handle);
	gdnative::tasks::set_executor(EXECUTOR.with(|e| *e));

    	handle.add_class::<ColorChain>();
}

#[derive(NativeClass, Debug, ToVariant, FromVariant)]
#[inherit(Node)]
struct ColorChain;

#[methods]
impl ColorChain {
    fn new(_owner: &Node) -> Self {
        ColorChain
    }

//#[method] goes here


}

godot_init!(init);
```
### 6. 
Once you've written your library, compile it with `cargo build`.  You'll find the compiled Rust library file in target/debug (.dylib for Mac, .dll for Windows, and .so for Linux).  Drag it into your Godot project's main folder, then import it into Godot with the following steps:

* Create a GDNative library resource, and link it to your compiled Rust library file under the target system.

<p align="center">
<img width="1157" alt="create gdnlib" src="https://github.com/Cactoidal/GodotRustEthers-rs/assets/115384394/3e5f17b6-5c36-4da0-af64-1d5d87db604f">
</p>

<p align="center">
<i>Make sure to save the resource with the .gdnlib extension.</i>
</p>


* Create a GDNative script, and link it to a class defined in your Rust library.

<p align="center">
<img width="362" alt="create nativescript" src="https://github.com/Cactoidal/GodotRustEthers-rs/assets/115384394/1f8e5ab3-0901-49c5-882f-87f80471988e">
</p>

<p align="center">
<i>The Class Name needs to match the name of the class you defined in your compiled Rust library.</i>
</p>

* Now link the script to the .gdnlib resource.

<p align="center">
<img width="289" alt="set library" src="https://github.com/Cactoidal/GodotRustEthers-rs/assets/115384394/058e9560-c018-454f-a1e0-bb350a758951">
</p>

<p align="center">
<i>Under Library, load the .gdnlib resource.</i>
</p>

* Now go to Autoload in Project Settings, and enable the GDNative (.gdns) script you just created.

<p align="center">
<img width="893" alt="set autoload" src="https://github.com/Cactoidal/GodotRustEthers-rs/assets/115384394/acb0946d-9cda-4129-b653-7da532ad19cb">
</p>

<p align="center">
<i>You will probably need to quit and relaunch the Godot editor for this change to take effect.</i>
</p>

7. You can now call your Godot Rust library from anywhere by using the name of the class and the name of the method you want to call.  For example:

```
func refresh_balance():
	ColorChain.get_balance(user_address, sepolia_rpc, self)
```

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

Ethers-rs can instantiate a wallet from an array of 32 bytes.  By reading the bytes as a buffer from the keystore file, and passing the buffer as a PoolArray<u8> to our Godot Rust library, the game can perform blockchain operations:

```
func get_address():
	var file = File.new()
	file.open("user://keystore", File.READ)
	var content = file.get_buffer(32)
	user_address = ColorChain.get_address(content)
	file.close()
```



## Interacting with Blockchains

Ethers-rs is capable of many things, and I invite you to [read the documentation](https://docs.rs/ethers/latest/ethers/) to learn more about what you can do.  First, I'll go over some basic functions, such as retrieving the player's address and gas balance.

Most Ethers-rs function calls will involve instantiating the wallet from the private key, setting up the connection to an RPC node, performing some kind of operation, then reporting the result back to gdscript.

To update variables on the gdscript side, Rust async functions need to "call back" into Godot, which is accomplished by telling the Godot Rust library which kind of node it will be calling to, and which function it will call.  That function call is executed within a Rust-unsafe block.

Much of your effort will involve converting between Godot's data types and Ethers' data types.  This will require some experimentation on your part, as Godot has trouble passing large unsigned integers, and sometimes the blockchain will give you values in hex that you will need to decode.  EVM blockchains also cannot handle decimals, you will need to convert decimal values into whole numbers, then convert back to decimal once the blockchain operation has been completed.

It is easiest to pass u64 and strings into Rust, and easiest to pass strings back into gdscript.


```
#[method]
fn get_address(key: PoolArray<u8>) -> GodotString {

let vec = &key.to_vec();

let keyset = &vec[..]; 
 
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();

let wallet: LocalWallet = prewallet.with_chain_id(Chain::Sepolia);

let address = wallet.address();

let address_string = address.encode_hex();

let key_slice = match address_string.char_indices().nth(*&0 as usize) {
    Some((_pos, _)) => (&address_string[26..]).to_string(),
    None => "".to_string(),
    };

let return_string: GodotString = format!("0x{}", key_slice).into();

return_string

}

#[method]
#[tokio::main]
async fn get_balance(user_address: GodotString, rpc: GodotString, ui_node: Ref<Control>) -> NewFuture {

let preaddress: &str = &user_address.to_string();

let address: Address = preaddress.parse().unwrap();

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

let balance = &provider.get_balance(address, None).await.unwrap().as_u128().to_string().to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("set_balance", &[balance.clone()])
};

NewFuture(Ok(()))
}
```


Note that you can use Ethers-rs to interact with any EVM chain, simply by passing the chain ID and an RPC node URL.



## Smart Contracts

You can interact with a specific smart contract by providing its ABI to your Godot Rust library.  The `abigen!` macro is the easiest way to do this, which simply takes an ABI.json and creates a contract object your library can interact with:

```
abigen!(
    ChainColorABI,
    "./ColorChain.json",
    event_derives(serde::Deserialize, serde::Serialize)
);
```

Read and write functions are very similar in setup, but have outcomes that need to be handled differently.  In both cases, you will need to instantiate the player's wallet, select the appropriate chain and provide an RPC URL, create the contract object, convert any parameters from Godot types into Ethers types, then call the smart contract function using its name and parameters listed in the ABI.  

On the gdscript side, it's important to set up error handling, because transactions do fail, due to RPC node downtime, lack of gas, invalid input, and so on.


### Reading

To "call back" into gdscript, you will need to convert the value's data type into a Variant.

For structs, you will need to first turn the struct into a JSON string using the `json!` macro, then pass the JSON as a Variant.  From gdscript you can then use the parse_json() function to get usable values.

```
#[method]
#[tokio::main]
async fn get_color(key: PoolArray<u8>, chain_id: u64, chain_color_address: GodotString, rpc: GodotString, ui_node: Ref<Control>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 

let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(chain_id);

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

let contract_address: Address = chain_color_address.to_string().parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainColorABI::new(contract_address.clone(), Arc::new(client.clone()));

let prequery = contract.get_color().call().await.unwrap();

let query = json!({
    "r": prequery.r,
    "g": prequery.g,
    "b": prequery.b
});

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("set_color", &[query.to_string().to_variant()])
};

NewFuture(Ok(()))

}
```

Sometimes you will need to convert from hex into the desired value.  For example, once you have your parsed JSON in gdscript, you can use the hex_to_int() function to convert uint256 values into a usable form.


### Writing

Please note that you will need gas to send write transactions.  Testnet gas is available from faucets, such as the [Sepolia PoW faucet](https://sepolia-faucet.pk910.de).  Writing to the chain is otherwise straightforward, just pass the necessary parameters and call the smart contract function.

```
#[method]
#[tokio::main]
async fn send_color(key: PoolArray<u8>, chain_id: u64, chain_color_contract: GodotString, rpc: GodotString, _r: u8, _g: u8, _b: u8) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();

let wallet: LocalWallet = prewallet.with_chain_id(chain_id);

let provider = Provider::<Http>::try_from(rpc.to_string()).expect("could not instantiate HTTP Provider");

let contract_address: Address = chain_color_contract.to_string().parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainColorABI::new(contract_address.clone(), Arc::new(client.clone()));

let tx = contract.set_color(_r.into(), _g.into(), _b.into()).send().await.unwrap().await.unwrap();

NewFuture(Ok(()))

}
```






## ColorChain - a sample implementation:

<img width="1021" alt="colorchain" src="https://github.com/Cactoidal/GodotRustEthers-rs/assets/115384394/52aab5b0-c7a0-4555-be55-168dcd5a3674">

I've provided a small project as an example.  To use it, [clone the ColorChain folder](https://github.com/Cactoidal/GodotRustEthers-rs/tree/main/ColorChain), then compile the Rust library.  Drag the compiled library out of target/debug into the main ColorChain folder, import it into the game by [following the steps above](https://github.com/Cactoidal/GodotRustEthers-rs/tree/main#6), then run the game.

Copy the address that is generated for you, mine some gas from the [Sepolia PoW faucet](https://sepolia-faucet.pk910.de/) (this may take around 10 minutes), then choose a color for the cube and submit the transaction.

The cube's color will change to whichever color has been submitted.  Because every copy of this sample game uses the same smart contract, every player will see the same cube, and other players will see the color you picked (and can overwrite the color if they wish!)




## Exporting the Project

When exporting your game, you will need to compile the Godot Rust library for the target system.  This is most easily achieved by compiling on the target system itself.  Cross-compilation is also possible, but is outside the scope of this guide.  Please refer to the Godot Rust docs for more information.




## Improvements

### Lag

Every read and write causes the game to lag while it waits for a response from the RPC node.  Performance would be much better if transactions did not block the main thread, and if their outcomes were transmitted back to the main thread using a Signal or some other means.  Currently, I estimate the time it will take for a transaction to confirm, then have the game periodically check the blockchain until it observes a state change.  Advice on this front would be much appreciated.

### Receipts

Ethers-rs transactions produce a receipt containing useful information like the transaction hash.  However, my current implementation just unwraps the expected result of the transaction.  It instead could be helpful to handle the receipt in a way the game can use, such as linking to a block explorer to look up the transaction hash.

### Confirmations

While invisible frictionless transactions have their appeal, you may want to ask the player to confirm a transaction before executing it, just as you would with a web wallet.  Gas spikes are of particular concern, and it could be wise to have your game check for abnormally high gas estimates and warn the player if a transaction would be more expensive than usual.

### RPC Nodes

Certainly this is a long-range goal, but games in the future could contain embedded light clients that give the player a more direct connection to the blockchain, instead of needing to rely on an RPC node.  In the meantime, you may wish to give the player an in-game option to change the RPC they use, or hardcode a fallback RPC if the main one isn't operational.




## Smart Contracts and Game Design

### Overview

A smart contract is a modular, on-chain program that runs on demand.  The chief benefits of a smart contract are its shared, immutable state (serverless sharing) and its immutable rules (serverless validation).

In the context of EVM (Ethereum Virtual Machine) blockchains, smart contracts are typically written in the [Solidity programming language](https://docs.soliditylang.org/en/v0.8.21/).

It is highly recommended that you not only [read the documentation](https://docs.soliditylang.org/en/v0.8.21/), but read about the many spectacular failures that have occurred over time, so that you may avoid making the same mistakes.

Once written, smart contracts are deployed on-chain, where their functions can be called by anyone who has permissions to call them.  All characteristics of a contract — its variables, its functions, its permissions — are fixed at the moment of deployment, and cannot be changed unless the contract has been coded to allow specific changes.

There are certain patterns, such as the [Diamond pattern](https://www.quicknode.com/guides/ethereum-development/smart-contracts/the-diamond-standard-eip-2535-explained-part-1) and [Proxy patterns](https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies), that allow for post-deployment changes, with the cost of eroding the previously-stated benefits, as such contracts are no longer fully immutable.  Such contracts often keep their _core logic_ immutable, to prevent tampering, or rely on a multisignature security mechanism that prevents changes unless a majority of trusted signers agree to the change.

Some contracts also contain safety features, such as a developer-controlled pause function, to temporarily shut down operations if an exploit is detected.

Contracts intended for production need to be heavily tested and audited before they are deployed on mainnet.



### Don't Trust the Player

Competitive multiplayer games are designed with the expectation that players will try to cheat.  A game server maintains its own version of the game's state, only accepts player inputs, and is programmed to detect and reject faulty inputs.  Players who successfully circumvent these protections are able to trick the server and achieve a game state that should not be possible.

Players can also gain an unfair advantage by reading information from the server that their game client otherwise tries to hide from them, such as the location and status of other players.

Imagine the blockchain environment as one massive multiplayer game, and always assume that there are players looking to break the game.  Always assume an adversarial mindset when drafting your smart contracts.  How might your contract be gamed by a bot, or cleverly exploited?  What requirements and restrictions can you impose to protect your game's mechanics?  How exposed is your contract to trust assumptions, and how can you eliminate them?

### Don't Trust Local Validation

Likewise, you cannot rely on your game application to protect your smart contract.  Your game can be coded to _help_ players format complex transactions, manage data between sessions, and protect players from submitting the wrong values by mistake, but your smart contract should not be coded to fully trust the output of your game.

Players could modify the code of their copy of the game, and get it to do things you did not intend, such as submitting faulty inputs to your contract.  Contracts are also public, which means that someone can submit values to your contract without actually using your game application.  Make sure your contract is coded to only accept the ranges of values that you want, and that your functions are only usable in the context that you intend.

In addition, do not put secrets in your Godot code, as these can be easily extracted.  



### Keep Contracts Simple

Also be aware of the computational power of the chain.   In the familiar server model, the server's owner bears the cost of computation.  On a blockchain, the user must use gas to pay for computation on demand.

Each block can perform simple validations and record modest amounts of data, they are not intended for heavy computation or data ingestion.  Ignoring this rule will make your contract unusable, due to the extreme expense of interacting with it.  



### Be Very Careful with Secrets

Always know that anything you put on-chain is public, permanently, and cannot be erased from the chain's history.  Do not put information on-chain that should be secret (such as a player's position, in a competitive game).  There are certain techniques you can use to obscure secret information, such as the commit-reveal technique, where a player puts a hash on-chain and later validates the hash to prove it was made using certain values.


## Testing

You can use a webwallet like [Metamask](https://metamask.io) and a browser IDE like [Remix](https://remix.ethereum.org) to quickly deploy and test contracts of your own.  [Hardhat](https://github.com/NomicFoundation/hardhat), [Brownie](https://github.com/eth-brownie/brownie), and [Truffle](https://trufflesuite.com) are also available for deploying and testing.  Remember to keep your developer key separate from your other keys, and never use it for anything other than testing.



## Areas of Interest


The following things are outside the scope of this guide, but are of personal interest for their potential application in games, and could be subjects of further experimentation:

* The use of zero knowledge proofs to prove the player has obtained some kind of secret information (such as the answer to a puzzle) without revealing what that information is.  The player can pass this proof to an on-chain prover, and cause a state change if their proof is valid.  [Zokrates](https://github.com/Zokrates/ZoKrates) and [Arkworks](https://github.com/arkworks-rs/) are two experimental Rust projects used for generating ZKP circuits, while [circom](https://docs.circom.io) is a lower level circuit generating language with a compiler written in Rust.

* Passing secrets to a specific individual by encrypting the secret using their public key.  That person will be able to decrypt the secret using their private key.  To do this, you could use encryption crates like [openssl](https://github.com/sfackler/rust-openssl) and [secp256k1](https://docs.rs/secp256k1/latest/secp256k1/) to generate a shared secret.

* The use of oracles to trustlessly execute code too complex and expensive for the blockchain (or which contains secret information), and the use of distributed databases to trustlessly store large amounts of game data.

* And finally, homomorphic encryption, a way of performing operations directly on secret values without revealing what those values are.  There exist a few experimental crates that can do this.
