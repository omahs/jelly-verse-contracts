// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {SafeCast} from "../vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";

/**
 * @title VestingLibChest
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

abstract contract VestingLibChest {
    uint256 public index;

    struct VestingPosition {
        uint256 totalVestedAmount;
        uint256 releasedAmount;
        uint48 cliffTimestamp;
        uint48 boosterTimestamp;
        uint32 vestingDuration;
        uint120 accumulatedBooster;
        uint8 nerfParameter;
    }

    event NewVestingPosition(VestingPosition position, uint256 index);

    mapping(uint256 => VestingPosition) internal vestingPositions;

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet
     *
     * @return uint256 The amount that has vested but hasn't been released yet
     */
    function releasableAmount(
        uint256 vestingIndex
    ) public view returns (uint256) {
        return vestedAmount(vestingIndex);
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
            vestedAmount_ = vestingPosition_.totalVestedAmount - vestingPosition_.releasedAmount;
        } else {
            unchecked {
                vestedAmount_ =
                    ((vestingPosition_.totalVestedAmount - vestingPosition_.releasedAmount) *
                        (block.timestamp - vestingPosition_.cliffTimestamp)) /
                    vestingPosition_.vestingDuration;
            }
        }
    }

    function createVestingPosition(
        uint256 amount,
        uint32 cliffDuration,
        uint32 vestingDuration,
        uint120 booster,
        uint8 nerfParameter
    ) internal returns (VestingPosition memory) {
        uint48 cliffTimestamp = SafeCast.toUint48(block.timestamp) +
            SafeCast.toUint48(cliffDuration);

        vestingPositions[index].totalVestedAmount = amount;
        vestingPositions[index].cliffTimestamp = cliffTimestamp;
        vestingPositions[index].boosterTimestamp = uint48(block.timestamp);
        vestingPositions[index].vestingDuration = vestingDuration;
        vestingPositions[index].accumulatedBooster = booster;
        vestingPositions[index].nerfParameter = nerfParameter;

        VestingPosition memory vestingPosition_ = vestingPositions[index];

        emit NewVestingPosition(vestingPosition_, index);

        ++index;

        return vestingPosition_;
    }
}
