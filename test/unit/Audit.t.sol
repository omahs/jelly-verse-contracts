// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {JellyTokenDeployer} from "../../contracts/JellyTokenDeployer.sol";
import {JellyToken} from "../../contracts/JellyToken.sol";
import {OfficialPoolsRegister} from "../../contracts/OfficialPoolsRegister.sol";
import {OfficialPoolsRegisterNew} from "../../contracts/OfficialPoolsRegisterNew.sol";
import {VestingLib} from "../../contracts/utils/VestingLib.sol";
import {Minter} from "../../contracts/Minter.sol";
import {PoolParty} from "../../contracts/Allocator.sol";

import "forge-std/console.sol";

contract AuditTest is Test, VestingLib {
    address deployer = makeAddr("deployer");
    address vestingTeam = makeAddr("vestingTeam");
    address vestingInvestor = makeAddr("vestingInvestor");
    address allocator = makeAddr("allocator");
    address minterContract = makeAddr("minterContract");

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 constant USD_JELLY_RATIO = 1;

    JellyTokenDeployer public jellyTokenDeployer;
    JellyToken public jellyToken;
    OfficialPoolsRegister public or;
    OfficialPoolsRegisterNew public orn;
    VestingLib public vestingLib;
    Minter public minter;
    PoolParty public poolParty;

    function setUp() external {
        jellyTokenDeployer = new JellyTokenDeployer();
        jellyToken = new JellyToken(deployer); // address(0) can be passed as a defaultAdminRole
        vm.startPrank(deployer);
        or = new OfficialPoolsRegister(deployer, address(0));
        orn = new OfficialPoolsRegisterNew(deployer, address(0));
        minter = new Minter(
            address(jellyToken),
            address(or),
            deployer,
            address(0)
        );
        poolParty = new PoolParty(
            address(jellyToken),
            address(0),
            USD_JELLY_RATIO,
            address(0),
            bytes32(0),
            deployer,
            address(0)
        );
        vm.stopPrank();
    }

    function test_zeroAddress() external {
        jellyTokenDeployer.deployJellyToken("0x01", address(0));
        bool hasRole = jellyToken.hasRole(
            jellyToken.DEFAULT_ADMIN_ROLE(),
            address(0)
        );
        assert(hasRole == false);
    }

    function testGas() external {
        // Generate 50 poolIds
        bytes32[] memory poolIds = new bytes32[](50);
        for (uint256 i = 0; i < 50; i++) {
            poolIds[i] = bytes32(keccak256(abi.encode(i)));
        }
        vm.startPrank(deployer);
        // Generate 50 Pool structs
        OfficialPoolsRegister.Pool[]
            memory pools = new OfficialPoolsRegister.Pool[](50);
        for (uint256 i = 0; i < 50; i++) {
            pools[i] = OfficialPoolsRegister.Pool({
                poolId: bytes32(keccak256(abi.encode(i))),
                weight: 0
            });
        }
        uint256 start = gasleft();
        or.registerOfficialPool(pools);
        uint256 gasUsed2 = start - gasleft();
        console.log(gasUsed2);

        start = gasleft();
        orn.registerOfficialPools(poolIds, new uint32[](50));
        uint256 gasUsed = start - gasleft();
        console.log(gasUsed);
        vm.stopPrank();
    }

    function testGas2() external {
        // Generate 50 poolIds
        bytes32[] memory poolIds = new bytes32[](50);
        for (uint256 i = 0; i < 50; i++) {
            poolIds[i] = bytes32(i);
        }
        vm.startPrank(deployer);
        uint256 start = gasleft();
        orn.registerOfficialPools(poolIds, new uint32[](50));
        uint256 gasUsed = start - gasleft();
        console.log(gasUsed);

        // Generate 50 Pool structs
        OfficialPoolsRegister.Pool[]
            memory pools = new OfficialPoolsRegister.Pool[](50);
        for (uint256 i = 0; i < 50; i++) {
            pools[i] = OfficialPoolsRegister.Pool({
                poolId: bytes32(i),
                weight: 0
            });
        }
        start = gasleft();
        or.registerOfficialPool(pools);
        uint256 gasUsed2 = start - gasleft();
        console.log(gasUsed2);
        vm.stopPrank();

        // now let's try to add new pool
    }

    function test_vestingLib() external {
        address beneficiary = msg.sender;
        uint256 amount = 1000;
        uint32 cliffDuration = 100;
        uint32 vestingDuration = 100;

        uint256 withrawAmount = 500;

        // Intitial position state
        // totalVestedAmount = 1000
        // releasedAmount = 0
        // cliffDuration = 100
        // vestingDuration = 100
        VestingLib.VestingPosition
            memory vestingPosition = createVestingPosition(
                amount,
                beneficiary,
                cliffDuration,
                vestingDuration
            );
        uint256 positionIndex = index - 1;

        vm.warp(vestingPosition.cliffTimestamp + vestingDuration);

        updateReleasedAmount(0, withrawAmount);

        // now imagine update of position happens
        vestingPositions[positionIndex].totalVestedAmount += amount; // totalVestedAmount is now 2x amount
        vestingPositions[positionIndex].cliffTimestamp = uint48(
            block.timestamp + cliffDuration
        );

        vm.warp(vestingPositions[positionIndex].cliffTimestamp + 1);
        vm.expectRevert();
        uint256 releasableAmount = releasableAmount(0);
    }

    function test_jellyToken() external {
        vm.startPrank(deployer);
        jellyToken.premint(
            vestingTeam,
            vestingInvestor,
            allocator,
            minterContract
        );
        jellyToken.mint(deployer, jellyToken.cap() - jellyToken.totalSupply());

        console.log(jellyToken.totalSupply());

        // vm.expectRevert();
        jellyToken.burn(1);
        jellyToken.mint(msg.sender, 1);

        jellyToken.grantRole(MINTER_ROLE, address(0));

        vm.stopPrank();
    }

    function test_poolParty() external {
        vm.startPrank(deployer);
        jellyToken.premint(
            vestingTeam,
            vestingInvestor,
            allocator,
            minterContract
        );
        jellyToken.mint(deployer, jellyToken.cap() - jellyToken.totalSupply());
        jellyToken.transfer(address(poolParty), 1000);

        assertEq(jellyToken.balanceOf(address(poolParty)), 1000);

        poolParty.endBuyingPeriod();
        assertEq(jellyToken.balanceOf(address(poolParty)), 0);
        assertEq(jellyToken.totalSupply(), jellyToken.cap() - 1000);
        vm.stopPrank();
    }
}
