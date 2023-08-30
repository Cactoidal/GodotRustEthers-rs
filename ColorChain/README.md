## ColorChain: Example Godot Rust + Ethers-rs Project

To try it, clone this repository, then compile the Rust library.  Drag the compiled library out of target/debug into the main ColorChain folder, import it into the game by [following these steps](https://github.com/Cactoidal/GodotRustEthers-rs/tree/main#6), then run the game.

Copy the address that is generated for you, and mine 0.05 sepETH from the [Sepolia PoW faucet](https://sepolia-faucet.pk910.de/).  This may take around 20 minutes.  I picked this faucet because it is permissionless.  To combat bots, most other faucets require some kind of social proof, such as a Twitter or Discord account, or a web wallet.  You can read more about [how the faucet works here](https://github.com/pk910/PoWFaucet/wiki). Once you have gas, choose a color for the cube and submit the transaction.

The cube's color will change to whichever color has been submitted.  Because every copy of this sample game uses the same smart contract, every player will see the same cube, and other players will see the color you picked (and can overwrite the color if they wish!)

<img width="1021" alt="colorchain" src="https://github.com/Cactoidal/GodotRustEthers-rs/assets/115384394/f86efbdc-798f-4145-8905-bb57536152aa">
