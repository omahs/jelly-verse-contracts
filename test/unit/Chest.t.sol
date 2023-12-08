// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Chest} from "../../contracts/Chest.sol";
import {ERC20Token} from "../../contracts/test/ERC20Token.sol";

// TO-ADD:
// MIN_FREEZING_PERIOD added for regular chests(stake,increaseStake affected), DONE
// latestUnstake asserts in tests
// - tests specific for releaseableAmount in both cases
// booster, freezingPeriod assertions in stake,unstake..
// add jellyBalance checks in stake, unstake, increaseStake
// soulbound tests

contract ChestTest is Test {
    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;
    uint32 constant MIN_FREEZING_PERIOD_REGULAR_CHEST = 7 days;

    uint64 private constant DECIMALS = 1e18;
    uint64 private constant INITIAL_BOOSTER = 1 * DECIMALS;

    address immutable deployerAddress;

    address allocator = makeAddr("allocator"); // replace with mock
    address distributor = makeAddr("distributor"); // replace with mock
    address testAddress = makeAddr("testAddress");
    address approvedAddress = makeAddr("approvedAddress");
    address nonApprovedAddress = makeAddr("nonApprovedAddress");

    Chest public chest;
    ERC20Token public jellyToken;

    event Staked(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 freezedUntil,
        uint32 vestedDuration
    );
    event IncreaseStake(
        uint256 indexed tokenId,
        uint256 totalStaked,
        uint256 freezedUntil
    );
    event Unstake(uint256 indexed tokenId, uint256 amount, uint256 totalStaked);
    event SetFee(uint256 fee);
    event SetBoosterThreshold(uint256 boosterThreshold);
    event SetMinimalStakingPower(uint256 minimalStakingPower);
    event SetMaxBooster(uint256 maxBooster);

    error Chest__ZeroAddress();
    error Chest__InvalidStakingAmount();
    error Chest__NotAuthorizedForSpecial();
    error Chest__NonExistentToken();
    error Chest__NothingToIncrease();
    error Chest__InvalidFreezingPeriod();
    error Chest__CannotModifySpecial();
    error Chest__NonTransferrableToken();
    error Chest__NotAuthorizedForToken();
    error Chest__FreezingPeriodNotOver();
    error Chest__CannotUnstakeMoreThanReleasable();
    error Chest__NothingToUnstake();

    error Ownable__CallerIsNotOwner();

    modifier openPosition() {
        uint256 amount = 100;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD_REGULAR_CHEST;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());

        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
        _;
    }

    modifier openSpecialPosition() {
        uint256 amount = 100;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount + chest.fee());

        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );

        vm.stopPrank();
        _;
    }

    constructor() {
        deployerAddress = msg.sender;
    }

    function setUp() public {
        uint256 fee = 10;
        uint128 maxBooster = 2e18;
        address owner = msg.sender;
        address pendingOwner = testAddress;
        uint8 timeFactor = 2;

        jellyToken = new ERC20Token("Jelly", "JELLY");
        chest = new Chest(
            address(jellyToken),
            allocator,
            distributor,
            fee,
            maxBooster,
            timeFactor,
            owner,
            pendingOwner
        );

        vm.prank(allocator);
        jellyToken.mint(1000);

        vm.prank(distributor);
        jellyToken.mint(1000);

        vm.prank(testAddress);
        jellyToken.mint(1000);

        vm.prank(approvedAddress);
        jellyToken.mint(1000);

        vm.prank(nonApprovedAddress);
        jellyToken.mint(1000);
    }

    // UNIT TESTS
    function test_Deployment() external {
        assertEq(chest.fee(), 10);
        assertEq(chest.owner(), msg.sender);
        assertEq(chest.getPendingOwner(), testAddress);
        assertEq(chest.totalSupply(), 0);
    }

    // Regular chest stake tests

    function test_stake() external {
        uint256 amount = 100;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD_REGULAR_CHEST;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());

        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();

        assertEq(chest.ownerOf(0), testAddress);
        assertEq(chest.balanceOf(testAddress), 1);
        assertEq(chest.totalSupply(), 1);

        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            0
        );

        assertEq(vestingPosition.totalVestedAmount, amount);
        assertEq(vestingPosition.releasedAmount, 0);
        assertEq(
            vestingPosition.cliffTimestamp,
            block.timestamp + freezingPeriod
        );
        assertEq(vestingPosition.vestingDuration, 0);
        assertEq(vestingPosition.freezingPeriod, freezingPeriod);
        assertEq(vestingPosition.booster, INITIAL_BOOSTER);
        assertEq(vestingPosition.nerfParameter, 0);

        uint256 releasableAmount = chest.releasableAmount(0);
        assertEq(releasableAmount, 0);
    }

    function test_stakeEmitsStakedEvent() external {
        uint256 amount = 100;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD_REGULAR_CHEST;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());

        vm.expectEmit(true, true, false, true, address(chest));
        emit Staked(
            testAddress,
            0,
            amount,
            block.timestamp + freezingPeriod,
            0
        );

        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
    }

    function test_stakeInvalidStakingAmount() external {
        uint256 amount = 0; // @dev assigning to zero for clarity & better code readability
        uint32 freezingPeriod = MIN_FREEZING_PERIOD_REGULAR_CHEST;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidStakingAmount.selector);
        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
    }

    function test_stakeZeroAddress() external {
        uint256 amount = 100;
        uint32 freezingPeriod = 1000;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__ZeroAddress.selector);
        chest.stake(amount, address(0), freezingPeriod);

        vm.stopPrank();
    }

    function test_stakeZeroInvalidMinimumFreezingTime() external {
        uint256 amount = 100;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD_REGULAR_CHEST - 1;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());

        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
    }

    function test_stakeInvalidMaximumFreezingPeriod() external {
        uint256 amount = 100;
        uint32 freezingPeriod = MAX_FREEZING_PERIOD_REGULAR_CHEST + 1;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
    }

    // Special chest stake tests
    function test_stakeSpecial() external {
        uint256 amount = 100;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5; // 5/10 = 1/2

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount + chest.fee());

        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );

        vm.stopPrank();

        assertEq(chest.ownerOf(0), testAddress);
        assertEq(chest.balanceOf(testAddress), 1);
        assertEq(chest.totalSupply(), 1);

        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            0
        );

        assertEq(vestingPosition.totalVestedAmount, amount);
        assertEq(vestingPosition.releasedAmount, 0);
        assertEq(
            vestingPosition.cliffTimestamp,
            block.timestamp + freezingPeriod
        );
        assertEq(vestingPosition.vestingDuration, 1000);
        assertEq(vestingPosition.freezingPeriod, freezingPeriod);
        assertEq(vestingPosition.booster, INITIAL_BOOSTER);
        assertEq(vestingPosition.nerfParameter, nerfParameter);

        uint256 releasableAmount = chest.releasableAmount(0);
        assertEq(releasableAmount, 0);
    }

    function test_stakeSpecialZeroFreezingTime() external {
        uint256 amount = 100;
        uint32 freezingPeriod = 0;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(distributor);
        jellyToken.approve(address(chest), amount + chest.fee());

        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );

        vm.stopPrank();

        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            0
        );
        assertEq(vestingPosition.cliffTimestamp, block.timestamp + 1);

        uint256 releasableAmount = chest.releasableAmount(0);
        assertEq(releasableAmount, 0);

        vm.warp(block.timestamp + 1000 + 1);

        releasableAmount = chest.releasableAmount(0);
        assertEq(releasableAmount, amount);
    }

    function test_stakeSpecialEmitsStakedEvent() external {
        uint256 amount = 100;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount + chest.fee());

        vm.expectEmit(true, true, false, true, address(chest));
        emit Staked(
            testAddress,
            0,
            amount,
            block.timestamp + freezingPeriod,
            vestingDuration
        );

        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );

        vm.stopPrank();
    }

    function test_stakeSpecialInvalidStakingAmount() external {
        uint256 amount = 0;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidStakingAmount.selector);
        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );

        vm.stopPrank();
    }

    function test_stakeSpecialZeroAddress() external {
        uint256 amount = 100;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__ZeroAddress.selector);
        chest.stakeSpecial(
            amount,
            address(0),
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );

        vm.stopPrank();
    }

    function test_stakeSpecialInvalidFreezingPeriod() external {
        uint256 amount = 100;
        uint32 freezingPeriod = MAX_FREEZING_PERIOD_SPECIAL_CHEST + 1;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );

        vm.stopPrank();
    }

    // Regular chest increase stake tests
    function test_increaseStakeIncreaseStakingAmount() external openPosition {
        uint256 positionIndex = 0; // @dev assigning to zero for clarity & better code readability
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 0;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        vm.stopPrank();

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount + increaseAmountFor
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(
            vestingPositionAfter.freezingPeriod,
            vestingPositionBefore.freezingPeriod
        );
        assertEq(vestingPositionAfter.booster, vestingPositionBefore.booster);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );
    }

    function test_increaseStakeIncreaseStakingAmountApprovedAddress()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 0;

        vm.prank(testAddress);
        chest.approve(approvedAddress, positionIndex);

        vm.startPrank(approvedAddress);

        jellyToken.approve(address(chest), increaseAmountFor);

        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        vm.stopPrank();

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount + increaseAmountFor
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(
            vestingPositionAfter.freezingPeriod,
            vestingPositionBefore.freezingPeriod
        );
        assertEq(vestingPositionAfter.booster, vestingPositionBefore.booster);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );
    }

    function test_increaseStakeIncreaseFreezingPeriodFrozenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 boosterBefore = chest.getBooster(positionIndex);
        uint256 freezingPeriodBefore = chest.getFreezingPeriod(positionIndex);

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = 50;

        vm.prank(testAddress);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);
        uint256 boosterAfter = chest.getBooster(positionIndex);
        uint256 freezingPeriodAfter = chest.getFreezingPeriod(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            (vestingPositionBefore.cliffTimestamp - freezingPeriodBefore) +
                MAX_FREEZING_PERIOD_REGULAR_CHEST
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(boosterAfter, boosterBefore);
        assertEq(freezingPeriodAfter, MAX_FREEZING_PERIOD_REGULAR_CHEST);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );
    }

    function test_increaseStakeIncreaseFreezingPeriodOpenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 boosterBefore = chest.getBooster(positionIndex);

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = 50;

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

        vm.prank(testAddress);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);
        uint256 boosterAfter = chest.getBooster(positionIndex);
        uint256 freezingPeriodAfter = chest.getFreezingPeriod(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            (block.timestamp + increaseFreezingPeriodFor)
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertGt(boosterAfter, boosterBefore);
        assertEq(freezingPeriodAfter, increaseFreezingPeriodFor);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );
    }

    function test_increaseStakeIncreaseFreezingPeriodApprovedAddressFrozenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 boosterBefore = chest.getBooster(positionIndex);
        uint256 freezingPeriodBefore = chest.getFreezingPeriod(positionIndex);

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = 50;

        vm.prank(testAddress);
        chest.approve(approvedAddress, positionIndex);

        vm.prank(approvedAddress);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);
        uint256 boosterAfter = chest.getBooster(positionIndex);
        uint256 freezingPeriodAfter = chest.getFreezingPeriod(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            (vestingPositionBefore.cliffTimestamp - freezingPeriodBefore) +
                MAX_FREEZING_PERIOD_REGULAR_CHEST
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(boosterAfter, boosterBefore);
        assertEq(freezingPeriodAfter, MAX_FREEZING_PERIOD_REGULAR_CHEST);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );
    }

    function test_increaseStakeIncreaseFreezingPeriodApprovedAddressOpenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 boosterBefore = chest.getBooster(positionIndex);

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = 50;

        vm.prank(testAddress);
        chest.approve(approvedAddress, positionIndex);

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

        vm.prank(approvedAddress);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);
        uint256 boosterAfter = chest.getBooster(positionIndex);
        uint256 freezingPeriodAfter = chest.getFreezingPeriod(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            (block.timestamp + increaseFreezingPeriodFor)
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertGt(boosterAfter, boosterBefore);
        assertEq(freezingPeriodAfter, increaseFreezingPeriodFor);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );
    }

    function test_increaseStakeIncreaseStakingAmountAndFreezingPeriodFrozenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 boosterBefore = chest.getBooster(positionIndex);
        uint256 freezingPeriodBefore = chest.getFreezingPeriod(positionIndex);

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 50;

        uint256 totalVestedAmountBefore = vestingPositionBefore
            .totalVestedAmount;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
        vm.stopPrank();

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);
        uint256 boosterAfter = chest.getBooster(positionIndex);
        uint256 freezingPeriodAfter = chest.getFreezingPeriod(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            totalVestedAmountBefore + increaseAmountFor
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            (vestingPositionBefore.cliffTimestamp - freezingPeriodBefore) +
                MAX_FREEZING_PERIOD_REGULAR_CHEST
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(boosterAfter, boosterBefore);
        assertEq(freezingPeriodAfter, MAX_FREEZING_PERIOD_REGULAR_CHEST);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );
    }

    function test_increaseStakeIncreaseStakingAmountAndFreezingPeriodOpenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 50;

        uint256 totalVestedAmountBefore = vestingPositionBefore
            .totalVestedAmount;

        uint256 boosterBefore = chest.getBooster(positionIndex);

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
        vm.stopPrank();

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);
        uint256 boosterAfter = chest.getBooster(positionIndex);
        uint256 freezingPeriodAfter = chest.getFreezingPeriod(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            totalVestedAmountBefore + increaseAmountFor
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            block.timestamp + increaseFreezingPeriodFor
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertGt(boosterAfter, boosterBefore);
        assertEq(freezingPeriodAfter, increaseFreezingPeriodFor);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );
    }

    function test_increaseStakeEmitsIncreaseStakeEventFrozenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 50;

        uint256 totalVestedAmountBefore = vestingPositionBefore
            .totalVestedAmount;

        uint256 cliffTimestampBefore = vestingPositionBefore.cliffTimestamp;

        uint256 freezingPeriodBefore = chest.getFreezingPeriod(positionIndex);

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        vm.expectEmit(true, false, false, true, address(chest));
        emit IncreaseStake(
            positionIndex,
            totalVestedAmountBefore + increaseAmountFor,
            (cliffTimestampBefore - freezingPeriodBefore) + // time of position creation
                MAX_FREEZING_PERIOD_REGULAR_CHEST
        );

        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        vm.stopPrank();
    }

    function test_increaseStakeEmitsIncreaseStakeEventOpenChest()
        external
        openPosition
    {
        {
            uint256 positionIndex = 0;
            Chest.VestingPosition memory vestingPositionBefore = chest
                .getVestingPosition(positionIndex);

            uint256 increaseAmountFor = 50;
            uint32 increaseFreezingPeriodFor = 50;

            uint256 totalVestedAmountBefore = vestingPositionBefore
                .totalVestedAmount;

            uint256 cliffTimestampBefore = vestingPositionBefore.cliffTimestamp;

            vm.warp(cliffTimestampBefore + 1);

            vm.startPrank(testAddress);
            jellyToken.approve(address(chest), increaseAmountFor);

            vm.expectEmit(true, false, false, true, address(chest));
            emit IncreaseStake(
                positionIndex,
                totalVestedAmountBefore + increaseAmountFor,
                block.timestamp + increaseFreezingPeriodFor
            );

            chest.increaseStake(
                positionIndex,
                increaseAmountFor,
                increaseFreezingPeriodFor
            );

            vm.stopPrank();
        }
    }

    function test_increaseStakeNotAuthorizedForToken() external openPosition {
        uint positionIndex = 0;

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 0;

        vm.prank(nonApprovedAddress);

        vm.expectRevert(Chest__NotAuthorizedForToken.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
    }

    function test_increaseStakeNonExistentToken() external {
        uint positionIndex = 0;

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 0;

        vm.expectRevert("ERC721: invalid token ID");
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
    }

    function test_increaseStakeNothingToIncrease() external openPosition {
        uint256 positionIndex = 0;

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = 0;

        vm.prank(testAddress);
        vm.expectRevert(Chest__NothingToIncrease.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
    }

    function test_increaseStakeInvalidFreezingPeriod() external openPosition {
        uint256 positionIndex = 0;

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = MAX_FREEZING_PERIOD_REGULAR_CHEST +
            1;

        vm.prank(testAddress);
        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
    }

    // Special chest increase stake tests
    function test_increaseStakeSpecialChest() external openSpecialPosition {
        uint256 positionIndex = 0;

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 0;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        vm.expectRevert(Chest__CannotModifySpecial.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        vm.stopPrank();
    }

    // Regular chest unstake tests
    function test_unstake() external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 balanceBeforeAccount = jellyToken.balanceOf(testAddress);
        uint256 balanceBeforeChest = jellyToken.balanceOf(address(chest));

        uint256 unstakeAmount = 50;

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

        vm.prank(testAddress);
        chest.unstake(positionIndex, unstakeAmount);

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount + unstakeAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, unstakeAmount);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(vestingPositionAfter.freezingPeriod, 0);
        assertEq(vestingPositionAfter.booster, INITIAL_BOOSTER);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );

        assertEq(
            jellyToken.balanceOf(testAddress),
            balanceBeforeAccount + unstakeAmount
        );

        assertEq(
            jellyToken.balanceOf(address(chest)),
            balanceBeforeChest - unstakeAmount
        );
    }

    function test_unstakeApprovedAddress() external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 balanceBeforeAccount = jellyToken.balanceOf(approvedAddress);
        uint256 balanceBeforeChest = jellyToken.balanceOf(address(chest));

        uint256 unstakeAmount = 50;

        vm.prank(testAddress);
        chest.approve(approvedAddress, positionIndex);

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

        vm.prank(approvedAddress);
        chest.unstake(positionIndex, unstakeAmount);

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount + unstakeAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, unstakeAmount);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );

        assertEq(vestingPositionAfter.freezingPeriod, 0);
        assertEq(vestingPositionAfter.booster, INITIAL_BOOSTER);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );

        assertEq(
            jellyToken.balanceOf(approvedAddress),
            balanceBeforeAccount + unstakeAmount
        );

        assertEq(
            jellyToken.balanceOf(address(chest)),
            balanceBeforeChest - unstakeAmount
        );
    }

    function test_unstakeEmitsUnstakeEvent() external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 totalVestedAmountBefore = vestingPosition.totalVestedAmount;

        uint256 unstakeAmount = 50;

        vm.warp(vestingPosition.cliffTimestamp + 1);

        vm.expectEmit(true, false, false, true, address(chest));
        emit Unstake(
            positionIndex,
            unstakeAmount,
            totalVestedAmountBefore - unstakeAmount
        );

        vm.prank(testAddress);
        chest.unstake(positionIndex, unstakeAmount);
    }

    function test_unstakeNotAuthorizedForToken() external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 unstakeAmount = 50;

        vm.warp(vestingPosition.cliffTimestamp + 1);

        vm.prank(nonApprovedAddress);
        vm.expectRevert(Chest__NotAuthorizedForToken.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    function test_unstakeNothingToUnstake() external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 unstakeAmount = 50;

        vm.warp(vestingPosition.cliffTimestamp - 1);

        vm.prank(testAddress);
        vm.expectRevert(Chest__NothingToUnstake.selector);
        chest.unstake(positionIndex, unstakeAmount);

        vm.warp(vestingPosition.cliffTimestamp + 1);

        unstakeAmount = 0;

        vm.prank(testAddress);
        vm.expectRevert(Chest__NothingToUnstake.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    function test_unstakeCannotUnstakeMoreThanReleasable()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 unstakeAmount = vestingPosition.totalVestedAmount + 1;

        vm.warp(vestingPosition.cliffTimestamp + 1);

        vm.prank(testAddress);
        vm.expectRevert(Chest__CannotUnstakeMoreThanReleasable.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    // Special chest unstake tests
    function test_unstakeSpecialChest() external openSpecialPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 balanceBeforeAccount = jellyToken.balanceOf(testAddress);
        uint256 balanceBeforeChest = jellyToken.balanceOf(address(chest));

        uint256 unstakeAmount = 50;

        vm.warp(
            vestingPositionBefore.cliffTimestamp +
                vestingPositionBefore.vestingDuration
        );

        vm.prank(testAddress);
        chest.unstake(positionIndex, unstakeAmount);

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount + unstakeAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, unstakeAmount);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );

        assertEq(vestingPositionAfter.freezingPeriod, 0);
        assertEq(vestingPositionAfter.booster, INITIAL_BOOSTER);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );

        assertEq(
            jellyToken.balanceOf(testAddress),
            balanceBeforeAccount + unstakeAmount
        );

        assertEq(
            jellyToken.balanceOf(address(chest)),
            balanceBeforeChest - unstakeAmount
        );
    }

    function test_unstakeSpecialChestApprovedAddress()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 balanceBeforeAccount = jellyToken.balanceOf(approvedAddress);
        uint256 balanceBeforeChest = jellyToken.balanceOf(address(chest));

        uint256 unstakeAmount = 50;

        vm.prank(testAddress);
        chest.approve(approvedAddress, positionIndex);

        vm.warp(
            vestingPositionBefore.cliffTimestamp +
                vestingPositionBefore.vestingDuration
        );

        vm.prank(approvedAddress);
        chest.unstake(positionIndex, unstakeAmount);

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        assertEq(
            vestingPositionAfter.totalVestedAmount + unstakeAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, unstakeAmount);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );

        assertEq(vestingPositionAfter.freezingPeriod, 0);
        assertEq(vestingPositionAfter.booster, INITIAL_BOOSTER);
        assertEq(
            vestingPositionAfter.nerfParameter,
            vestingPositionBefore.nerfParameter
        );

        assertEq(
            jellyToken.balanceOf(approvedAddress),
            balanceBeforeAccount + unstakeAmount
        );

        assertEq(
            jellyToken.balanceOf(address(chest)),
            balanceBeforeChest - unstakeAmount
        );
    }

    function test_unstakeSpecialChestEmitsUnstakeEvent()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 totalVestedAmountBefore = vestingPosition.totalVestedAmount;

        uint256 unstakeAmount = 50;

        vm.warp(
            vestingPosition.cliffTimestamp + vestingPosition.vestingDuration
        );

        vm.expectEmit(true, false, false, true, address(chest));
        emit Unstake(
            positionIndex,
            unstakeAmount,
            totalVestedAmountBefore - unstakeAmount
        );

        vm.prank(testAddress);
        chest.unstake(positionIndex, unstakeAmount);
    }

    function test_unstakeSpecialChestNotAuthorizedForToken()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 unstakeAmount = 50;

        vm.warp(vestingPosition.cliffTimestamp + 1);

        vm.prank(nonApprovedAddress);
        vm.expectRevert(Chest__NotAuthorizedForToken.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    function test_unstakeSpecialChestNothingToUnstake()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 unstakeAmount = 50;

        vm.warp(vestingPosition.cliffTimestamp - 1);

        vm.prank(testAddress);
        vm.expectRevert(Chest__NothingToUnstake.selector);
        chest.unstake(positionIndex, unstakeAmount);

        vm.warp(vestingPosition.cliffTimestamp + 1);

        unstakeAmount = 0;

        vm.prank(testAddress);
        vm.expectRevert(Chest__NothingToUnstake.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    function test_unstakeSpecialChestCannotUnstakeMoreThanReleasable()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 unstakeAmount = vestingPosition.totalVestedAmount + 1;

        vm.warp(
            vestingPosition.cliffTimestamp + vestingPosition.vestingDuration
        );

        vm.prank(testAddress);
        vm.expectRevert(Chest__CannotUnstakeMoreThanReleasable.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    function test_calculateBooster() external openPosition {} // TO-DO

    function test_setFee() external {
        uint256 newFee = 100;

        vm.prank(deployerAddress);
        chest.setFee(newFee);

        assertEq(chest.fee(), newFee);
    }

    function test_setFeeEmitsSetFeeEvent() external {
        uint256 newFee = 100;

        vm.prank(deployerAddress);

        vm.expectEmit(false, false, false, true, address(chest));
        emit SetFee(newFee);

        chest.setFee(newFee);
    }

    function test_setFeeCallerIsNotOwner() external {
        uint256 newFee = 100;

        vm.prank(testAddress);
        vm.expectRevert(Ownable__CallerIsNotOwner.selector);

        chest.setFee(newFee);
    }
}
