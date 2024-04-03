// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Vesting} from "../utils/Vesting.sol";

contract VestingTest is Vesting {
    function getVestingPosition(
        uint256 vestingIndex
    ) public view returns (VestingPosition memory) {
        return Vesting.vestingPositions[vestingIndex];
    }

    function getVestingIndex() public view returns (uint256) {
        return Vesting.index;
    }

    function createNewVestingPosition(
        uint256 amount,
        uint32 cliffDuration,
        uint32 vestingDuration,
        uint120 booster,
        uint8 nerfParameter
    ) public returns (VestingPosition memory) {
        return
            Vesting._createVestingPosition(
                amount,
                cliffDuration,
                vestingDuration,
                booster,
                nerfParameter
            );
    }

    function updateReleasedAmount(uint256 vestingIndex, uint256 amount) public {
        Vesting.vestingPositions[vestingIndex].releasedAmount = amount;
    }
}
