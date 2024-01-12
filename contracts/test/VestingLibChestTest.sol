// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {VestingLibChest} from "../utils/VestingLibChest.sol";

contract VestingLibChestTest is VestingLibChest {
    function getVestingPosition(
        uint256 vestingIndex
    ) public view returns (VestingPosition memory) {
        return VestingLibChest.vestingPositions[vestingIndex];
    }

    function getVestingIndex() public view returns (uint256) {
        return VestingLibChest.index;
    }

    function getVestedAmount(
        uint256 vestingIndex
    ) public view returns (uint256) {
        return VestingLibChest.vestedAmount(vestingIndex);
    }

    function createNewVestingPosition(
        uint256 amount,
        uint32 cliffDuration,
        uint32 vestingDuration,
        uint128 booster,
        uint8 nerfParameter
    ) public returns (VestingPosition memory) {
        return
            VestingLibChest.createVestingPosition(
                amount,
                cliffDuration,
                vestingDuration,
                booster,
                nerfParameter
            );
    }

    function updateReleasedAmount(
        uint256 vestingIndex,
        uint256 releaseAmount
    ) public {
        vestingPositions[vestingIndex].releasedAmount += releaseAmount;
    }
}
