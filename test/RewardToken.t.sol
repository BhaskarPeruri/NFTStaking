// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import {Test,console} from "forge-std/Test.sol";
import{RewardToken} from "../src/core/RewardToken.sol";


contract RewardTokenTest is Test{

    RewardToken public rewardToken;
    address public owner;
    address public user;

    function setUp() external{

        owner = address(this);
        user = address(0x1);
        rewardToken = new RewardToken();
    }

    function testTokenNameAndSymbol() public{
        assertEq(rewardToken.name(), 'RewardToken');
        assertEq(rewardToken.symbol(), 'RWT');
        assertEq(rewardToken.totalSupply(), 0);
    }

    function testMint() public{
        rewardToken.mint(address(user), 1_000_000);   
        assertEq(rewardToken.balanceOf(user),1_000_000);
        assertEq(rewardToken.totalSupply(), 1_000_000);

    }
    function testUserCannotMint() public{
        vm.prank(user);
        vm.expectRevert();
        rewardToken.mint(address(user), 1_000_000);
    }

    function testOwnership() public {
        assertEq(rewardToken.owner(), owner);
    }


}