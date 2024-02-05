// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "./vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";

contract RewardVesting is Ownable {
    using SafeERC20 for IERC20;

    struct VestingPostion {
        uint256 vestedAmount;
        uint48 startTime;
    }

    mapping(address => VestingPostion) public liquidtyVestedPotitions;
    mapping(address => VestingPostion) public stakingVestedPotitions;
    address public liquidtyContract;
    address public stakingContract;
    IERC20 public jellyToken;
    uint48 public vestingPeriod = 30 days;

    error Vest_InvalidCaller();
    error Vest__ZeroAddress();
    error Vest__InvalidVestingAmount();
    error Vest__AlreadyVested();
    error Vest__NothingToClaim();

    event VestedLiqidty(uint256 amount, address _eneficiary);
    event VestingLiquidtyClaimed(uint256 amount, address _eneficiary);
    event VestedStaking(uint256 amount, address _eneficiary);
    event VestingStakingClaimed(uint256 amount, address _eneficiary);

    constructor(
        address _owner,
        address _pendingOwner,
        address _liquidtyContract,
        address _stakingContract,
        address _jellyToken
    ) Ownable(_owner, _pendingOwner) {
        stakingContract = _stakingContract;
        liquidtyContract = _liquidtyContract;
        jellyToken = IERC20(_jellyToken);
    }

    /**
     * @notice Vest liquidty
     *
     * @param _amount - amount of tokens to deposit
     * @param _beneficiary - address of beneficiary
     *
     * No return only Vesting contract can call
     */

    function vestLiqidty(uint256 _amount, address _beneficiary) public {
        if (msg.sender != liquidtyContract) revert Vest_InvalidCaller();
        if (_amount == 0) revert Vest__InvalidVestingAmount();
        if (_beneficiary == address(0)) revert Vest__ZeroAddress();
        if (liquidtyVestedPotitions[_beneficiary].vestedAmount != 0)
            revert Vest__AlreadyVested();

        liquidtyVestedPotitions[_beneficiary].vestedAmount = _amount;
        liquidtyVestedPotitions[_beneficiary].startTime = SafeCast.toUint48(
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

    function claimLiquidty() public {
        if (liquidtyVestedPotitions[msg.sender].vestedAmount == 0)
            revert Vest__NothingToClaim();

        uint256 amount = vestedLiquidtyAmount(msg.sender);

        liquidtyVestedPotitions[msg.sender].vestedAmount = 0;
        jellyToken.safeTransfer(msg.sender, amount);

        emit VestingLiquidtyClaimed(amount, msg.sender);
    }

    /**
     * @notice Calculates vested tokens
     *
     * @param _beneficiary - address of beneficiary
     *
     * Return amount of tokens vested
     */

    function vestedLiquidtyAmount(
        address _beneficiary
    ) public view returns (uint256 amount) {
        VestingPostion storage vestingPosition = liquidtyVestedPotitions[
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
        if (msg.sender != stakingContract) revert Vest_InvalidCaller();
        if (_amount == 0) revert Vest__InvalidVestingAmount();
        if (_beneficiary == address(0)) revert Vest__ZeroAddress();
        if (stakingVestedPotitions[_beneficiary].vestedAmount != 0)
            revert Vest__AlreadyVested();

        stakingVestedPotitions[_beneficiary].vestedAmount = _amount;
        stakingVestedPotitions[_beneficiary].startTime = SafeCast.toUint48(
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
        if (stakingVestedPotitions[msg.sender].vestedAmount == 0)
            revert Vest__NothingToClaim();

        uint256 amount = vestedStakingAmount(msg.sender);

        stakingVestedPotitions[msg.sender].vestedAmount = 0;
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
        VestingPostion storage vestingPosition = stakingVestedPotitions[
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
