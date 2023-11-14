// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {SafeCast} from "../vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";

/**
 * @title VestingLib
 * @notice Vesting Library
 *
 *  token amount
 *       ^
 *       |                           __________________
 *       |                          /
 *       |                         /
 *       |                        /
 *       |                       /
 *       |                      /
 *       | <----- cliff ----->
 *       |
 *       |
 *        --------------------.------.-------------------> time
 *                         vesting duration
 *
 *
 * @dev Total vested amount is stored as an immutable storage variable to prevent manipulations when calculating current releasable amount.
 */

abstract contract VestingLib {
    uint32 public index;

    struct VestingPosition {
        address beneficiary;
        uint256 totalVestedAmount;
        uint256 releasedAmount;
        uint48 cliffTimestamp;
        uint32 vestingDuration;
    }

    event NewVestingPosition (
        VestingPosition position,
        uint32 index
    );

    mapping(uint32 => VestingPosition) internal vestingPositions;

    error VestingLib__StartTimestampMustNotBeInThePast();
    error VestingLib__InvalidDuration();
    error VestingLib__InvalidIndex();
    error VestingLib__InvalidSender();
    error VestingLib__InvalidBeneficiary();
    error VestingLib__InvalidVestingAmount();
    error VestingLib__InvalidReleaseAmount();

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet
     *
     * @return uint256 The amount that has vested but hasn't been released yet
     */
    function releasableAmount(uint32 vestingIndex) public view returns (uint256) {
        VestingPosition memory vestingPosition = vestingPositions[vestingIndex];
        return vestedAmount(vestingIndex) - vestingPosition.releasedAmount;
    }

    function vestedAmount(
        uint32 vestingIndex
    ) internal view returns (uint256 vestedAmount_) {
        VestingPosition memory vestingPosition_ = vestingPositions[
            vestingIndex
        ];

        if (block.timestamp < vestingPosition_.cliffTimestamp) {
            vestedAmount_ = 0; // @dev reassiging to zero for clarity & better code readability
        } else if (
            block.timestamp >=
            vestingPosition_.cliffTimestamp + vestingPosition_.vestingDuration
        ) {
            vestedAmount_ = vestingPosition_.totalVestedAmount;
        } else {
            unchecked {
                vestedAmount_ =
                    (vestingPosition_.totalVestedAmount *
                        (block.timestamp - vestingPosition_.cliffTimestamp)) /
                    vestingPosition_.vestingDuration;
            }
        }
    }

    function createVestingPosition(
        uint256 amount,
        address beneficiary,
        uint32 cliffDuration,
        uint32 vestingDuration
    ) internal returns (VestingPosition memory) {
        if (cliffDuration == 0) revert VestingLib__InvalidDuration();
        if (beneficiary == address(0)) revert VestingLib__InvalidBeneficiary();
        if (amount == 0) revert VestingLib__InvalidVestingAmount();

        uint48 cliffTimestamp = SafeCast.toUint48(block.timestamp) +
            SafeCast.toUint48(cliffDuration);

        vestingPositions[index].beneficiary = beneficiary;
        vestingPositions[index].totalVestedAmount = amount;
        vestingPositions[index].cliffTimestamp = cliffTimestamp;
        vestingPositions[index].vestingDuration = vestingDuration;

        VestingPosition memory vestingPosition_ = vestingPositions[
            index
        ];

        emit NewVestingPosition(vestingPosition_, index);

        ++index;

        return vestingPosition_;
    }

    // @dev This is a function which should be called when user claims some amount of releasable tokens
    function updateReleasedAmount(
        uint32 vestingIndex,
        uint256 releaseAmount
    ) internal {
        if (vestingIndex >= index) revert VestingLib__InvalidIndex();
        if (releaseAmount == 0) revert VestingLib__InvalidReleaseAmount();
        if (releaseAmount > releasableAmount(vestingIndex)) revert VestingLib__InvalidReleaseAmount();

        VestingPosition storage vestingPosition_ = vestingPositions[
            vestingIndex
        ];

        if (vestingPosition_.beneficiary != msg.sender)
            revert VestingLib__InvalidSender();

        vestingPosition_.releasedAmount += releaseAmount;
    }
}