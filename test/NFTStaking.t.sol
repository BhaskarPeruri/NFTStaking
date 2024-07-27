// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test,console} from "forge-std/Test.sol";
import {NFTStaking}  from "../src/core/NFTStaking.sol";
import{MockNFT} from "../src/mocks/MockNFT.sol";
import{RewardToken} from "../src/core/Rewardtoken.sol";
import {NFTStakingProxy} from "../src/core/NFTStakingProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract StakingTest is Test{

    NFTStaking public nftStaking;
    NFTStaking public nftStakingImplementation;
    NFTStakingProxy public proxy;
    RewardToken public rewardToken;
    MockNFT public nftContract;

    address public owner;
    address public user1;
    address public user2;
    address user3 = address(0x03);

    function setUp() external {

        nftStakingImplementation = new NFTStaking();
        rewardToken = new RewardToken();
        nftContract = new MockNFT();

        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        bytes memory initData = abi.encodeWithSelector(
            nftStaking.initialize.selector,
            address(nftContract),
            address(rewardToken),
            1 ether, // 1 token per second
            1 days, // 1 day unbonding period
            1 hours  // 1 hour claim delay 
        );

        proxy = new NFTStakingProxy(address(nftStakingImplementation), initData);
        nftStaking = NFTStaking(address(proxy));

        // Mint reward tokens to staking contract
        rewardToken.mint(address(nftStaking),1_000_000 ether );


        //Mint NFTs to users
        nftContract.mint(user1, 1);
        nftContract.mint(user1, 2);
        nftContract.mint(user2, 3);

        //Approve by users for transferring NFT's to staking contract
        vm.prank(user1);
        nftContract.setApprovalForAll(address(nftStaking), true); 
        vm.prank(user2);
        nftContract.setApprovalForAll(address(nftStaking), true); 

    }

    function testNoOneCanInitialize() public{
        vm.prank(owner);
        vm.expectRevert();
        nftStaking.initialize(address(0x04), address(0x05), 1 ether, 1 days, 1 hours);

        vm.prank(user1);
        vm.expectRevert();
        nftStaking.initialize(address(0x04), address(0x05), 1 ether, 1 days, 1 hours);
    }

    function testStake() public{
        uint256[] memory user1tokenIds = new uint256[](2);
        user1tokenIds[0] = 1;
        user1tokenIds[1] = 2;

        //user1 staking 
        vm.prank(user1);
        nftStaking.stake(user1tokenIds);

        //user2 staking
        vm.prank(user2);
        uint256[] memory user2tokenIds = new uint256[](1);
        user2tokenIds[0] = 3;
        nftStaking.stake(user2tokenIds);

        assertEq(nftContract.ownerOf(1), address(nftStaking));
        assertEq(nftContract.ownerOf(2), address(nftStaking));
        assertEq(nftContract.ownerOf(3), address(nftStaking));
    }

    function testCannotStakeWithApprovalToStakingContract() public{
        vm.startPrank(owner);
        nftContract.mint(user3, 4);

        assertEq(nftContract.ownerOf(4), user3);

        vm.startPrank(user3);

        uint256[] memory tokenId = new uint256[] (1);
        tokenId[0] = 4;
        vm.expectRevert();
        nftStaking.stake(tokenId);
    }

    function testCannotStakeSameTypeOfTokenIds() public{
        vm.startPrank(user1);
        uint256[] memory tokenId = new uint256[](1);
        tokenId[0] = 1;

        nftStaking.stake(tokenId);

        vm.expectRevert();
        nftStaking.stake(tokenId);

    }

    function testWhenPausedUserUnableToStake() public {
        //staking is paused 
        nftStaking.pause();
        assertTrue(nftStaking.paused());

        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.expectRevert();
        nftStaking.stake(tokenIds);

    }

    function testWhenUnpausedUserAbleToStake() public{
        //staking is paused 
        nftStaking.pause();
        assertTrue(nftStaking.paused());

        vm.startPrank(user1);
        uint256[] memory tokenId = new uint256[](1);
        tokenId[0] = 1;

        vm.expectRevert();
        nftStaking.stake(tokenId);
        vm.stopPrank();

        //staking is unpaused 
        nftStaking.unpause();
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        nftStaking.stake(tokenIds);
        vm.stopPrank();
    }


    function testUnstake() public{
        //to check for unstake we need to stake first
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        vm.prank(user1);
        nftStaking.stake(tokenIds);

        // Unstake NFTs
        uint256[] memory indices = new uint256[](2);
        indices[0] = 0;
        indices[1] = 1;

        vm.prank(user1);
        nftStaking.unstake(indices);

        // Check if NFTs are marked as unstaked
        (,, bool isUnstaked1,) = nftStaking.stakedNFTs(user1, 0);
        (,, bool isUnstaked2,) = nftStaking.stakedNFTs(user1, 1);

        assertTrue(isUnstaked1);
        assertTrue(isUnstaked2);
    }

    function testCannotUnstakeWithoutStake() public{
        vm.startPrank(user3);

        uint256 [] memory indices = new uint256[] (1);
        indices[0] = 1;

        vm.expectRevert();
        nftStaking.unstake(indices);
    }

    function testRevertWhenUnstakedMoreThanOneTime() public{
        uint256[] memory tokenId = new uint256[](1);
        tokenId[0] = 1;

        vm.startPrank(user1);
        nftStaking.stake(tokenId);

        uint256[] memory indices = new uint256[](1);
        indices[0] = 0;

        nftStaking.unstake(indices);  

        vm.expectRevert();
        nftStaking.unstake(indices);  
    }

    
    function testWithdrawUnstakedNFTs() public {
        // Stake an NFT
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(user1);
        nftStaking.stake(tokenIds);

        uint256[] memory indices = new uint256[](1);
        indices[0] = 0;

        // UnStake an NFT        
        nftStaking.unstake(indices);

        // passing unbonding period
        vm.warp(block.timestamp + 1 days);

        // Withdraw unstaked NFT
        nftStaking.withdrawUnstakedNFTs();
        vm.stopPrank();

        // Check if user is the owner of NFT
        assertEq(nftContract.ownerOf(1), user1);
    }

    function testCannotWithdrawUnstakedNTFsBeforeUnstake() public{
        // Stake an NFT
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(user1);
        nftStaking.stake(tokenIds);

        vm.expectRevert();
        nftStaking.withdrawUnstakedNFTs();

    }

    function testCannotWithdrawUnstakedNFTsBeforeUnbondingPeriodCompleted() public{
        // Stake an NFT
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(user1);
        nftStaking.stake(tokenIds);

        uint256[] memory indices = new uint256[](1);
        indices[0] = 0;

        // UnStake an NFT        
        nftStaking.unstake(indices);

        vm.expectRevert();
        nftStaking.withdrawUnstakedNFTs();


    }

    function testCannotWithdrawWithoutStake() public{
        vm.startPrank(user3);
        vm.expectRevert();
        nftStaking.withdrawUnstakedNFTs();

    }

    function testRevertWhenWithdrawnUnStakedNFTsMoreThanOneTime() public {
        // Stake an NFT
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(user1);
        nftStaking.stake(tokenIds);

        uint256[] memory indices = new uint256[](1);
        indices[0] = 0;

        // Stake an NFT        
        nftStaking.unstake(indices);

        // passing unbonding period
        vm.warp(block.timestamp + 1 days);

        // Withdraw unstaked NFT
        nftStaking.withdrawUnstakedNFTs();

        vm.expectRevert();
        nftStaking.withdrawUnstakedNFTs();

        vm.stopPrank();
    }

    function testClaimRewards() public {
        // Stake an NFT
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(user1);
        nftStaking.stake(tokenIds);

        // passing unbonding period
        vm.warp(block.timestamp + 1 days);

        // Claim rewards
        vm.prank(user1);
        nftStaking.claimRewards();

        // Check if rewards were transferred
        assertEq(rewardToken.balanceOf(user1), 1 days * 1 ether);
    }

    function testCannotClaimWithoutStake() public{
        vm.startPrank(user1);
        vm.expectRevert();
        nftStaking.claimRewards();
    }

    function testCannotClaimBeforeClaimDelay() public{
        // Stake an NFT
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.prank(user1);
        nftStaking.stake(tokenIds);

        vm.warp(block.timestamp + 10 seconds);
        vm.expectRevert();
        nftStaking.claimRewards();
    }

    function testCalculateRewardsWhenNFTIsStaked() public{
        uint256[] memory tokenIds = new uint256[] (1);
        tokenIds[0] = 1;
        tokenIds[0] = 2;

        vm.startPrank(user1);
        nftStaking.stake(tokenIds);

        vm.warp(block.timestamp + 2 days);
        nftStaking.claimRewards();

        assertEq(rewardToken.balanceOf(user1), 2 days * 1 ether);
        assertEq(nftStaking.calculateRewards(user1),  2 days * 1 ether);
    }

    function testCalculateRewardsWhenNFTIsUnStaked() public{
        uint256[] memory tokenId = new uint256[] (1);
        tokenId[0] = 1;

        vm.startPrank(user1);
        nftStaking.stake(tokenId);

        vm.warp(block.timestamp + 1 days);

        uint256[] memory index = new uint256[](1);
        index[0] = 0;
        nftStaking.unstake(index);

        nftStaking.claimRewards();

        assertEq(rewardToken.balanceOf(user1), 1 days * 1 ether);
        assertEq(nftStaking.calculateRewards(user1),  1 days * 1 ether);
    }


    function testUpdateRewardRate() public {
        uint256 newRate = 2 ether;
        nftStaking.updateRewardRate(newRate);
        assertEq(nftStaking.rewardRate(), newRate);
    }

    function testUpdateStakingConfiguration() public{
        nftStaking.updateStakingConfiguration(2 days, 2 hours) ;
    }


    function test_authorizeUpgrade() public {
    address newImplementation = address(new NFTStaking());

    // Cast to NFTStaking to call upgradeToAndCall
    NFTStaking(address(proxy)).upgradeToAndCall(newImplementation, "");

    // Use NFTStakingProxy to get the implementation
    address actualImplementation = NFTStakingProxy(payable(address(proxy))).getImplementation();
    
    assertEq(actualImplementation, newImplementation, "Upgrade failed");
}

function testGetImplementation() public view {
    address actualImplementation = NFTStakingProxy(payable(address(proxy))).getImplementation();
    assertEq(actualImplementation, address(nftStakingImplementation), "getImplementation returned incorrect address");
}

}