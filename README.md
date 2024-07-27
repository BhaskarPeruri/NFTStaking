
# NFTStaking

## Summary of the Protocol

This protocol allows users to stake their NFTs (Non-Fungible Tokens) and earn ERC20 token rewards over time.

This protocol incentivizes users to stake their NFTs by offering token rewards, while also providing flexibility in staking management and security measures to protect both users and the protocol itself.

For more please refer to [this](https://drive.google.com/file/d/1r3Norn1lS3TLrk4wuWq0Fc5JPRwXIaEV/view?usp=sharing) 


### To install all dependencies
```
make install

```

### To compile all the contracts
```
forge build

```


### To see the tests coverage

```
forge coverage
```


### To deploy on testnet 

```
forge script scripts/DeployNFTStaking.s.sol:DeployNFTStaking --rpc-url $SEPOLIA_RPC_URL --broadcast --legacy

```
#### Note: Make sure to add your configurations in .env file

