// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Minter} from "../../../contracts/Minter.sol";
import {Strings} from "../../../contracts/vendor/openzeppelin/v4.9.0/utils/Strings.sol";
import {SafeCast} from "../../../contracts/vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";

contract MinterDifferentialTest is Test {
  using Strings for int256;

  Minter public minter;

  function setUp() public {
    address _jellyToken = makeAddr("jellyToken");
    address _stakingRewardsContract = makeAddr("stakingRewardsContract");
    address _ownerAddress = makeAddr("owner");
    address _pendingOwnerAddress = makeAddr("pendingOwner");
    minter = new Minter(_jellyToken, _stakingRewardsContract, _ownerAddress, _pendingOwnerAddress);
  }

  function test_calculateMintAmount(int256 daysSinceMintingStarted) external {  
    daysSinceMintingStarted = bound(daysSinceMintingStarted, 0, 100_000);

    uint256 mintAmountRust = ffi_minter(daysSinceMintingStarted);
    uint256 mintAmountSol = minter.calculateMintAmount(daysSinceMintingStarted);

    console.logUint(mintAmountRust);
    console.logUint(mintAmountSol);

    assertEq(mintAmountRust, mintAmountSol);
  }

  function ffi_minter(int256 daysSinceMintingStarted) private returns (uint256 mintAmount) {
    string[] memory inputs = new string[](10);
    inputs[0] = "cargo";
    inputs[1] = "run";
    inputs[2] = "--quiet";
    inputs[3] = "--manifest-path";
    inputs[4] = "test/differential/minter/Cargo.toml";
    inputs[5] = daysSinceMintingStarted.toString();
       
    bytes memory result = vm.ffi(inputs);    

    return abi.decode(result, (uint256));
  }
}