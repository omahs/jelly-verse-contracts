// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Ownable} from "./utils/Ownable.sol";
import {IJellyToken} from "./interfaces/IJellyToken.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeCast} from "./vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";
import {IStakingRewardDistribution} from "./interfaces/IStakingRewardDistribution.sol";
import {SD59x18, convert, exp, mul, div, sd, intoUint256} from "./vendor/prb/math/v0.4.1/SD59x18.sol";

/**
 * @title Minter
 *s
 * @notice mint jelly tokens
 */
contract Minter is Ownable, ReentrancyGuard {
    struct Beneficiary {
        address beneficiary;
        uint96 weight; //BPS
    }

    address public immutable i_jellyToken;
    uint32 public mintingStartedTimestamp;
    address public stakingRewardsContract;
    uint32 public lastMintedTimestamp;
    uint32 public mintingPeriod = 7 days;

    bool public started;

    Beneficiary[] public beneficiaries;

    int256 constant K = -15;
    uint256 constant DECIMALS = 1e18;

    modifier onlyStarted() {
        if (started == false) {
            revert Minter_MintingNotStarted();
        }
        _;
    }

    modifier onlyNotStarted() {
        if (started == true) {
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
    error Minter_ZeroAddress();

    constructor(
        address _jellyToken,
        address _stakingRewardsContract,
        address _newOwner,
        address _pendingOwner
    ) Ownable(_newOwner, _pendingOwner) {
        if (
            _jellyToken == address(0) || _stakingRewardsContract == address(0)
        ) {
            revert Minter_ZeroAddress();
        }
        i_jellyToken = _jellyToken;
        stakingRewardsContract = _stakingRewardsContract;
    }

    /**
     * @notice Starts minting process for jelly tokens, and sets last minted timestamp so that minting can start immediately
     */
    function startMinting() external onlyOwner onlyNotStarted {
        started = true;
        lastMintedTimestamp = uint32(block.timestamp) - mintingPeriod;
        mintingStartedTimestamp = uint32(block.timestamp);

        emit MintingStarted(msg.sender, block.timestamp);
    }

    /**
     * @notice Mint new tokens based on exponential function, callable by anyone
     */
    function mint() external onlyStarted nonReentrant {
        uint256 secondsSinceLastMint = block.timestamp - lastMintedTimestamp;

        if (secondsSinceLastMint < mintingPeriod) {
            revert Minter_MintTooSoon();
        }

        lastMintedTimestamp += mintingPeriod;
        int256 daysSinceMintingStarted = int256(
            (block.timestamp - mintingStartedTimestamp) / 1 days
        );
        uint256 mintAmount = calculateMintAmount(daysSinceMintingStarted);
        uint256 mintAmountWithDecimals = mintAmount * DECIMALS;

        uint256 epochId;

        for (uint16 i = 0; i < beneficiaries.length; i++) {
            uint256 weight = beneficiaries[i].weight;
            uint256 amount = (mintAmountWithDecimals * weight) / 1000;

            if (beneficiaries[i].beneficiary == stakingRewardsContract) {
                IJellyToken(i_jellyToken).mint(address(this), amount);
                IJellyToken(i_jellyToken).approve(
                    stakingRewardsContract,
                    amount
                );
                epochId = IStakingRewardDistribution(stakingRewardsContract)
                    .deposit(IERC20(i_jellyToken), amount);
            } else {
                IJellyToken(i_jellyToken).mint(
                    beneficiaries[i].beneficiary,
                    amount
                );
            }
        }

        emit JellyMinted(
            msg.sender,
            stakingRewardsContract,
            lastMintedTimestamp,
            mintingPeriod,
            mintAmountWithDecimals,
            epochId
        );
    }

    /**
     * @notice Calculate mint amount based on exponential function
     *
     * @param _daysSinceMintingStarted - number of days since minting started
     *
     * @return mintAmount - amount of tokens to mint
     */
    function calculateMintAmount(
        int256 _daysSinceMintingStarted
    ) public pure returns (uint256) {
        // 900_000 * e ^ (-0.0015 * n)
        SD59x18 exponentMultiplier = div(convert(K), convert(10000));
        SD59x18 exponent = mul(
            exponentMultiplier,
            convert(_daysSinceMintingStarted)
        );
        uint256 mintAmount = intoUint256(mul(exp(exponent), sd(900_000)));

        return mintAmount;
    }

    /**
     * @notice Set new Staking Rewards Distribution Contract
     *
     * @dev Only owner can call.
     *
     * @param _newStakingRewardsContract new staking rewards distribution contract
     */
    function setStakingRewardsContract(
        address _newStakingRewardsContract
    ) external onlyOwner {
        if (_newStakingRewardsContract == address(0)) {
            revert Minter_ZeroAddress();
        }

        stakingRewardsContract = _newStakingRewardsContract;

        emit StakingRewardsContractSet(msg.sender, _newStakingRewardsContract);
    }

    /**
     * @notice Set new minting period
     *
     * @dev Only owner can call.
     *
     * @param _mintingPeriod new minitng period
     */
    function setMintingPeriod(uint32 _mintingPeriod) external onlyOwner {
        if (_mintingPeriod == 0) {
            revert Minter_ZeroAddress();
        }
        mintingPeriod = _mintingPeriod;

        emit MintingPeriodSet(msg.sender, _mintingPeriod);
    }

    /**
     * @notice Store array of beneficiaries to storage
     *
     * @dev Only owner can call.
     *
     * @param _beneficiaries to store
     */
    function setBeneficiaries(
        Beneficiary[] calldata _beneficiaries
    ) external onlyOwner {
        delete beneficiaries;

        uint256 size = _beneficiaries.length;
        for (uint256 i = 0; i < size; ++i) {
            beneficiaries.push(_beneficiaries[i]);
        }
        emit BeneficiariesChanged();
    }
}
