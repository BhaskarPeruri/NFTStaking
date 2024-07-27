// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './Rewardtoken.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title NFTStaking
/// @dev A contract for staking NFTs and earning ERC20 token rewards
contract NFTStaking is PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {

    IERC721 public nftContract;
    RewardToken private i_rewardToken;

    using SafeERC20 for RewardToken;

    /// @dev Struct to store information about a staked NFT
    struct StakedNFT {
        uint256 tokenId;
        uint256 timestamp;
        bool isUnstaked;
        uint256 unstakeTime;
    }

    //mappings
    mapping(address => StakedNFT[]) public stakedNFTs;
    mapping(address => uint256) public rewardBalances;
    mapping(address => uint256) public lastClaimTime;

    uint256 public rewardRate;
    uint256 public unbondingPeriod;
    uint256 public claimDelay;


    //events
    event NFTStaked(address indexed user, uint256 tokenId);
    event NFTUnstaked(address indexed user, uint256 tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event NFTWithdrawn(address indexed user, uint256 tokenId);

    /// @dev Initializes the contract
    /// @param _nftContract Address of the NFT contract
    /// @param _rewardToken Address of the reward token contract
    /// @param _rewardRate Initial reward rate
    /// @param _unbondingPeriod Initial unbonding period
    /// @param _claimDelay Initial claim delay
    function initialize(
        address _nftContract,
        address _rewardToken,
        uint256 _rewardRate,
        uint256 _unbondingPeriod,
        uint256 _claimDelay
    ) public initializer {
        __Pausable_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        nftContract = IERC721(_nftContract);
        i_rewardToken = RewardToken(_rewardToken);
        rewardRate = _rewardRate;
        unbondingPeriod = _unbondingPeriod;
        claimDelay = _claimDelay;
    }

    /// @dev Allows users to stake multiple NFTs
    /// @param tokenIds Array of token IDs to stake
    function stake(uint256[] memory tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(nftContract.ownerOf(tokenIds[i]) == msg.sender, "Not the owner");
            nftContract.transferFrom(msg.sender, address(this), tokenIds[i]);
            stakedNFTs[msg.sender].push(StakedNFT(tokenIds[i], block.timestamp, false, 0));
            emit NFTStaked(msg.sender, tokenIds[i]);
        }
    }

    /// @dev Allows users to unstake multiple NFTs
    /// @param indices Array of indices in the user's stakedNFTs array to unstake
    function unstake(uint256[] memory indices) external {
        require(stakedNFTs[msg.sender].length > 0, "You haven't staked");
        for (uint256 i = 0; i < indices.length; i++) {
            require(indices[i] < stakedNFTs[msg.sender].length, "Invalid index");
            StakedNFT storage nft = stakedNFTs[msg.sender][indices[i]];
            require(!nft.isUnstaked, "NFT already unstaked");
            nft.isUnstaked = true;
            nft.unstakeTime = block.timestamp;
            emit NFTUnstaked(msg.sender, nft.tokenId);
        }
    }

    /// @dev Allows users to withdraw their unstaked NFTs 
    function withdrawUnstakedNFTs() external {
        StakedNFT[] storage userStakedNFTs = stakedNFTs[msg.sender];
        uint256 length = userStakedNFTs.length;
        
        require(length > 0, "You don't have stakedNFTs");

        for (uint256 i = length; i > 0; i--) {
            StakedNFT storage nft = userStakedNFTs[i - 1];
            require(nft.isUnstaked, "NFT is not unstaked");
            require(block.timestamp >= nft.unstakeTime + unbondingPeriod, "Come again after some time");
            nftContract.safeTransferFrom(address(this), msg.sender, nft.tokenId);
            
            // Remove the NFT from the array by replacing it with the last element and reducing the array length
            userStakedNFTs[i - 1] = userStakedNFTs[length - 1];
            userStakedNFTs.pop();
            
            // Update the length
            length--;
            
            emit NFTWithdrawn(msg.sender, nft.tokenId);
        }
    }

    /// @dev Allows users to claim their accumulated rewards
    function claimRewards() external {
        require(block.timestamp >= lastClaimTime[msg.sender] + claimDelay, "Claim delay not met");
        uint256 reward = calculateRewards(msg.sender);
        require(reward > 0, "No rewards to claim");
        
        rewardBalances[msg.sender] = 0;
        lastClaimTime[msg.sender] = block.timestamp;
        i_rewardToken.safeTransfer(msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
    }

    /// @dev Calculates the rewards for a given user
    /// @param user Address of the user
    /// @return The calculated reward amount
    function calculateRewards(address user) public view returns (uint256) {
        uint256 reward = rewardBalances[user];
        for (uint256 i = 0; i < stakedNFTs[user].length; i++) {
            StakedNFT memory nft = stakedNFTs[user][i];
            if (!nft.isUnstaked) {
                uint256 stakingDuration = block.timestamp - nft.timestamp;
                reward += stakingDuration * rewardRate;
            } else if (block.timestamp < nft.unstakeTime + unbondingPeriod) {
                uint256 stakingDuration = nft.unstakeTime - nft.timestamp;
                reward += stakingDuration * rewardRate;
            }
        }
        return reward;
    }

    /// @dev Allows the owner to update the reward rate
    /// @param newRate The new reward rate
    function updateRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }

    /// @dev Allows the owner to update staking configuration
    /// @param _unbondingPeriod New unbonding period
    /// @param _claimDelay New claim delay
    function updateStakingConfiguration(uint256 _unbondingPeriod, uint256 _claimDelay) external onlyOwner {
        unbondingPeriod = _unbondingPeriod;
        claimDelay = _claimDelay;
    }

    /// @dev Pauses the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract
    /// @param newImplementation Address of the new implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}