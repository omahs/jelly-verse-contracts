// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {VestingLib} from "../../../contracts/utils/VestingLib.sol";
import {Strings} from "../../../contracts/vendor/openzeppelin/v4.9.0/utils/Strings.sol";
import {SafeCast} from "../../../contracts/vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";
import {VestingLibTest} from "../../../contracts/test/VestingLibTest.sol";

contract VestingLibFuzzTest is VestingLib, Test {
    using Strings for uint256;

    VestingLibTest vestingLibTest;
    address beneficiary;
    uint256 amount;
    uint32 cliffDuration;
    uint32 vestingDuration;
    VestingPosition vestingPosition;

    function setUp() public {
        amount = 133_000_000 * 10 ** 18;
        beneficiary = makeAddr("beneficiary");
        cliffDuration = SafeCast.toUint32(15638400); // @dev 6 month Wednesday, 1 July 1970 00:00:00
        vestingDuration = SafeCast.toUint32(44582400); // @dev 18 month Tuesday, 1 June 1971 00:00:00
        vestingLibTest = new VestingLibTest();
        vestingPosition = vestingLibTest.createNewVestingPosition(
            amount,
            beneficiary,
            cliffDuration,
            vestingDuration
        );
    }

    function testFuzz_createVestingPosition(
        uint256 _amount,
        address _beneficiary,
        uint32 _cliffDuration,
        uint32 _vestingDuration
    ) external {
        vm.assume(_amount > 0);
        vm.assume(_beneficiary != address(0));
        vm.assume(_cliffDuration > 0);
        vm.assume(_vestingDuration > 0);
        uint256 beforeIndex = index;
        createVestingPosition(
            _amount,
            _beneficiary,
            _cliffDuration,
            _vestingDuration
        );
        uint256 afterIndex = index;

        assertEq(beforeIndex + 1, afterIndex);
    }

    function testFuzz_updateReleasedAmount(uint256 _releaseAmount) external {
        _releaseAmount = bound(_releaseAmount, 1, amount);
        vm.warp(block.timestamp + cliffDuration + vestingDuration);
        vm.startPrank(vestingPosition.beneficiary);
        uint256 beforeAmount = vestingPosition.releasedAmount;
        vestingLibTest.updateReleasedAmountPublic(0, _releaseAmount);
        uint256 afterAmount = vestingLibTest
            .getVestingPosition(0)
            .releasedAmount;
        vm.stopPrank();
        assertEq(beforeAmount + _releaseAmount, afterAmount);
    }
}