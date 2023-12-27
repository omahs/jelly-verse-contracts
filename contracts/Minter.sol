// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./JellyToken.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeCast} from "./vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";

/**
 * @title Minter
 *s
 * @notice mint jelly tokens
 */
contract Minter is Ownable, ReentrancyGuard {
    address public _jellyToken;
    address public _lpRewardsContract;
    address public _stakingRewardsContract;
    uint256 public _lastMintedTimestamp;
    uint256 public _inflationRate;
    uint256 public _mintingPeriod = 7 days;

    event InflationRateSet(
        address indexed sender,
        uint256 indexed inflationRate
    );

    event MintingPeriodSet(
        address indexed sender,
        uint256 indexed mintingPeriod
    );

    event LPRewardsContractSet(
        address indexed sender,
        address indexed lpRewardsContract
    );

    event StakingRewardsContractSet(
        address indexed sender,
        address indexed lpRewardsContract
    );

    event JellyMinted(
        address indexed sender,
        uint256 indexed mintedTimestamp,
        uint256 newLastMintedTimestamp,
        uint256 mintingPeriod,
        uint256 indexed mintedAmount
    );

    error OfficialPoolsRegister_MaxPools10();
    error OfficialPoolsRegister_InvalidPool();

    constructor(
        address jellyToken_,
        address lpRewardsContract_,
        address stakingRewardsContract_,
        address newOwner_,
        address pendingOwner_
    ) Ownable(newOwner_, pendingOwner_) {
        _jellyToken = jellyToken_;
        _lpRewardsContract = lpRewardsContract_;
        _stakingRewardsContract = stakingRewardsContract_;

        _lastMintedTimestamp = block.timestamp;
    }

    /**
     * @notice Mint new tokens based on inflation rate, called by anyone
     */
    function mint() nonReentrant external {
        uint256 mintingPeriod = _mintingPeriod;
        uint256 currentTimestamp = block.timestamp;
        uint256 secondsSinceLastMint = currentTimestamp - _lastMintedTimestamp;
        require(secondsSinceLastMint > mintingPeriod, "Minter: mint too soon");
        
        _lastMintedTimestamp += mintingPeriod;
       
        uint256 mintAmount = _inflationRate * mintingPeriod;

        JellyToken(_jellyToken).mint(_lpRewardsContract, mintAmount / 2);
        JellyToken(_jellyToken).mint(_stakingRewardsContract, mintAmount / 2);

        emit JellyMinted(msg.sender, currentTimestamp, _lastMintedTimestamp, mintingPeriod, mintAmount);
    }

    /**
     * @notice Set new Inflation Rate
     *
     * @dev Only owner can call.
     *
     * @param newInflationRate_ new inflation rate
     */
    function setInflationRate(uint48 newInflationRate_) external onlyOwner {
        _inflationRate = newInflationRate_;

        emit InflationRateSet(msg.sender, newInflationRate_);
    }

    /**
     * @notice Set new LP Rewards Distribution Contract
     *
     * @dev Only owner can call.
     *
     * @param newLpRewardsContract_ new LP rewards distribution contract
     */
    function setLpRewardsContract(address newLpRewardsContract_) external onlyOwner {
        _lpRewardsContract = newLpRewardsContract_;

        emit LPRewardsContractSet(msg.sender, newLpRewardsContract_);
    }

    /**
     * @notice Set new Staking Rewards Distribution Contract
     *
     * @dev Only owner can call.
     *
     * @param newStakingRewardsContract_ new staking rewards distribution contract
     */
    function setStakingRewardsContract(address newStakingRewardsContract_) external onlyOwner {
        _stakingRewardsContract = newStakingRewardsContract_;

        emit StakingRewardsContractSet(msg.sender, newStakingRewardsContract_);
    }

    /**
     * @notice Set new minting period
     *
     * @dev Only owner can call.
     *
     * @param mintingPeriod_ new minitng period
     */
    function setMintingPeriod(uint48 mintingPeriod_) external onlyOwner {
        _mintingPeriod = mintingPeriod_;

        emit MintingPeriodSet(msg.sender, mintingPeriod_);
    }
}
