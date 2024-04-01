// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// @audit change this to import {}
import "./utils/Ownable.sol";
import "./JellyToken.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeCast} from "./vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";
import {IStakingRewardDistribution} from "./interfaces/IStakingRewardDistribution.sol";
// i check this library
import {SD59x18, convert, exp, mul, div, sd, intoUint256} from "./vendor/prb/math/v0.4.1/SD59x18.sol";
import "forge-std/console.sol";

/**
 * @title Minter
 *s
 * @notice mint jelly tokens
 */
contract Minter is Ownable, ReentrancyGuard {
    // @audit does weight fit into uint96? // done
    struct Beneficiary {
        address beneficiary;
        uint256 weight; //BPS
    }
    // @audit storage is BAD // done
    // @audit naming convention is BAD, don't use underscores // done
    address public _jellyToken; // change this to immutable variable, no need to waste storage // done
    uint256 public _mintingStartedTimestamp;
    address public _stakingRewardsContract; // i has setter
    uint256 public _lastMintedTimestamp;
    uint256 public _mintingPeriod = 7 days; // i has setter

    bool public _started;

    Beneficiary[] public _beneficiaries;
    // i put theese below struct
    int256 constant K = -15;
    uint256 constant DECIMALS = 1e18;

    // i merge these two modifiers into one with input parameter
    // e.g.
    // modifier onlyStarted(bool started) {}
    modifier onlyStarted() {
        if (_started == false) {
            revert Minter_MintingNotStarted();
        }
        _;
    }

    modifier onlyNotStarted() {
        if (_started == true) {
            revert Minter_MintingAlreadyStarted();
        }
        _;
    }

    event MintingStarted(
        address indexed sender,
        uint256 indexed startTimestamp
    );

    event MintingPeriodSet(
        address indexed sender,
        uint256 indexed mintingPeriod
    );

    event StakingRewardsContractSet(
        address indexed sender,
        address indexed stakingRewardsContract
    );

    event JellyMinted(
        address indexed sender,
        address stakingRewardsContract,
        uint256 newLastMintedTimestamp,
        uint256 mintingPeriod,
        uint256 mintedAmount,
        uint256 indexed epochId
    );

    event BeneficiariesChanged();

    error Minter_MintingNotStarted();
    error Minter_MintingAlreadyStarted();
    error Minter_MintTooSoon();

    constructor(
        address jellyToken_,
        address stakingRewardsContract_,
        address newOwner_,
        address pendingOwner_
    ) Ownable(newOwner_, pendingOwner_) {
        // @audit input validation
        _jellyToken = jellyToken_;
        _stakingRewardsContract = stakingRewardsContract_;
    }

    /**
     * @notice Starts minting process for jelly tokens, and sets last minted timestamp so that minting can start immediately
     */
    // q: what is the purpose of this function? why not just start minting when contract is deployed?
    function startMinting() external onlyOwner onlyNotStarted {
        _started = true;
        _lastMintedTimestamp = block.timestamp - _mintingPeriod;
        _mintingStartedTimestamp = block.timestamp;

        emit MintingStarted(msg.sender, block.timestamp);
    }

    /**
     * @notice Mint new tokens based on exponential function, callable by anyone
     */
    function mint() external onlyStarted nonReentrant {
        uint256 mintingPeriod = _mintingPeriod;
        uint256 currentTimestamp = block.timestamp;
        uint256 secondsSinceLastMint = currentTimestamp - _lastMintedTimestamp;

        if (secondsSinceLastMint < mintingPeriod) {
            revert Minter_MintTooSoon();
        }

        _lastMintedTimestamp += mintingPeriod; // q: why not just set it to currentTimestamp?
        int256 daysSinceMintingStarted = int256(
            (block.timestamp - _mintingStartedTimestamp) / 1 days
        );
        uint256 mintAmount = this.calculateMintAmount(daysSinceMintingStarted); // @audit weird syntax, change visibility to public // done
        uint256 mintAmountWithDecimals = mintAmount * DECIMALS;

        uint256 epochId;

        for (uint16 i = 0; i < _beneficiaries.length; i++) {
            uint256 weight = _beneficiaries[i].weight; // @audit linter/formatter
            uint256 amount = (mintAmount * DECIMALS * weight) / 1000; //check to see why stack too deep
            console.log(amount); // @audit use mintAmountWithDecimals instead of mintAmount // done
            // q what / 1000 means? what is weight?

            if (_beneficiaries[i].beneficiary == _stakingRewardsContract) {
                JellyToken(_jellyToken).mint(address(this), amount);
                JellyToken(_jellyToken).approve(
                    _stakingRewardsContract,
                    amount
                );
                epochId = IStakingRewardDistribution(_stakingRewardsContract)
                    .deposit(IERC20(_jellyToken), amount);
            } else {
                JellyToken(_jellyToken).mint(
                    _beneficiaries[i].beneficiary,
                    amount
                );
            }
        }

        emit JellyMinted(
            msg.sender,
            _stakingRewardsContract,
            _lastMintedTimestamp,
            mintingPeriod,
            mintAmountWithDecimals,
            epochId
        );
    }

    /**
     * @notice Calculate mint amount based on exponential function
     *
     * @param daysSinceMintingStarted - number of days since minting started
     *
     * @return mintAmount - amount of tokens to mint
     */
    function calculateMintAmount(
        int256 daysSinceMintingStarted
    ) external pure returns (uint256) {
        // 900_000 * e ^ (-0.0015 * n)
        SD59x18 exponentMultiplier = div(convert(K), convert(10000));
        SD59x18 exponent = mul(
            exponentMultiplier,
            convert(daysSinceMintingStarted)
        );
        // exponent = -0.0015 * n where n is daysSinceMintingStarted
        uint256 mintAmount = intoUint256(mul(exp(exponent), sd(900_000)));

        return mintAmount;
    }

    /**
     * @notice Set new Staking Rewards Distribution Contract
     *
     * @dev Only owner can call.
     *
     * @param newStakingRewardsContract_ new staking rewards distribution contract
     */
    function setStakingRewardsContract(
        address newStakingRewardsContract_
    ) external onlyOwner {
        // @audit input validation
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
        // @audit input validation, weird syntax..
        _mintingPeriod = mintingPeriod_;

        emit MintingPeriodSet(msg.sender, mintingPeriod_);
    }

    /**
     * @notice Store array of beneficiaries to storage
     *
     * @dev Only owner can call.
     *
     * @param beneficiaries_ to store
     */
    /*
    // @audit doesn't compile without viaIR, change the way how array is copied from memory to storage
    // @audit missing input validation on beneficiaries_, which could lead to ddos if beneficiaries_.address is set to 0
    //        also make sure to validate that weight is between 0 and 1000
    function setBeneficiaries(
        Beneficiary[] memory beneficiaries_
    ) external onlyOwner {
        delete _beneficiaries;

        _beneficiaries = beneficiaries_;

        emit BeneficiariesChanged();
    }
    */
}
