// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title NFTStakingProxy
/// @dev This contract serves as a proxy for the NFTStaking contract, implementing the UUPS (Universal Upgradeable Proxy Standard) pattern.
contract NFTStakingProxy is ERC1967Proxy {
    
    /// @dev Constructor to initialize the proxy contract
    /// @param _logic Address of the initial implementation contract
    /// @param _data Calldata to execute in the implementation contract after initialization
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}

    /// @dev Function to retrieve the current implementation address
    /// @return The address of the current implementation contract
    function getImplementation() public view returns (address) {
        return _implementation();
    }
}