// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {VestingLib} from "../../../contracts/utils/VestingLib.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SafeCast} from "../../../contracts/vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";

contract VestingLibDifferentialTest is VestingLib, Test {
  using Strings for uint256;
 
  address beneficiary; 
  uint256 amount;
  uint48 startTimestamp;
  uint32 cliffDuration;
  uint32 vestingDuration;
  VestingPosition vestingPosition;
   
  function setUp() public {
    amount = 133_000_000 * 10 ** 18;
    beneficiary = makeAddr("beneficiary");
    startTimestamp = SafeCast.toUint48(block.timestamp);
    cliffDuration = SafeCast.toUint32(15638400); // @dev 6 month Wednesday, 1 July 1970 00:00:00
    vestingDuration = SafeCast.toUint32(44582400); // @dev 18 month Tuesday, 1 June 1971 00:00:00

    vestingPosition = createVestingPosition(amount, beneficiary, startTimestamp, cliffDuration, vestingDuration);
  }

  function ffi_vestedAmount(uint256 blockTimestamp) private returns (uint256 vestedAmountRust) {
    string[] memory inputs = new string[](10);
    inputs[0] = "cargo";
    inputs[1] = "run";
    inputs[2] = "--quiet";
    inputs[3] = "--manifest-path";
    inputs[4] = "test/differential/vesting_lib/Cargo.toml";
    inputs[5] = amount.toString();
    inputs[6] = blockTimestamp.toString();
    inputs[7] = uint256(startTimestamp).toString();
    inputs[8] = uint256(startTimestamp + SafeCast.toUint48(cliffDuration)).toString();
    inputs[9] = uint256(cliffDuration + vestingDuration).toString(); // @dev 60220800 - 2 years
       
    bytes memory result = vm.ffi(inputs);    

    vestedAmountRust = abi.decode(result, (uint256));
  }

  function test_vestedAmount(uint256 blockTimestamp) external {
    uint48 maxClaimTime = startTimestamp + (SafeCast.toUint48(vestingPosition.totalDuration)*15); // @dev ~30 years for claiming
    blockTimestamp = bound(blockTimestamp, vestingPosition.startTimestamp, maxClaimTime);
    vm.warp(blockTimestamp);

    uint256 vestedAmountRust = ffi_vestedAmount(block.timestamp);
    uint256 vestedAmountSol = releasableAmount(0);

    console.logUint(vestedAmountRust);
    console.logUint(vestedAmountSol);

    assertEq(vestedAmountRust, vestedAmountSol);
  }
}
