// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import "forge-std/console.sol";
import {JellyToken} from "../../contracts/JellyToken.sol";

contract InvariantJellyToken is StdInvariant, Test {
    JellyToken public jellyToken;

    uint256 internal constant cap = 1_000_000_000;

    address internal defaultAdminRole;
    address internal vesting;
    address internal vestingJelly;
    address internal allocator;
    address internal minter;

    function setUp() public {
        defaultAdminRole = makeAddr("defaultAdminRole");
        vesting = makeAddr("vesting");
        vestingJelly = makeAddr("vestingJelly");
        allocator = makeAddr("allocator");
        minter = makeAddr("minter");

        jellyToken = new JellyToken(defaultAdminRole);

        vm.startPrank(defaultAdminRole);
        jellyToken.premint(vesting, vestingJelly, allocator, minter);
        vm.stopPrank();

        targetSender(defaultAdminRole);
    }

    function invariant_supplyAlwaysBellowCap() public {
        uint256 beforeAmount = jellyToken.totalSupply();
        uint256 mintAmount = cap * 10 ** 18 - beforeAmount;
        vm.startPrank(minter); 
        jellyToken.mint(minter, mintAmount);
        vm.stopPrank();
        assertLe(jellyToken.totalSupply(), cap * 10 ** 18);
    }

    function testFuzz_mint(uint256 _mintAmount) external {
        uint256 beforeAmount = jellyToken.totalSupply();
        _mintAmount = bound(_mintAmount, 1, cap * 10 ** 18 - beforeAmount);
        vm.startPrank(minter); 
        jellyToken.mint(defaultAdminRole, _mintAmount);
        uint256 afterAmount = jellyToken.totalSupply();
        vm.stopPrank();
        assertEq(beforeAmount + _mintAmount, afterAmount);
    }
}