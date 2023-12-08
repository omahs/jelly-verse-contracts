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
    uint256 public index;

    struct VestingPosition {
        uint256 totalVestedAmount;
        uint256 releasedAmount;
        uint48 cliffTimestamp;
        uint32 vestingDuration;
        uint32 freezingPeriod;
        uint128 booster;
        uint16 nerfParameter;
    }

    event NewVestingPosition(VestingPosition position, uint256 index);
    // changed from uint32 to uint256
    mapping(uint256 => VestingPosition) internal vestingPositions;

    error VestingLib__StartTimestampMustNotBeInThePast();
    error VestingLib__InvalidDuration();
    error VestingLib__InvalidIndex();
    error VestingLib__InvalidSender();
    error VestingLib__InvalidVestingAmount();
    error VestingLib__InvalidReleaseAmount();

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet
     *
     * @return uint256 The amount that has vested but hasn't been released yet
     */
    function releasableAmount(
        uint256 vestingIndex
    ) public view returns (uint256) {
        VestingPosition memory vestingPosition = vestingPositions[vestingIndex];
        return vestedAmount(vestingIndex) - vestingPosition.releasedAmount;
    }

    function vestedAmount(
        uint256 vestingIndex
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
        uint32 cliffDuration,
        uint32 vestingDuration,
        uint128 booster,
        uint8 nerfParameter
    ) internal returns (VestingPosition memory) {
        if (cliffDuration == 0) revert VestingLib__InvalidDuration();
        if (amount == 0) revert VestingLib__InvalidVestingAmount();

        uint48 cliffTimestamp = SafeCast.toUint48(block.timestamp) +
            SafeCast.toUint48(cliffDuration);

        vestingPositions[index].totalVestedAmount = amount;
        vestingPositions[index].cliffTimestamp = cliffTimestamp;
        vestingPositions[index].vestingDuration = vestingDuration;
        vestingPositions[index].freezingPeriod = cliffDuration;
        vestingPositions[index].booster = booster;
        vestingPositions[index].nerfParameter = nerfParameter;

        VestingPosition memory vestingPosition_ = vestingPositions[index];

        emit NewVestingPosition(vestingPosition_, index);

        ++index;

        return vestingPosition_;
    }

    // @dev This is a function which should be called when user claims some amount of releasable tokens
    function updateReleasedAmount(
        uint256 vestingIndex,
        uint256 releaseAmount
    ) internal {
        if (vestingIndex >= index) revert VestingLib__InvalidIndex();
        if (releaseAmount == 0) revert VestingLib__InvalidReleaseAmount();
        if (releaseAmount > releasableAmount(vestingIndex))
            revert VestingLib__InvalidReleaseAmount();

        VestingPosition storage vestingPosition_ = vestingPositions[
            vestingIndex
        ];

        vestingPosition_.releasedAmount += releaseAmount;
    }
}
