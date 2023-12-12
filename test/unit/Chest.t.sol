// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Chest} from "../../contracts/Chest.sol";
import {ERC20Token} from "../../contracts/test/ERC20Token.sol";

// TO-ADD:
// - tests specific for releaseableAmount in both cases
// - calculations overflow/underflow

// contract for internal function testing
contract ChestHarness is Chest {
    constructor(
        address jellyToken,
        address allocator,
        address distributor,
        uint256 fee_,
        uint128 maxBooster_,
        uint8 timeFactor_,
        address owner,
        address pendingOwner
    )
        Chest(
            jellyToken,
            allocator,
            distributor,
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

    function exposed_calculatePower(
        uint256 timestamp,
        VestingPosition memory vestingPosition
    ) external view returns (uint256) {
        return calculatePower(timestamp, vestingPosition);
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
    address transferRecipientAddress = makeAddr("transferRecipientAddress");

    Chest public chest;
    ChestHarness public chestHarness;
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
    event FeeWithdrawn(address indexed beneficiary);

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
    error Chest__InvalidBoosterValue();

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
        chestHarness = new ChestHarness(
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
        assertEq(chest.totalFees(), 0);
        assertEq(chest.owner(), msg.sender);
        assertEq(chest.getPendingOwner(), testAddress);
        assertEq(chest.totalSupply(), 0);
        assertEq(chest.maxBooster(), 2e18);

        assertEq(chestHarness.fee(), 10);
        assertEq(chestHarness.totalFees(), 0);
        assertEq(chestHarness.owner(), msg.sender);
        assertEq(chestHarness.getPendingOwner(), testAddress);
        assertEq(chestHarness.totalSupply(), 0);
        assertEq(chestHarness.maxBooster(), 2e18);
    }

    // Regular chest stake tests

    function test_stake() external {
        uint256 amount = 100;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD_REGULAR_CHEST;

        uint256 totalFeesBefore = chest.totalFees();
        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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
        uint256 totalFeesAfter = chest.totalFees();
        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

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

        assertEq(totalFeesAfter, totalFeesBefore + chest.fee());

        assertEq(
            accountJellyBalanceAfter,
            accountJellyBalanceBefore - amount - chest.fee()
        );
        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore + amount + chest.fee()
        );

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

        uint256 totalFeesBefore = chest.totalFees();
        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(allocator);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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
        uint256 totalFeesAfter = chest.totalFees();
        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(allocator);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

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

        assertEq(totalFeesAfter, totalFeesBefore + chest.fee());

        assertEq(
            accountJellyBalanceAfter,
            accountJellyBalanceBefore - amount - chest.fee()
        );
        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore + amount + chest.fee()
        );

        uint256 releasableAmount = chest.releasableAmount(0);
        assertEq(releasableAmount, 0);
    }

    function test_stakeSpecialZeroFreezingTime() external {
        uint256 amount = 100;
        uint32 freezingPeriod = 0;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        uint256 totalFeesBefore = chest.totalFees();
        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(distributor);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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

        assertEq(chest.ownerOf(0), testAddress);
        assertEq(chest.balanceOf(testAddress), 1);
        assertEq(chest.totalSupply(), 1);

        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            0
        );
        uint256 totalFeesAfter = chest.totalFees();
        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(distributor);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

        assertEq(vestingPosition.totalVestedAmount, amount);
        assertEq(vestingPosition.releasedAmount, 0);

        assertEq(vestingPosition.cliffTimestamp, block.timestamp + 1);

        assertEq(vestingPosition.vestingDuration, 1000);
        assertEq(vestingPosition.freezingPeriod, 1);
        assertEq(vestingPosition.booster, INITIAL_BOOSTER);
        assertEq(vestingPosition.nerfParameter, nerfParameter);

        assertEq(totalFeesAfter, totalFeesBefore + chest.fee());

        assertEq(
            accountJellyBalanceAfter,
            accountJellyBalanceBefore - amount - chest.fee()
        );
        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore + amount + chest.fee()
        );

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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

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

        assertEq(
            accountJellyBalanceAfter,
            accountJellyBalanceBefore - increaseAmountFor
        );
        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore + increaseAmountFor
        );
    }

    function test_increaseStakeIncreaseStakingAmountApprovedAddress()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

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

        assertEq(
            accountJellyBalanceAfter,
            accountJellyBalanceBefore - increaseAmountFor
        );
        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore + increaseAmountFor
        );
    }

    function test_increaseStakeIncreaseFreezingPeriodFrozenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;
        uint256 freezingPeriodBefore = vestingPositionBefore.freezingPeriod;

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

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));
        uint256 boosterAfter = vestingPositionAfter.booster;
        uint256 freezingPeriodAfter = vestingPositionAfter.freezingPeriod;

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
        assertEq(accountJellyBalanceAfter, accountJellyBalanceBefore);
        assertEq(chestJellyBalanceAfter, chestJellyBalanceBefore);
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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;

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

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));
        uint256 boosterAfter = vestingPositionAfter.booster;
        uint256 freezingPeriodAfter = vestingPositionAfter.freezingPeriod;

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
        assertEq(accountJellyBalanceAfter, accountJellyBalanceBefore);
        assertEq(chestJellyBalanceAfter, chestJellyBalanceBefore);
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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;
        uint256 freezingPeriodBefore = vestingPositionBefore.freezingPeriod;

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

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));
        uint256 boosterAfter = vestingPositionAfter.booster;
        uint256 freezingPeriodAfter = vestingPositionAfter.freezingPeriod;

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
        assertEq(accountJellyBalanceAfter, accountJellyBalanceBefore);
        assertEq(chestJellyBalanceAfter, chestJellyBalanceBefore);
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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;

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

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));
        uint256 boosterAfter = vestingPositionAfter.booster;
        uint256 freezingPeriodAfter = vestingPositionAfter.freezingPeriod;

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
        assertEq(accountJellyBalanceAfter, accountJellyBalanceBefore);
        assertEq(chestJellyBalanceAfter, chestJellyBalanceBefore);
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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;
        uint256 freezingPeriodBefore = vestingPositionBefore.freezingPeriod;

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

        uint256 boosterAfter = vestingPositionAfter.booster;
        uint256 freezingPeriodAfter = vestingPositionAfter.freezingPeriod;

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
        // using direct calls for balance to avoid stack too deep error
        assertEq(
            jellyToken.balanceOf(testAddress),
            accountJellyBalanceBefore - increaseAmountFor
        );
        assertEq(
            jellyToken.balanceOf(address(chest)),
            chestJellyBalanceBefore + increaseAmountFor
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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = 50;

        uint256 totalVestedAmountBefore = vestingPositionBefore
            .totalVestedAmount;

        uint256 boosterBefore = vestingPositionBefore.booster;

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

        uint256 boosterAfter = vestingPositionAfter.booster;
        uint256 freezingPeriodAfter = vestingPositionAfter.freezingPeriod;

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
        // using direct calls for balances to avoid stack too deep error
        assertEq(
            jellyToken.balanceOf(testAddress),
            accountJellyBalanceBefore - increaseAmountFor
        );
        assertEq(
            jellyToken.balanceOf(address(chest)),
            chestJellyBalanceBefore + increaseAmountFor
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

        uint256 freezingPeriodBefore = vestingPositionBefore.freezingPeriod;

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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

        uint256 unstakeAmount = 50;

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

        vm.prank(testAddress);
        chest.unstake(positionIndex, unstakeAmount);

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

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
            accountJellyBalanceAfter,
            accountJellyBalanceBefore + unstakeAmount
        );

        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore - unstakeAmount
        );
    }

    function test_unstakeApprovedAddress() external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

        uint256 unstakeAmount = 50;

        vm.prank(testAddress);
        chest.approve(approvedAddress, positionIndex);

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

        vm.prank(approvedAddress);
        chest.unstake(positionIndex, unstakeAmount);

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

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
            accountJellyBalanceAfter,
            accountJellyBalanceBefore + unstakeAmount
        );

        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore - unstakeAmount
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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

        uint256 unstakeAmount = 50;

        vm.warp(
            vestingPositionBefore.cliffTimestamp +
                vestingPositionBefore.vestingDuration
        );

        vm.prank(testAddress);
        chest.unstake(positionIndex, unstakeAmount);

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

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
            accountJellyBalanceAfter,
            accountJellyBalanceBefore + unstakeAmount
        );
        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore - unstakeAmount
        );
    }

    function test_unstakeSpecialChestApprovedAddress()
        external
        openSpecialPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

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
            accountJellyBalanceAfter,
            accountJellyBalanceBefore + unstakeAmount
        );

        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore - unstakeAmount
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

    function test_setMaxBooster() external {
        uint128 newMaxBooster = 5e18;

        vm.prank(deployerAddress);
        chest.setMaxBooster(newMaxBooster);

        assertEq(chest.maxBooster(), newMaxBooster);
    }

    function test_setMaxBoosterEmitsSetMaxBoosterEvent() external {
        uint128 newMaxBooster = 5e18;

        vm.prank(deployerAddress);

        vm.expectEmit(false, false, false, true, address(chest));
        emit SetMaxBooster(newMaxBooster);

        chest.setMaxBooster(newMaxBooster);
    }

    function test_setMaxBoosterCallerIsNotOwner() external {
        uint128 newMaxBooster = 5e18;

        vm.prank(testAddress);
        vm.expectRevert(Ownable__CallerIsNotOwner.selector);

        chest.setMaxBooster(newMaxBooster);
    }

    function test_setMaxBoosterInvalidBoosterValue() external {
        uint128 newMaxBooster = INITIAL_BOOSTER - 1;

        vm.prank(deployerAddress);
        vm.expectRevert(Chest__InvalidBoosterValue.selector);

        chest.setMaxBooster(newMaxBooster);
    }

    function test_withdrawFees() external openPosition {
        uint256 deployerJellyBalanceBefore = jellyToken.balanceOf(
            deployerAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 totalFeesBefore = chest.totalFees();

        vm.prank(deployerAddress);
        chest.withdrawFees(deployerAddress);

        uint256 deployerJellyBalanceAfter = jellyToken.balanceOf(
            deployerAddress
        );
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));
        uint256 totalFeesAfter = chest.totalFees();

        assertEq(
            deployerJellyBalanceAfter,
            deployerJellyBalanceBefore + totalFeesBefore
        );
        assertEq(
            chestJellyBalanceAfter,
            chestJellyBalanceBefore - totalFeesBefore
        );
        assertEq(totalFeesAfter, 0);
    }

    function test_withdrawFeesEmitsFeeWithdrawnEvent() external openPosition {
        vm.prank(deployerAddress);

        vm.expectEmit(true, false, false, true, address(chest));
        emit FeeWithdrawn(deployerAddress);

        chest.withdrawFees(deployerAddress);
    }

    function test_withdrawFeesCallerIsNotOwner() external openPosition {
        vm.prank(testAddress);
        vm.expectRevert(Ownable__CallerIsNotOwner.selector);

        chest.withdrawFees(deployerAddress);
    }

    function test_transferFromChest() external openPosition {
        vm.prank(testAddress);

        vm.expectRevert(Chest__NonTransferrableToken.selector);
        chest.transferFrom(testAddress, transferRecipientAddress, 0);
    }

    function test_calculateBooster() external {
        uint256 amount = 100;
        uint32 freezingPeriodMinimum = MIN_FREEZING_PERIOD_REGULAR_CHEST;
        uint32 freezingPeriodMaximum = MAX_FREEZING_PERIOD_REGULAR_CHEST;
        uint8 nerfParameter = 10;
        uint32 vestingDuration = 0;

        // Position with minimum freezing period
        ChestHarness.VestingPosition
            memory vestingPositionMinimumFreezingPeriod = chestHarness
                .exposed_createVestingPosition(
                    amount,
                    freezingPeriodMinimum,
                    vestingDuration,
                    INITIAL_BOOSTER,
                    nerfParameter
                );

        uint128 booster = chestHarness.exposed_calculateBooster(
            vestingPositionMinimumFreezingPeriod
        );
        assertEq(booster, 1006392694063926940);
        // scopes to avoid stack too deep error
        {
            // Position at 1/8 of maximum freezing period
            uint32 freezingPeriodEighth = freezingPeriodMaximum / 8;
            ChestHarness.VestingPosition
                memory vestingPositionEighthFreezingPeriod = chestHarness
                    .exposed_createVestingPosition(
                        amount,
                        freezingPeriodEighth,
                        vestingDuration,
                        INITIAL_BOOSTER,
                        nerfParameter
                    );

            booster = chestHarness.exposed_calculateBooster(
                vestingPositionEighthFreezingPeriod
            );
            assertEq(booster, 1125000000000000000);
        }

        {
            // Position at 1/4 of maximum freezing period
            uint32 freezingPeriodQuarter = freezingPeriodMaximum / 4;
            ChestHarness.VestingPosition
                memory vestingPositionQuarterFreezingPeriod = chestHarness
                    .exposed_createVestingPosition(
                        amount,
                        freezingPeriodQuarter,
                        vestingDuration,
                        INITIAL_BOOSTER,
                        nerfParameter
                    );

            booster = chestHarness.exposed_calculateBooster(
                vestingPositionQuarterFreezingPeriod
            );
            assertEq(booster, 1250000000000000000);
        }

        {
            // Position at 3/8 of maximum freezing period
            uint32 freezingPeriodThreeEighths = (3 * freezingPeriodMaximum) / 8;
            ChestHarness.VestingPosition
                memory vestingPositionThreeEighthsFreezingPeriod = chestHarness
                    .exposed_createVestingPosition(
                        amount,
                        freezingPeriodThreeEighths,
                        vestingDuration,
                        INITIAL_BOOSTER,
                        nerfParameter
                    );

            booster = chestHarness.exposed_calculateBooster(
                vestingPositionThreeEighthsFreezingPeriod
            );
            assertEq(booster, 1375000000000000000);
        }

        {
            // Position at freezing period midpoint
            uint32 freezingPeriodMidpoint = freezingPeriodMaximum / 2;
            ChestHarness.VestingPosition
                memory vestingPositionMidpointFreezingPeriod = chestHarness
                    .exposed_createVestingPosition(
                        amount,
                        freezingPeriodMidpoint,
                        vestingDuration,
                        INITIAL_BOOSTER,
                        nerfParameter
                    );

            booster = chestHarness.exposed_calculateBooster(
                vestingPositionMidpointFreezingPeriod
            );
        }
        assertEq(booster, 1500000000000000000);

        {
            // Position at 5/8 of maximum freezing period
            uint32 freezingPeriodFiveEighths = (5 * freezingPeriodMaximum) / 8;
            ChestHarness.VestingPosition
                memory vestingPositionFiveEighthsFreezingPeriod = chestHarness
                    .exposed_createVestingPosition(
                        amount,
                        freezingPeriodFiveEighths,
                        vestingDuration,
                        INITIAL_BOOSTER,
                        nerfParameter
                    );

            booster = chestHarness.exposed_calculateBooster(
                vestingPositionFiveEighthsFreezingPeriod
            );
            assertEq(booster, 1625000000000000000);
        }

        {
            // Position at 3/4 of maximum freezing period
            uint32 freezingPeriodThreeQuarters = (3 * freezingPeriodMaximum) /
                4;
            ChestHarness.VestingPosition
                memory vestingPositionThreeQuartersFreezingPeriod = chestHarness
                    .exposed_createVestingPosition(
                        amount,
                        freezingPeriodThreeQuarters,
                        vestingDuration,
                        INITIAL_BOOSTER,
                        nerfParameter
                    );
            booster = chestHarness.exposed_calculateBooster(
                vestingPositionThreeQuartersFreezingPeriod
            );
            assertEq(booster, 1750000000000000000);
        }

        {
            // Position at 7/8 of maximum freezing period
            uint32 freezingPeriodSevenEighths = (7 * freezingPeriodMaximum) / 8;
            ChestHarness.VestingPosition
                memory vestingPositionSevenEighthsFreezingPeriod = chestHarness
                    .exposed_createVestingPosition(
                        amount,
                        freezingPeriodSevenEighths,
                        vestingDuration,
                        INITIAL_BOOSTER,
                        nerfParameter
                    );

            booster = chestHarness.exposed_calculateBooster(
                vestingPositionSevenEighthsFreezingPeriod
            );
            assertEq(booster, 1875000000000000000);
        }

        {
            // Position with maximum freezing period
            ChestHarness.VestingPosition
                memory vestingPositionMaximumFreezingPeriod = chestHarness
                    .exposed_createVestingPosition(
                        amount,
                        freezingPeriodMaximum,
                        vestingDuration,
                        INITIAL_BOOSTER,
                        nerfParameter
                    );

            booster = chestHarness.exposed_calculateBooster(
                vestingPositionMaximumFreezingPeriod
            );
            assertEq(booster, chestHarness.maxBooster());
        }
    }

    function test_calculateBoosterSpecialChest() external {
        uint256 amount = 100;
        uint32 freezingPeriodMinimum = MIN_FREEZING_PERIOD_REGULAR_CHEST;
        uint8 nerfParameter = 1;

        // Position with vesting duration > 0
        uint32 vestingDuration = 100;
        ChestHarness.VestingPosition
            memory vestingPositionVestingDurationZero = chestHarness
                .exposed_createVestingPosition(
                    amount,
                    freezingPeriodMinimum,
                    vestingDuration,
                    INITIAL_BOOSTER,
                    nerfParameter
                );

        uint128 booster = chestHarness.exposed_calculateBooster(
            vestingPositionVestingDurationZero
        );
        assertEq(booster, INITIAL_BOOSTER);
    }

    function test_calculatePowerChestWithMinimumFreezingPeriod() external {
        uint256 amount = 100;
        uint32 freezingPeriodMinimum = MIN_FREEZING_PERIOD_REGULAR_CHEST;
        uint8 nerfParameter = 10;

        // Regular chest position with minimum freezing period
        uint32 vestingDuration = 0;
        uint32 freezingPeriod = freezingPeriodMinimum;
        ChestHarness.VestingPosition
            memory vestingPositionRegularChestFreezingPeriodMinimum = chestHarness
                .exposed_createVestingPosition(
                    amount,
                    freezingPeriod,
                    vestingDuration,
                    INITIAL_BOOSTER,
                    nerfParameter
                );

        // Chest is open
        uint256 timestamp = block.timestamp +
            (freezingPeriod + vestingDuration);

        uint256 power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, 0);

        // Chest is frozen, start of freezing period check
        timestamp = block.timestamp;

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, amount * freezingPeriodMinimum);

        // Chest is frozen, 1/8 of freezing period passed check
        timestamp = block.timestamp + (freezingPeriodMinimum / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, ((amount * freezingPeriodMinimum) * 7) / 8);

        // Chest is frozen, 1/4 of freezing period passed check
        timestamp = block.timestamp + (freezingPeriodMinimum / 4);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, ((amount * freezingPeriodMinimum) * 3) / 4);

        // Chest is frozen, 3/8 of freezing period passed check
        timestamp = block.timestamp + ((3 * freezingPeriodMinimum) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, ((amount * freezingPeriodMinimum) * 5) / 8);

        // Chest is frozen, 1/2 of freezing period passed check
        timestamp = block.timestamp + (freezingPeriodMinimum / 2);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, ((amount * freezingPeriodMinimum) * 1) / 2);

        // Chest is frozen, 5/8 of freezing period passed check
        timestamp = block.timestamp + ((5 * freezingPeriodMinimum) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, ((amount * freezingPeriodMinimum) * 3) / 8);

        // Chest is frozen, 3/4 of freezing period passed check
        timestamp = block.timestamp + ((3 * freezingPeriodMinimum) / 4);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, ((amount * freezingPeriodMinimum) * 1) / 4);

        // Chest is frozen, 7/8 of freezing period passed check
        timestamp = block.timestamp + ((7 * freezingPeriodMinimum) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, (amount * freezingPeriodMinimum) / 8);

        // Chest is frozen, end of freezing period check
        timestamp = block.timestamp + freezingPeriodMinimum;

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, 0);
    }

    function test_calculatePowerChestWithMaximumFreezingPeriod() external {
        uint256 amount = 100;
        uint32 freezingPeriodMaximum = MAX_FREEZING_PERIOD_REGULAR_CHEST;
        uint8 nerfParameter = 10;

        // Regular chest position with maximum freezing period
        uint32 vestingDuration = 0;
        uint32 freezingPeriod = freezingPeriodMaximum;
        ChestHarness.VestingPosition
            memory vestingPositionRegularChestFreezingPeriodMaximum = chestHarness
                .exposed_createVestingPosition(
                    amount,
                    freezingPeriod,
                    vestingDuration,
                    INITIAL_BOOSTER,
                    nerfParameter
                );

        // Chest is open
        uint256 timestamp = block.timestamp +
            (freezingPeriod + vestingDuration);

        uint256 power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, 0);

        // Chest is frozen, start of freezing period check
        timestamp = block.timestamp;

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, amount * freezingPeriodMaximum);

        // Chest is frozen, 1/8 of freezing period passed check
        timestamp = block.timestamp + (freezingPeriodMaximum / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, ((amount * freezingPeriodMaximum) * 7) / 8);

        // Chest is frozen, 1/4 of freezing period passed check
        timestamp = block.timestamp + (freezingPeriodMaximum / 4);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, ((amount * freezingPeriodMaximum) * 3) / 4);

        // Chest is frozen, 3/8 of freezing period passed check
        timestamp = block.timestamp + ((3 * freezingPeriodMaximum) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, ((amount * freezingPeriodMaximum) * 5) / 8);

        // Chest is frozen, 1/2 of freezing period passed check
        timestamp = block.timestamp + (freezingPeriodMaximum / 2);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, ((amount * freezingPeriodMaximum) * 1) / 2);

        // Chest is frozen, 5/8 of freezing period passed check
        timestamp = block.timestamp + ((5 * freezingPeriodMaximum) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, ((amount * freezingPeriodMaximum) * 3) / 8);

        // Chest is frozen, 3/4 of freezing period passed check
        timestamp = block.timestamp + ((3 * freezingPeriodMaximum) / 4);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, ((amount * freezingPeriodMaximum) * 1) / 4);

        // Chest is frozen, 7/8 of freezing period passed check
        timestamp = block.timestamp + ((7 * freezingPeriodMaximum) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, (amount * freezingPeriodMaximum) / 8);

        // Chest is frozen, end of freezing period check
        timestamp = block.timestamp + freezingPeriodMaximum;

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, 0);
    }

    function test_calculatePowerSpecialChestWithMaximumFreezingPeriod()
        external
    {
        uint256 amount = 100;
        uint32 freezingPeriodMaximum = MAX_FREEZING_PERIOD_SPECIAL_CHEST;
        uint8 nerfParameter = 4; // 4/10 nerfing

        // Special chest position with maximum freezing period
        uint32 vestingDuration = 7 days;
        uint32 freezingPeriod = freezingPeriodMaximum;
        ChestHarness.VestingPosition
            memory vestingPositionRegularChestFreezingPeriodMaximum = chestHarness
                .exposed_createVestingPosition(
                    amount,
                    freezingPeriod,
                    vestingDuration,
                    INITIAL_BOOSTER,
                    nerfParameter
                );

        // Chest is open
        uint256 timestamp = block.timestamp +
            (freezingPeriod + vestingDuration);

        uint256 power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, 0);

        // Chest is frozen, start of freezing period check, vesting not started
        timestamp = block.timestamp;

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, (amount * freezingPeriodMaximum * nerfParameter) / 10);

        // Chest is frozen, 1/8 of freezing period passed check, , vesting not started
        timestamp = block.timestamp + (freezingPeriodMaximum / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            (((amount * freezingPeriodMaximum * nerfParameter) / 10) * 7) / 8
        );

        // Chest is frozen, 1/4 of freezing period passed check, , vesting not started
        timestamp = block.timestamp + (freezingPeriodMaximum / 4);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            (((amount * freezingPeriodMaximum * nerfParameter) / 10) * 3) / 4
        );

        // Chest is frozen, 3/8 of freezing period passed check, , vesting not started
        timestamp = block.timestamp + ((3 * freezingPeriodMaximum) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            (((amount * freezingPeriodMaximum * nerfParameter) / 10) * 5) / 8
        );

        // Chest is frozen, 1/2 of freezing period passed check, vesting not started
        timestamp = block.timestamp + (freezingPeriodMaximum / 2);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            (((amount * freezingPeriodMaximum * nerfParameter) / 10) * 1) / 2
        );

        // Chest is frozen, 5/8 of freezing period passed check, vesting not started
        timestamp = block.timestamp + ((5 * freezingPeriodMaximum) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            (((amount * freezingPeriodMaximum * nerfParameter) / 10) * 3) / 8
        );

        // Chest is frozen, 3/4 of freezing period passed check, vesting not started
        timestamp = block.timestamp + ((3 * freezingPeriodMaximum) / 4);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            (((amount * freezingPeriodMaximum * nerfParameter) / 10) * 1) / 4
        );

        // Chest is frozen, 7/8 of freezing period passed check, vesting not started
        timestamp = block.timestamp + ((7 * freezingPeriodMaximum) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            ((amount * freezingPeriodMaximum * nerfParameter) / 10) / 8
        );

        // Chest is frozen, end of freezing period check, vesting started
        uint256 cliffTimestamp = block.timestamp + freezingPeriodMaximum;

        power = chestHarness.exposed_calculatePower(
            cliffTimestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, ((vestingDuration * amount * nerfParameter) / 10) / 2);

        // Chest is frozen,  1/8 of vesting duration passed
        timestamp = cliffTimestamp + (vestingDuration / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            ((((vestingDuration * 7) / 8) * amount * nerfParameter) / 10) / 2
        );

        // Chest is frozen,  1/4 of vesting duration passed
        timestamp = cliffTimestamp + (vestingDuration / 4);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            ((((vestingDuration * 3) / 4) * amount * nerfParameter) / 10) / 2
        );

        // Chest is frozen, 3/8 of vesting duration passed
        timestamp = cliffTimestamp + ((3 * vestingDuration) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            ((((vestingDuration * 5) / 8) * amount * nerfParameter) / 10) / 2
        );

        // Chest is frozen,  1/2 of vesting duration passed
        timestamp = cliffTimestamp + (vestingDuration / 2);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            ((((vestingDuration * 1) / 2) * amount * nerfParameter) / 10) / 2
        );

        // Chest is frozen,  5/8 of vesting duration passed
        timestamp = cliffTimestamp + ((5 * vestingDuration) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            ((((vestingDuration * 3) / 8) * amount * nerfParameter) / 10) / 2
        );

        // Chest is frozen,  3/4 of vesting duration passed
        timestamp = cliffTimestamp + ((3 * vestingDuration) / 4);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            ((((vestingDuration * 1) / 4) * amount * nerfParameter) / 10) / 2
        );

        // Chest is frozen, 7/8 of vesting duration passed
        timestamp = cliffTimestamp + ((7 * vestingDuration) / 8);

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(
            power,
            ((((vestingDuration * 1) / 8) * amount * nerfParameter) / 10) / 2
        );

        // Chest is open, vesting ended
        timestamp = cliffTimestamp + vestingDuration;

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, 0);
    }
}
