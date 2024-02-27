/*
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Chest} from "../../../../contracts/Chest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ChestHarness is Chest {
    constructor(
        address jellyToken,
        uint256 fee_,
        uint128 maxBooster_,
        uint8 timeFactor_,
        address owner,
        address pendingOwner
    )
        Chest(
            jellyToken,
            fee_,
            maxBooster_,
            timeFactor_,
            owner,
            pendingOwner
        )
    {}

    function exposed_calculateBooster(
        ChestHarness.VestingPosition memory vestingPosition
    ) external view returns (uint128) {
        return calculateBooster(vestingPosition);
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

contract ChestBoosterCalculationDifferentialTest is Test {
    using Strings for *;

    uint32 constant MIN_FREEZING_PERIOD_REGULAR_CHEST = 7 days;
    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint128 private constant DECIMALS = 1e18;
    uint128 private constant INITIAL_BOOSTER = 1 * DECIMALS;

    address jellyToken = makeAddr("jellyToken");

    ChestHarness public chestHarness;
    Chest.VestingPosition vestingPosition;

    function setUp() public {
        uint256 fee = 10;
        uint128 maxBooster = 2e18;
        address owner = msg.sender;
        address pendingOwner = makeAddr("pendingOwner");
        uint8 timeFactor = 2;

        chestHarness = new ChestHarness(
            jellyToken,
            fee,
            maxBooster,
            timeFactor,
            owner,
            pendingOwner
        );
    }

    function test_calculateBooster(
        uint256 amount,
        uint32 freezingPeriod
    ) external {
        vm.assume(
            amount > 0 &&
                freezingPeriod < MAX_FREEZING_PERIOD_REGULAR_CHEST &&
                freezingPeriod > MIN_FREEZING_PERIOD_REGULAR_CHEST
        );

        uint8 nerfParameter = 10;
        uint32 vestingDuration = 0;

        vestingPosition = chestHarness.exposed_createVestingPosition(
            amount,
            freezingPeriod,
            vestingDuration,
            INITIAL_BOOSTER,
            nerfParameter
        );

        uint128 boosterSol = chestHarness.exposed_calculateBooster(
            vestingPosition
        );
        uint128 boosterRust = ffi_booster();

        console.logUint(boosterRust);
        console.logUint(boosterSol);

        assertEq(boosterRust, boosterSol);
    }

    function ffi_booster() private returns (uint128 boosterRust) {
        string[] memory inputs = new string[](9);
        inputs[0] = "cargo";
        inputs[1] = "run";
        inputs[2] = "--quiet";
        inputs[3] = "--manifest-path";
        inputs[4] = "test/differential/chest/booster/Cargo.toml";
        inputs[5] = vestingPosition.freezingPeriod.toString();
        inputs[6] = vestingPosition.vestingDuration.toString();
        inputs[7] = vestingPosition.booster.toString();
        inputs[8] = chestHarness.maxBooster().toString();

        bytes memory result = vm.ffi(inputs);
        assembly {
            boosterRust := mload(add(result, 0x20))
        }
    }
}
*/