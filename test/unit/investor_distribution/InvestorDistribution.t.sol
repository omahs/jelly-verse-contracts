// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {InvestorDistribution} from "../../../contracts/InvestorDistribution.sol";
import {Chest} from "../../../contracts/Chest.sol";
import {ERC20Token} from "../../../contracts/test/ERC20Token.sol";

contract InvestorDistributionTest is Test {
    address immutable i_deployerAddress;

    address allocator = makeAddr("allocator");
    address testAddress = makeAddr("testAddress");

    Chest public chest;
    ERC20Token public jellyToken;
    InvestorDistribution public investorDistribution;

    constructor() {
        i_deployerAddress = msg.sender;
    }

    function setUp() public {
        uint256 fee = 10;
        uint128 maxBooster = 2e18;
        address owner = msg.sender;
        address pendingOwner = testAddress;
        uint32 timeFactor = 7 days;

        jellyToken = new ERC20Token("Jelly", "JELLY");
        investorDistribution = new InvestorDistribution(
            address(jellyToken),
            owner,
            pendingOwner
        );
        chest = new Chest(
            address(jellyToken),
            allocator,
            address(investorDistribution),
            fee,
            maxBooster,
            timeFactor,
            owner,
            pendingOwner
        );

        vm.prank(i_deployerAddress);
        investorDistribution.setChest(address(chest));

        vm.prank(address(investorDistribution));
        jellyToken.mint(2_000_000_000);
    }
    
    // UNIT TESTS
}
