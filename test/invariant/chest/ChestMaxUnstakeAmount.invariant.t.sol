// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/BaseSetup.sol";
import {Chest} from "../../../contracts/Chest.sol";
import {ERC20Token} from "../../../contracts/test/ERC20Token.sol";

// Invariant Definition:
// Withdrawal Limit: Guarantees that the withdrawal amount cannot exceed the staked balance.

contract InvariantChestMaxUnstakeAmount is BaseSetup {
    uint256 accountJellyBalance;

    function setUp() public virtual override {
        super.setUp();
        Chest.VestingPosition memory position = chest.getVestingPosition(
            positionIndex
        );
        accountJellyBalance =
            jellyToken.balanceOf(address(testAddress)) +
            position.totalVestedAmount;

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = chestHandler.stake.selector;
        selectors[1] = chestHandler.stakeSpecial.selector;
        selectors[2] = chestHandler.increaseFreezingPeriod.selector;
        selectors[3] = chestHandler.unstake.selector;
        selectors[4] = chestHandler.withdrawFees.selector;

        targetSelector(FuzzSelector(address(chestHandler), selectors));
    }

    function invariant_unstake() external {
        assertLe(
            jellyToken.balanceOf(address(testAddress)),
            accountJellyBalance
        );
    }
}
