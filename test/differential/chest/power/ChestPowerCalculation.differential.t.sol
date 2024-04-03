// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Chest} from "../../../../contracts/Chest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ChestHarness is Chest {
    constructor(
        address jellyToken,
        uint128 fee_,
        address owner,
        address pendingOwner
    ) Chest(jellyToken, fee_, owner, pendingOwner) {}

    function exposed_calculatePower(
        uint256 timestamp,
        VestingPosition memory vestingPosition
    ) external pure returns (uint256) {
        return _calculatePower(timestamp, vestingPosition);
    }

    function exposed_createVestingPosition(
        uint256 amount,
        uint32 freezingPeriod,
        uint32 vestingDuration,
        uint120 booster,
        uint8 nerfParameter
    ) external returns (VestingPosition memory) {
        return
            _createVestingPosition(
                amount,
                freezingPeriod,
                vestingDuration,
                booster,
                nerfParameter
            );
    }
}

contract ChestPowerCalculationDifferentialTest is Test {
    using Strings for *;

    uint256 constant JELLY_MAX_SUPPLY = 1_000_000_000 ether;
    uint32 constant MIN_FREEZING_PERIOD_CHEST = 0 days;
    uint32 constant MAX_FREEZING_PERIOD_CHEST = 5 * 365 days;
    uint120 private constant DECIMALS = 1e18;
    uint120 private constant INITIAL_BOOSTER = 1 * DECIMALS;
    uint256 private constant MIN_STAKING_AMOUNT = 1_000 ether;

    uint120 private constant MAX_BOOSTER = 2 * DECIMALS;

    address jellyToken = makeAddr("jellyToken");

    ChestHarness public chestHarness;
    Chest.VestingPosition vestingPosition;

    function setUp() public {
        uint128 fee = 10;
        address owner = msg.sender;
        address pendingOwner = makeAddr("pendingOwner");

        chestHarness = new ChestHarness(jellyToken, fee, owner, pendingOwner);
    }

    function test_calculatePower(
        uint256 timestamp,
        uint256 amount,
        uint256 freezingPeriod,
        uint256 vestingDuration,
        uint8 nerfParameter
    ) external {
        vm.assume(
            timestamp > 0 && vestingDuration <= MAX_FREEZING_PERIOD_CHEST
        );
        freezingPeriod = bound(freezingPeriod, 1, MAX_FREEZING_PERIOD_CHEST);
        amount = bound(amount, MIN_STAKING_AMOUNT, JELLY_MAX_SUPPLY);
        vm.assume(nerfParameter <= 10);

        vestingPosition = chestHarness.exposed_createVestingPosition(
            amount,
            uint32(freezingPeriod),
            uint32(vestingDuration),
            INITIAL_BOOSTER,
            nerfParameter
        );

        vm.warp(timestamp);
        uint256 powerSol = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPosition
        );
        uint256 powerRust = ffi_power(timestamp);

        console.logUint(powerRust);
        console.logUint(powerSol);

        assertEq(powerRust, powerSol);
    }

    function ffi_power(uint256 timestamp) private returns (uint256 powerRust) {
        string[] memory inputs = new string[](12);
        inputs[0] = "cargo";
        inputs[1] = "run";
        inputs[2] = "--quiet";
        inputs[3] = "--manifest-path";
        inputs[4] = "test/differential/chest/power/Cargo.toml";
        inputs[5] = timestamp.toString();
        inputs[6] = vestingPosition.totalVestedAmount.toString();
        inputs[7] = uint256(vestingPosition.cliffTimestamp).toString();
        inputs[8] = uint256(vestingPosition.vestingDuration).toString();
        inputs[9] = uint256(vestingPosition.accumulatedBooster).toString();
        inputs[10] = uint256(vestingPosition.nerfParameter).toString();
        inputs[11] = vestingPosition.boosterTimestamp.toString();
        bytes memory result = vm.ffi(inputs);
        assembly {
            powerRust := mload(add(result, 0x20))
        }
    }
}
