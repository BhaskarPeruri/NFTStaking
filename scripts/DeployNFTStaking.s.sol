// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {Script} from "forge-std/Script.sol";
import {Test,console} from "forge-std/Test.sol";
import "../src/core/NFTStaking.sol";
import "../src/core/NFTStakingProxy.sol";
import "../src/mocks/MockNFT.sol";

contract DeployNFTStaking is Script {
    function run() external {
       
        vm.startBroadcast( vm.envUint("PRIVATE_KEY"));

        RewardToken rewardToken = new RewardToken();
        MockNFT mockNFT = new MockNFT();
        NFTStaking nftStakingImplementation = new NFTStaking();

        bytes memory initData = abi.encodeWithSelector(
            NFTStaking.initialize.selector,
            address(mockNFT),
            address(rewardToken),
            1 ether, 
            1 days, 
            1 hours 
        );


        NFTStakingProxy proxy = new NFTStakingProxy(
            address(nftStakingImplementation),
            initData
        );

        NFTStaking nftStaking = NFTStaking(address(proxy));
        rewardToken.mint(address(nftStaking), 1_000_000 ether);

        vm.stopBroadcast();

        console.log("RewardToken deployed at:", address(rewardToken));
        console.log("MockNFT deployed at:", address(mockNFT));
        console.log("NFTStaking implementation deployed at:", address(nftStakingImplementation));
        console.log("NFTStakingProxy deployed at:", address(proxy));
        console.log("NFTStaking (through proxy) deployed at:", address(nftStaking));
    }
}

