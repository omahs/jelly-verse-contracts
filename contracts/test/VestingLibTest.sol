// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {VestingLib} from "../utils/VestingLib.sol";

contract VestingLibTest is VestingLib {
    function getVestingPosition(uint256 vestingIndex) public view returns (VestingPosition memory) {
        return VestingLib.vestingPositions[vestingIndex];
    }
    function getVestingIndex() public view returns (uint256) {
        return VestingLib.index;
    }
    function getVestedAmount(uint256 vestingIndex) public view returns (uint256) {
        return VestingLib.vestedAmount(vestingIndex);
    }
    function createNewVestingPosition(
        uint256 totalVestedAmount,
        address beneficiary,
        uint32 cliffDuration,
        uint32 vestingDuration
    ) public returns (VestingPosition memory) {
        return VestingLib.createVestingPosition(
            totalVestedAmount,
            beneficiary,
            cliffDuration,
            vestingDuration
        );
    }
    function updateReleasedAmountPublic(
        uint256 vestingIndex,
        uint256 releaseAmount
    ) public {
        return VestingLib.updateReleasedAmount(
            vestingIndex,
            releaseAmount
        );
    }
}
