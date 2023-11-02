// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {SafeCast} from "../vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";

/**
 * @title Vesting
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
        uint48 startTimestamp; // ─╮
        uint48 cliffTimestamp; //  │
        uint32 totalDuration; //  ─╯
        bool finished;
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
        VestingPosition memory vestingPosition_ = VestingLib.vestingPositions[
            vestingIndex
        ];

        if (block.timestamp < vestingPosition_.cliffTimestamp) {
            vestedAmount_ = 0; // @dev reassiging to zero for clarity & better code readability
        } else if (
            block.timestamp >=
            vestingPosition_.startTimestamp + vestingPosition_.totalDuration
        ) {
            vestedAmount_ = vestingPosition_.totalVestedAmount;
        } else {
            unchecked {
                vestedAmount_ =
                    (vestingPosition_.totalVestedAmount *
                        (block.timestamp - vestingPosition_.startTimestamp)) /
                    vestingPosition_.totalDuration;
            }
        }
    }

    function createVestingPosition(
        uint256 amount,
        address beneficiary,
        uint48 startTimestamp,
        uint32 cliffDuration,
        uint32 vestingDuration
    ) internal returns (VestingPosition memory) {
        if (startTimestamp < block.timestamp)
            revert VestingLib__StartTimestampMustNotBeInThePast();
        if (cliffDuration <= 0) revert VestingLib__InvalidDuration();
        if (vestingDuration <= 0) revert VestingLib__InvalidDuration();
        if (beneficiary == address(0)) revert VestingLib__InvalidBeneficiary();
        if (amount <= 0) revert VestingLib__InvalidVestingAmount();

        uint48 cliffTimestamp = startTimestamp +
            SafeCast.toUint48(cliffDuration);
        uint32 totalDuration = cliffDuration + vestingDuration;

        vestingPositions[index].beneficiary = beneficiary;
        vestingPositions[index].totalVestedAmount = amount;
        vestingPositions[index].startTimestamp = startTimestamp;
        vestingPositions[index].cliffTimestamp = cliffTimestamp;
        vestingPositions[index].totalDuration = totalDuration;

        VestingPosition memory vestingPosition_ = VestingLib.vestingPositions[
            index
        ];

        emit NewVestingPosition(vestingPosition_, index);

        ++index;

        return vestingPosition_;
    }

    function updateReleasedAmount(
        uint32 vestingIndex,
        uint256 releaseAmount
    ) internal {
        if (vestingIndex <= 0 || vestingIndex >= index) revert VestingLib__InvalidIndex();
        if (releaseAmount <= 0) revert VestingLib__InvalidReleaseAmount();

        VestingPosition memory vestingPosition_ = VestingLib.vestingPositions[
            vestingIndex
        ];

        if (vestingPosition_.beneficiary != msg.sender)
            revert VestingLib__InvalidSender();

        uint256 totalReleasedAmount = vestingPosition_.releasedAmount + releaseAmount;

        if (totalReleasedAmount > vestingPosition_.totalVestedAmount)
            revert VestingLib__InvalidReleaseAmount();

        VestingLib.vestingPositions[vestingIndex].releasedAmount = totalReleasedAmount;
    }
}