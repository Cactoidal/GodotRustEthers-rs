## ColorChain: Example Godot Rust + Ethers-rs Project

To try it, clone this repository, then compile the Rust library.  Drag the compiled library out of target/debug into the main ColorChain folder, import it into the game by [following these steps](https://github.com/Cactoidal/GodotRustEthers-rs/tree/main#6), then run the game.

Copy the address that is generated for you, mine some gas from the Sepolia PoW faucet (this may take around 10 minutes), then choose a color for the cube and submit the transaction.

The cube's color will change to whichever color has been submitted.  Because every copy of this sample game uses the same smart contract, every player will see the same cube, and other players will see the color you picked (and can overwrite the color if they wish!)
