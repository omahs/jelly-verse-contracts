// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ChestHandler} from "./ChestHandler.sol";
import {Chest} from "../../../../contracts/Chest.sol";
import {ERC20Token} from "../../../../contracts/test/ERC20Token.sol";

contract ChestHarness is Chest {
    constructor(
        address jellyToken,
        uint128 fee_,
        address owner,
        address pendingOwner
    ) Chest(jellyToken, fee_, owner, pendingOwner) {}

    function exposed_calculateBooster(
        ChestHarness.VestingPosition memory vestingPosition,
        uint48 timestamp
    ) external pure returns (uint120) {
        return _calculateBooster(vestingPosition, timestamp);
    }
}

contract BaseSetup is Test {
    uint256 constant JELLY_MAX_SUPPLY = 1_000_000_000 ether;

    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;
    uint32 constant MIN_FREEZING_PERIOD = 7 days;

    uint120 private constant DECIMALS = 1e18;
    uint120 private constant INITIAL_BOOSTER = 1 * DECIMALS;

    uint256 constant MIN_STAKING_AMOUNT = 1000 * DECIMALS;

    uint256 positionIndex;
    address ownerOfChest;

    address testAddress = makeAddr("testAddress");
    address specialChestCreator = makeAddr("specialChestCreator");
    address approvedAddress = makeAddr("approvedAddress");
    address nonApprovedAddress = makeAddr("nonApprovedAddress");
    address transferRecipientAddress = makeAddr("transferRecipientAddress");
    address beneficiary = makeAddr("beneficiary");

    Chest public chest;
    ERC20Token public jellyToken;
    ChestHandler public chestHandler;
    ChestHarness public chestHarness;

    function setUp() public virtual {
        uint128 fee = 10;
        address owner = msg.sender;
        address pendingOwner = testAddress;

        jellyToken = new ERC20Token("Jelly", "JELLY");
        chest = new Chest(address(jellyToken), fee, owner, pendingOwner);
        chestHarness = new ChestHarness(
            address(jellyToken),
            fee,
            owner,
            pendingOwner
        );
        chestHandler = new ChestHandler(beneficiary, chest, jellyToken);

        excludeContract(address(jellyToken));
        excludeContract(address(chest));
        excludeContract(address(chestHarness));

        vm.prank(testAddress);
        jellyToken.mint(1_000 * MIN_STAKING_AMOUNT);

        vm.prank(specialChestCreator);
        jellyToken.mint(1_000 * MIN_STAKING_AMOUNT);

        vm.prank(approvedAddress);
        jellyToken.mint(1_000 * MIN_STAKING_AMOUNT);

        // @dev open regular positions so handler has always position to work with
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());
        chest.stake(amount, testAddress, freezingPeriod);

        positionIndex = chest.totalSupply() - 1;
        ownerOfChest = chest.ownerOf(positionIndex);
        vm.stopPrank();
    }
}
