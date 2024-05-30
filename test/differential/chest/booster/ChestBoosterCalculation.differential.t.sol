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

    function exposed_calculateBooster(
        ChestHarness.VestingPosition memory vestingPosition,
        uint48 timestamp
    ) external pure returns (uint120) {
        return _calculateBooster(vestingPosition, timestamp);
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

contract ChestBoosterCalculationDifferentialTest is Test {
    using Strings for *;

    uint32 constant MIN_FREEZING_PERIOD = 7 days;
    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint8 constant MAX_NERF_PARAMETER = 10;
    uint120 private constant DECIMALS = 1e18;
    uint120 private constant INITIAL_BOOSTER = 1 * DECIMALS;
    uint256 private constant MIN_STAKING_AMOUNT = 100 * DECIMALS;

    address jellyToken = makeAddr("jellyToken");

    ChestHarness public chestHarness;
    Chest.VestingPosition vestingPosition;

    function setUp() public {
        uint128 fee = 10;
        address owner = msg.sender;
        address pendingOwner = makeAddr("pendingOwner");

        chestHarness = new ChestHarness(jellyToken, fee, owner, pendingOwner);
    }

    function test_calculateBooster(
        uint256 amount,
        uint32 freezingPeriod
    ) external {
        vm.assume(
            amount > MIN_STAKING_AMOUNT &&
                freezingPeriod < MAX_FREEZING_PERIOD_REGULAR_CHEST &&
                freezingPeriod > MIN_FREEZING_PERIOD
        );

        uint8 nerfParameter = MAX_NERF_PARAMETER;
        uint32 vestingDuration = 0;

        vestingPosition = chestHarness.exposed_createVestingPosition(
            amount,
            freezingPeriod,
            vestingDuration,
            INITIAL_BOOSTER,
            nerfParameter
        );

        uint128 boosterSol = chestHarness.exposed_calculateBooster(
            vestingPosition,
            uint48(block.timestamp)
        );
        uint128 boosterRust = ffi_booster();

        console.logUint(boosterRust);
        console.logUint(boosterSol);

        assertEq(boosterRust, boosterSol);
    }

    function ffi_booster() private returns (uint128 boosterRust) {
        string[] memory inputs = new string[](11);
        inputs[0] = "cargo";
        inputs[1] = "run";
        inputs[2] = "--quiet";
        inputs[3] = "--manifest-path";
        inputs[4] = "test/differential/chest/booster/Cargo.toml";
        inputs[5] = vestingPosition.vestingDuration.toString();
        inputs[6] = vestingPosition.cliffTimestamp.toString();
        inputs[7] = vestingPosition.boosterTimestamp.toString();
        inputs[8] = block.timestamp.toString();
        inputs[9] = vestingPosition.accumulatedBooster.toString();
        inputs[10] = chestHarness.MAX_BOOSTER().toString();

        bytes memory result = vm.ffi(inputs);
        assembly {
            boosterRust := mload(add(result, 0x20))
        }
    }
}
