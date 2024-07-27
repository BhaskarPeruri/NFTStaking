// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @title RewardToken
/// @dev A simple ERC20 token contract with minting capability, used as a reward token in the NFT staking system
contract RewardToken is ERC20, Ownable {
   
    /// @dev Constructor to initialize the RewardToken
    /// @notice Sets the token name as 'RewardToken' and symbol as 'RWT'
    /// @notice The deployer of the contract becomes the initial owner
    constructor() ERC20('RewardToken', 'RWT') Ownable(msg.sender) {}

    /// @dev Allows the owner to mint new tokens
    /// @param to The address that will receive the minted tokens
    /// @param amount The amount of tokens to mint
    /// @notice This function can only be called by the contract owner
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}