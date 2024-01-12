// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/BaseSetup.sol";
import {Chest} from "../../../contracts/Chest.sol";
import {ERC20Token} from "../../../contracts/test/ERC20Token.sol";

// Invariant Definition:
// TransferFrom Restriction: Prohibits the transfer of any chest token.

contract InvariantChestTransferFrom is BaseSetup {
    function setUp() public virtual override {
        super.setUp();
        targetContract(address(chestHandler));
    }

    function invariant_transferFrom() external {
        assertEq(chest.ownerOf(positionIndex), ownerOfChest);
    }
}
