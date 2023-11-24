// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Chest} from "../../contracts/Chest.sol";
import {ERC20Token} from "../../contracts/test/ERC20Token.sol";

// TO-ADD:
// - tests specific for releaseableAmount in both cases

contract ChestTest is Test {
    uint256 constant MIN_STAKING_AMOUNT = 100; // change to real value if there is minimum
    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;

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
    error Chest__NothingToIncrease();
    error Chest__InvalidFreezingPeriod();
    error Chest__NonTransferrableToken();
    error Chest__NotAuthorizedForToken();
    error Chest__FreezingPeriodNotOver();
    error Chest__CannotUnstakeMoreThanReleasable();
    error Chest__NothingToUnstake();

    error Ownable__CallerIsNotOwner();

    modifier openPosition() {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 1000;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
        _;
    }

    modifier openSpecialPosition() {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount);

        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration
        );

        vm.stopPrank();
        _;
    }

    constructor() {
        deployerAddress = msg.sender;
    }

    function setUp() public {
        uint256 fee = 0;
        uint256 boosterThreshold = 1000;
        uint256 minimalStakingPower = 1;
        uint256 maxBooster = 10;
        uint256 timeFactor = 2;
        address owner = msg.sender;
        address pendingOwner = testAddress;

        jellyToken = new ERC20Token("Jelly", "JELLY");
        chest = new Chest(
            address(jellyToken),
            allocator,
            distributor,
            fee,
            boosterThreshold,
            minimalStakingPower,
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
        assertEq(chest.fee(), 0);
        assertEq(chest.owner(), msg.sender);
        assertEq(chest.getPendingOwner(), testAddress);
        assertEq(chest.totalSupply(), 0);
    }

    // Regular chest stake tests
    function test_stake() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 1000;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();

        assertEq(chest.ownerOf(0), testAddress);
        assertEq(chest.balanceOf(testAddress), 1);
        assertEq(chest.totalSupply(), 1);

        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            0
        );

        assertEq(vestingPosition.beneficiary, testAddress);
        assertEq(vestingPosition.totalVestedAmount, amount);
        assertEq(vestingPosition.releasedAmount, 0);
        assertEq(
            vestingPosition.cliffTimestamp,
            block.timestamp + freezingPeriod
        );
        assertEq(vestingPosition.vestingDuration, 0);

        uint256 releasableAmount = chest.releasableAmount(0);
        assertEq(releasableAmount, 0);
    }

    function test_stakeZeroFreezingTime() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 0; // @dev assigning to zero for clarity & better code readability

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();

        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            0
        );
        assertEq(vestingPosition.cliffTimestamp, block.timestamp + 1);

        uint256 releasableAmount = chest.releasableAmount(0);
        assertEq(releasableAmount, 0);

        vm.warp(block.timestamp + 1);

        releasableAmount = chest.releasableAmount(0);
        assertEq(releasableAmount, amount);
    }

    function test_stakeEmitsStakedEvent() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 1000;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

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
        uint256 amount = MIN_STAKING_AMOUNT - 1;
        uint32 freezingPeriod = 1000;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidStakingAmount.selector);
        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
    }

    function test_stakeZeroAddress() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 1000;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__ZeroAddress.selector);
        chest.stake(amount, address(0), freezingPeriod);

        vm.stopPrank();
    }

    // Special chest stake tests
    function test_stakeSpecial() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount);

        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration
        );

        vm.stopPrank();

        assertEq(chest.ownerOf(0), testAddress);
        assertEq(chest.balanceOf(testAddress), 1);
        assertEq(chest.totalSupply(), 1);

        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            0
        );

        assertEq(vestingPosition.beneficiary, testAddress);
        assertEq(vestingPosition.totalVestedAmount, amount);
        assertEq(vestingPosition.releasedAmount, 0);
        assertEq(
            vestingPosition.cliffTimestamp,
            block.timestamp + freezingPeriod
        );
        assertEq(vestingPosition.vestingDuration, 1000);

        uint256 releasableAmount = chest.releasableAmount(0);
        assertEq(releasableAmount, 0);
    }

    function test_stakeSpecialZeroFreezingTime() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 0;
        uint32 vestingDuration = 1000;

        vm.startPrank(distributor);
        jellyToken.approve(address(chest), amount);

        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration
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
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount);

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
            vestingDuration
        );

        vm.stopPrank();
    }

    function test_stakeSpecialInvalidStakingAmount() external {
        uint256 amount = MIN_STAKING_AMOUNT - 1;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidStakingAmount.selector);
        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration
        );

        vm.stopPrank();
    }

    function test_stakeSpecialZeroAddress() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = 1000;
        uint32 vestingDuration = 1000;

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__ZeroAddress.selector);
        chest.stakeSpecial(amount, address(0), freezingPeriod, vestingDuration);

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
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
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
    }

    function test_increaseStakeIncreaseFreezingPeriod() external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

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

        assertEq(
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp + increaseFreezingPeriodFor
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
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
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
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
    }

    function test_increaseStakeIncreaseFreezingPeriodApprovedAddress()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

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

        assertEq(
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp + increaseFreezingPeriodFor
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
    }

    function test_increaseStakeEmitsIncreaseStakeEvent() external openPosition {
        uint256 positionIndex = 0;

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 50;

        uint256 totalVestedAmountBefore = chest
            .getVestingPosition(positionIndex)
            .totalVestedAmount;

        uint256 cliffTimestampBefore = chest
            .getVestingPosition(positionIndex)
            .cliffTimestamp;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        vm.expectEmit(true, false, false, true, address(chest));
        emit IncreaseStake(
            positionIndex,
            totalVestedAmountBefore + increaseAmountFor,
            cliffTimestampBefore + increaseFreezingPeriodFor
        );

        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        vm.stopPrank();
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
    function test_increaseStakeSpecialChestIncreaseStakingAmount()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;
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
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
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
    }

    function test_increaseStakeSpecialChestIncreaseFreezingPeriod()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

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

        assertEq(
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp + increaseFreezingPeriodFor
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
    }

    function test_increaseStakeSpecialChestIncreaseStakingAmountApprovedAddress()
        external
        openSpecialPosition
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
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
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
    }

    function test_increaseStakeSpecialChestIncreaseFreezingPeriodApprovedAddress()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

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

        assertEq(
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp + increaseFreezingPeriodFor
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
    }

    function test_increaseStakeSpecialChestEmitsIncreaseStakeEvent()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 50;

        uint256 totalVestedAmountBefore = chest
            .getVestingPosition(positionIndex)
            .totalVestedAmount;

        uint256 cliffTimestampBefore = chest
            .getVestingPosition(positionIndex)
            .cliffTimestamp;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        vm.expectEmit(true, false, false, true, address(chest));
        emit IncreaseStake(
            positionIndex,
            totalVestedAmountBefore + increaseAmountFor,
            cliffTimestampBefore + increaseFreezingPeriodFor
        );

        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        vm.stopPrank();
    }

    function test_increaseStakeSpecialChestNotAuthorizedForToken()
        external
        openSpecialPosition
    {
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

    function test_increaseStakeSpecialChestNothingToIncrease()
        external
        openSpecialPosition
    {
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

    function test_increaseStakeSpecialChestInvalidFreezingPeriod()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = MAX_FREEZING_PERIOD_SPECIAL_CHEST +
            1;

        vm.prank(testAddress);
        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
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
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
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

        assertEq(chest.getLatestUnstake(positionIndex), block.timestamp);

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
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
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

        assertEq(chest.getLatestUnstake(positionIndex), block.timestamp);

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
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
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

        assertEq(chest.getLatestUnstake(positionIndex), block.timestamp);

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
            vestingPositionAfter.beneficiary,
            vestingPositionBefore.beneficiary
        );
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

        assertEq(chest.getLatestUnstake(positionIndex), block.timestamp);

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
