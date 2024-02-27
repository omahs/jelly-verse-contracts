// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/BaseSetup.sol";
import {Chest} from "../../../contracts/Chest.sol";
import {ERC20Token} from "../../../contracts/test/ERC20Token.sol";

// Invariant Definition:
// Voting Power Cap: Confirms that the voting power associated with any chest remains within the stipulated maximum threshold.

contract InvariantChestMaxVotingPower is BaseSetup {
    uint256 constant MAX_FREEZING_PERIOD = 157 weeks;

    uint256 maxVotingPower;

    function setUp() public virtual override {
        super.setUp();
        targetContract(address(chestHandler));
        // @dev this is the maximum voting power for regular chest in case fee and booster are constant
        uint256 maxStakingAmount = JELLY_MAX_SUPPLY - chest.fee();
        uint256 maxFreezingPeriod = 157 weeks;
        maxVotingPower =
            maxStakingAmount *
            maxFreezingPeriod *
            chest.MAX_BOOSTER();
    }

    function invariant_maxVotingPower() external {
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 chestPower = chest.getChestPower(
            block.timestamp,
            vestingPosition
        );

        assertLe(chestPower, maxVotingPower);
    }
}
