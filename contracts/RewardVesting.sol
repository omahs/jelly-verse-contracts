// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "./vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";

contract RewardVesting is Ownable {
    using SafeERC20 for IERC20;

    struct VestingPosition {
        uint256 vestedAmount;
        uint48 startTime;
    }

    mapping(address => VestingPosition) public liquidityVestedPositions;
    mapping(address => VestingPosition) public stakingVestedPositions;
    address public liquidityContract;
    address public stakingContract;
    IERC20 public jellyToken;
    uint48 public vestingPeriod = 30 days;

    error Vest__InvalidCaller();
    error Vest__ZeroAddress();
    error Vest__InvalidVestingAmount();
    error Vest__AlreadyVested();
    error Vest__NothingToClaim();

    event VestedLiqidty(uint256 amount, address beneficiary);
    event VestingLiquidityClaimed(uint256 amount, address beneficiary);
    event VestedStaking(uint256 amount, address beneficiary);
    event VestingStakingClaimed(uint256 amount, address beneficiary);

    constructor(
        address _owner,
        address _pendingOwner,
        address _liquidityContract,
        address _stakingContract,
        address _jellyToken
    ) Ownable(_owner, _pendingOwner) {
        stakingContract = _stakingContract;
        liquidityContract = _liquidityContract;
        jellyToken = IERC20(_jellyToken);
    }

    /**
     * @notice Vest liquidity
     *
     * @param _amount - amount of tokens to deposit
     * @param _beneficiary - address of beneficiary
     *
     * No return only Vesting contract can call
     */

    function vestLiquidity(uint256 _amount, address _beneficiary) public {
        if (msg.sender != liquidityContract) revert Vest__InvalidCaller();
        if (_amount == 0) revert Vest__InvalidVestingAmount();
        if (_beneficiary == address(0)) revert Vest__ZeroAddress();
        if (liquidityVestedPositions[_beneficiary].vestedAmount != 0)
            revert Vest__AlreadyVested();

        liquidityVestedPositions[_beneficiary].vestedAmount = _amount;
        liquidityVestedPositions[_beneficiary].startTime = SafeCast.toUint48(
            block.timestamp
        );

        jellyToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit VestedLiqidty(_amount, _beneficiary);
    }

    /**
     * @notice Claim vested liqidty
     *
     * No return
     */

    function claimLiquidity() public {
        if (liquidityVestedPositions[msg.sender].vestedAmount == 0)
            revert Vest__NothingToClaim();

        uint256 amount = vestedLiquidityAmount(msg.sender);

        liquidityVestedPositions[msg.sender].vestedAmount = 0;
        jellyToken.safeTransfer(msg.sender, amount);

        emit VestingLiquidityClaimed(amount, msg.sender);
    }

    /**
     * @notice Calculates vested tokens
     *
     * @param _beneficiary - address of beneficiary
     *
     * Return amount of tokens vested
     */

    function vestedLiquidityAmount(
        address _beneficiary
    ) public view returns (uint256 amount) {
        VestingPosition storage vestingPosition = liquidityVestedPositions[
            _beneficiary
        ];

        if (block.timestamp >= vestingPosition.startTime + vestingPeriod)
            amount = vestingPosition.vestedAmount;
        else
            amount = (
                (vestingPosition.vestedAmount /
                    2 +
                    ((vestingPosition.vestedAmount / 2) *
                        (block.timestamp - vestingPosition.startTime)) /
                    vestingPeriod)
            );
    }

    /**
     * @notice Vest staking
     *
     * @param _amount - amount of tokens to deposit
     * @param _beneficiary - address of beneficiary
     *
     * No return only Vesting contract can call
     */

    function vestStaking(uint256 _amount, address _beneficiary) public {
        if (msg.sender != stakingContract) revert Vest__InvalidCaller();
        if (_amount == 0) revert Vest__InvalidVestingAmount();
        if (_beneficiary == address(0)) revert Vest__ZeroAddress();
        if (stakingVestedPositions[_beneficiary].vestedAmount != 0)
            revert Vest__AlreadyVested();

        stakingVestedPositions[_beneficiary].vestedAmount = _amount;
        stakingVestedPositions[_beneficiary].startTime = SafeCast.toUint48(
            block.timestamp
        );

        jellyToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit VestedStaking(_amount, _beneficiary);
    }

    /**
     * @notice Claim vested staking
     *
     * No return
     */
    function claimStaking() public {
        if (stakingVestedPositions[msg.sender].vestedAmount == 0)
            revert Vest__NothingToClaim();

        uint256 amount = vestedStakingAmount(msg.sender);

        stakingVestedPositions[msg.sender].vestedAmount = 0;
        jellyToken.safeTransfer(msg.sender, amount);

        emit VestingStakingClaimed(amount, msg.sender);
    }

    /**
     * @notice Calculates vested tokens
     *
     * @param _beneficiary - address of beneficiary
     *
     * Return amount of tokens vested
     */

    function vestedStakingAmount(
        address _beneficiary
    ) public view returns (uint256 amount) {
        VestingPosition storage vestingPosition = stakingVestedPositions[
            _beneficiary
        ];

        if (block.timestamp >= vestingPosition.startTime + vestingPeriod)
            amount = vestingPosition.vestedAmount;
        else
            amount = (
                (vestingPosition.vestedAmount /
                    2 +
                    ((vestingPosition.vestedAmount / 2) *
                        (block.timestamp - vestingPosition.startTime)) /
                    vestingPeriod)
            );
    }
}
