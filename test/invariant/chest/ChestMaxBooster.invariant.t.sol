// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/BaseSetup.sol";
import {Chest} from "../../../contracts/Chest.sol";
import {ERC20Token} from "../../../contracts/test/ERC20Token.sol";

// Invariant Definition:
// Booster Cap: Ensures that the booster value for any chest does not surpass the defined maximum booster limit.

contract InvariantChestMaxBooster is BaseSetup {
    function setUp() public virtual override {
        super.setUp();
        targetContract(address(chestHandler));
    }

    function invariant_maxBooster() external {
        uint256 booster = chest.getVestingPosition(positionIndex).booster;
        assertLe(booster, chest.maxBooster());
    }
}
