// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Chest} from "../../../../contracts/Chest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ChestHarness is Chest {
    constructor(
        address jellyToken,
        address allocator,
        address distributor,
        uint256 fee_,
        uint128 maxBooster_,
        uint8 timeFactor_,
        address owner,
        address pendingOwner
    )
        Chest(
            jellyToken,
            allocator,
            distributor,
            fee_,
            maxBooster_,
            timeFactor_,
            owner,
            pendingOwner
        )
    {}

    function exposed_calculatePower(
        uint256 timestamp,
        VestingPosition memory vestingPosition
    ) external view returns (uint256) {
        return calculatePower(timestamp, vestingPosition);
    }

    function exposed_createVestingPosition(
        uint256 amount,
        uint32 freezingPeriod,
        uint32 vestingDuration,
        uint128 booster,
        uint8 nerfParameter
    ) external returns (VestingPosition memory) {
        return
            createVestingPosition(
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
    uint64 private constant DECIMALS = 1e18;
    uint64 private constant INITIAL_BOOSTER = 1 * DECIMALS;

    uint128 private constant MAX_BOOSTER = 2 * DECIMALS;

    address jellyToken = makeAddr("jellyToken");
    address allocator = makeAddr("allocator");
    address distributor = makeAddr("distributor");

    ChestHarness public chestHarness;
    Chest.VestingPosition vestingPosition;

    function setUp() public {
        uint256 fee = 10;
        uint128 maxBooster = MAX_BOOSTER;
        address owner = msg.sender;
        address pendingOwner = allocator;
        uint8 timeFactor = 2;

        chestHarness = new ChestHarness(
            jellyToken,
            allocator,
            distributor,
            fee,
            maxBooster,
            timeFactor,
            owner,
            pendingOwner
        );
    }

    function test_calculatePower(
        uint256 timestamp,
        uint256 amount,
        uint256 freezingPeriod,
        uint256 vestingDuration,
        uint256 booster,
        uint256 nerfParameter
    ) external {
        vm.assume(
            timestamp > 0 && vestingDuration <= MAX_FREEZING_PERIOD_CHEST
        );
        freezingPeriod = bound(freezingPeriod, 1, MAX_FREEZING_PERIOD_CHEST);
        amount = bound(amount, 1, JELLY_MAX_SUPPLY);
        booster = bound(booster, INITIAL_BOOSTER, MAX_BOOSTER);
        nerfParameter = bound(nerfParameter, 0, 10);

        vestingPosition = chestHarness.exposed_createVestingPosition(
            amount,
            uint32(freezingPeriod),
            uint32(vestingDuration),
            uint128(INITIAL_BOOSTER),
            uint8(nerfParameter)
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
        string[] memory inputs = new string[](11);
        inputs[0] = "cargo";
        inputs[1] = "run";
        inputs[2] = "--quiet";
        inputs[3] = "--manifest-path";
        inputs[4] = "test/differential/chest/power/Cargo.toml";
        inputs[5] = timestamp.toString();
        inputs[6] = vestingPosition.totalVestedAmount.toString();
        inputs[7] = uint256(vestingPosition.cliffTimestamp).toString();
        inputs[8] = uint256(vestingPosition.vestingDuration).toString();
        inputs[9] = uint256(vestingPosition.booster).toString();

        bytes memory result = vm.ffi(inputs);
        assembly {
            powerRust := mload(add(result, 0x20))
        }
    }
}
