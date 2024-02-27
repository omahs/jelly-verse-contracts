// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/BaseSetup.sol";
import {Chest} from "../../../contracts/Chest.sol";
import {ERC20Token} from "../../../contracts/test/ERC20Token.sol";

// Invariant Definition:
// Booster Cap: Ensures that the booster value for any chest does not surpass the defined maximum booster limit.

contract InvariantChestMaxBooster is BaseSetup {
    uint120 maxBooster;

    function setUp() public virtual override {
        super.setUp();
        targetContract(address(chestHandler));
        maxBooster = chest.maxBooster();
    }

    function invariant_maxBooster() external {
      Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

      uint256 booster = chestHarness.exposed_calculateBooster(vestingPosition, block.timestamp);

      assertLe(booster, maxBooster);
    }
}
