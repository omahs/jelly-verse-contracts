// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Chest} from "../../../contracts/Chest.sol";
import {ERC20Token} from "../../../contracts/test/ERC20Token.sol";
import {Math} from "../../../contracts/vendor/openzeppelin/v4.9.0/utils/math/Math.sol";

// contract for internal function testing
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

    function exposed_calculatePower(
        uint256 timestamp,
        VestingPosition memory vestingPosition
    ) external pure returns (uint256) {
        return _calculatePower(timestamp, vestingPosition);
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

contract ChestTest is Test {
    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;
    uint32 constant MIN_FREEZING_PERIOD = 7 days;
    uint32 constant MIN_VESTING_DURATION = 1;
    uint32 constant MAX_VESTING_DURATION = 3 * 365 days;
    uint8 constant MAX_NERF_PARAMETER = 10;
    uint32 constant TIME_FACTOR = 7 days;

    uint120 private constant DECIMALS = 1e18;
    uint120 private constant INITIAL_BOOSTER = 1 * DECIMALS;
    uint120 private constant WEEKLY_BOOSTER_INCREMENT = 6_410_256_410_256_410; // @dev 1 / 156 weeks

    uint256 constant MIN_STAKING_AMOUNT = 1000 * DECIMALS;

    address immutable i_deployerAddress;

    address testAddress = makeAddr("testAddress");
    address specialChestCreator = makeAddr("specialChestCreator");
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
        uint32 vestedDuration,
        uint120 booster,
        uint8 nerfParameter
    );
    event IncreaseStake(
        uint256 indexed tokenId,
        uint256 totalStaked,
        uint256 freezedUntil,
        uint120 booster
    );
    event Unstake(
        uint256 indexed tokenId,
        uint256 amount,
        uint256 totalStaked,
        uint120 booster
    );
    event SetFee(uint128 fee);
    event SetBoosterThreshold(uint256 boosterThreshold);
    event SetMinimalStakingPower(uint256 minimalStakingPower);
    event FeeWithdrawn(address indexed beneficiary);

    error Chest__ZeroAddress();
    error Chest__InvalidStakingAmount();
    error Chest__NonExistentToken();
    error Chest__NothingToIncrease();
    error Chest__InvalidFreezingPeriod();
    error Chest__CannotModifySpecial();
    error Chest__NonTransferrableToken();
    error Chest__NotAuthorizedForToken();
    error Chest__FreezingPeriodNotOver();
    error Chest__InvalidVestingDuration();
    error Chest__InvalidNerfParameter();
    error Chest__CannotUnstakeMoreThanReleasable();
    error Chest__NothingToUnstake();
    error Chest__InvalidBoosterValue();
    error Chest__NoFeesToWithdraw();

    error Ownable__CallerIsNotOwner();

    modifier openPosition() {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());

        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
        _;
    }

    modifier openSpecialPosition() {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(specialChestCreator);
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
        i_deployerAddress = msg.sender;
    }

    function setUp() public {
        uint128 fee = 10;
        address owner = msg.sender;
        address pendingOwner = testAddress;

        jellyToken = new ERC20Token("Jelly", "JELLY");
        chest = new Chest(address(jellyToken), fee, owner, pendingOwner);
        chestHarness = new ChestHarness(
            address(jellyToken),
            fee,
            owner,
            pendingOwner
        );

        vm.prank(testAddress);
        jellyToken.mint(1_000 * MIN_STAKING_AMOUNT);

        vm.prank(specialChestCreator);
        jellyToken.mint(1_000 * MIN_STAKING_AMOUNT);

        vm.prank(approvedAddress);
        jellyToken.mint(1_000 * MIN_STAKING_AMOUNT);

        vm.prank(nonApprovedAddress);
        jellyToken.mint(1_000 * MIN_STAKING_AMOUNT);

        vm.warp(7 days); //min freezing period
    }

    // UNIT TESTS
    function test_Deployment() external {
        assertEq(chest.fee(), 10);
        assertEq(chest.totalFees(), 0);
        assertEq(chest.owner(), msg.sender);
        assertEq(chest.getPendingOwner(), testAddress);
        assertEq(chest.totalSupply(), 0);

        assertEq(chestHarness.fee(), 10);
        assertEq(chestHarness.totalFees(), 0);
        assertEq(chestHarness.owner(), msg.sender);
        assertEq(chestHarness.getPendingOwner(), testAddress);
        assertEq(chestHarness.totalSupply(), 0);
    }

    // Regular chest stake tests
    function test_stake() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;

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
        assertEq(vestingPosition.boosterTimestamp, block.timestamp);
        assertEq(vestingPosition.vestingDuration, 0);
        assertEq(vestingPosition.accumulatedBooster, INITIAL_BOOSTER);
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
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());

        vm.expectEmit(true, true, false, true, address(chest));
        emit Staked(
            testAddress,
            0,
            amount,
            block.timestamp + freezingPeriod,
            0,
            INITIAL_BOOSTER,
            0
        );

        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
    }

    function test_stakeInvalidStakingAmountZero() external {
        uint256 amount = 0; // @dev assigning to zero for clarity & better code readability
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidStakingAmount.selector);
        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
    }

    function test_stakeInvalidStakingAmountBelowMinimum() external {
        uint256 amount = MIN_STAKING_AMOUNT - 1;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;

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

    function test_stakeZeroInvalidMinimumFreezingTime() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD - 1;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());

        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
    }

    function test_stakeInvalidMaximumFreezingPeriod() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MAX_FREEZING_PERIOD_REGULAR_CHEST + 1;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.stake(amount, testAddress, freezingPeriod);

        vm.stopPrank();
    }

    // Special chest stake tests
    function test_stakeSpecial() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5; // 5/10 = 1/2

        uint256 totalFeesBefore = chest.totalFees();
        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            specialChestCreator
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

        vm.startPrank(specialChestCreator);
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
        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(
            specialChestCreator
        );
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

        assertEq(vestingPosition.totalVestedAmount, amount);
        assertEq(vestingPosition.releasedAmount, 0);
        assertEq(
            vestingPosition.cliffTimestamp,
            block.timestamp + freezingPeriod
        );
        assertEq(vestingPosition.boosterTimestamp, block.timestamp);
        assertEq(vestingPosition.vestingDuration, 1000);
        assertEq(vestingPosition.accumulatedBooster, 0);
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

    function test_stakeSpecialEmitsStakedEvent() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(specialChestCreator);
        jellyToken.approve(address(chest), amount + chest.fee());

        vm.expectEmit(true, true, false, true, address(chest));
        emit Staked(
            testAddress,
            0,
            amount,
            block.timestamp + freezingPeriod,
            vestingDuration,
            0,
            nerfParameter
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

    function test_stakeSpecialInvalidStakingAmountZero() external {
        uint256 amount = 0;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(specialChestCreator);
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

    function test_stakeSpecialInvalidStakingAmountBelowMinimum() external {
        uint256 amount = MIN_STAKING_AMOUNT - 1;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(specialChestCreator);
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
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(specialChestCreator);
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

    function test_stakeSpecialInvalidMinimumFreezingPeriod() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD - 1;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(specialChestCreator);
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

    function test_stakeSpecialInvalidMaximumFreezingPeriod() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MAX_FREEZING_PERIOD_SPECIAL_CHEST + 1;
        uint32 vestingDuration = 1000;
        uint8 nerfParameter = 5;

        vm.startPrank(specialChestCreator);
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

    function test_stakeSpecialInvalidMinimumVestingDuration() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MAX_FREEZING_PERIOD_SPECIAL_CHEST;
        uint32 vestingDuration = MIN_VESTING_DURATION - 1;
        uint8 nerfParameter = 5;

        vm.startPrank(specialChestCreator);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidVestingDuration.selector);
        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );

        vm.stopPrank();
    }

    function test_stakeSpecialInvalidMaximumVestingDuration() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MAX_FREEZING_PERIOD_SPECIAL_CHEST;
        uint32 vestingDuration = MAX_VESTING_DURATION + 1;
        uint8 nerfParameter = 5;

        vm.startPrank(specialChestCreator);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidVestingDuration.selector);
        chest.stakeSpecial(
            amount,
            testAddress,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );

        vm.stopPrank();
    }

    function test_stakeSpecialInvalidNerfParameter() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MAX_FREEZING_PERIOD_SPECIAL_CHEST;
        uint32 vestingDuration = MAX_VESTING_DURATION;
        uint8 nerfParameter = MAX_NERF_PARAMETER + 1;

        vm.startPrank(specialChestCreator);
        jellyToken.approve(address(chest), amount);

        vm.expectRevert(Chest__InvalidNerfParameter.selector);
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
    function test_increaseStakeIncreaseStakingAmountFrozenChest()
        external
        openPosition
    {
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
            vestingPositionAfter.boosterTimestamp,
            vestingPositionBefore.boosterTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );

        assertEq(
            vestingPositionAfter.accumulatedBooster,
            vestingPositionBefore.accumulatedBooster
        );
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

    function test_increaseStakeIncreaseStakingAmountApprovedAddressFrozenChest()
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
            vestingPositionAfter.boosterTimestamp,
            vestingPositionBefore.boosterTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(
            vestingPositionAfter.accumulatedBooster,
            vestingPositionBefore.accumulatedBooster
        );
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

    function test_increaseStakeIncreaseStakingAmountOpenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0; // @dev assigning to zero for clarity & better code readability
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

        uint256 increaseAmountFor = 50;
        uint32 increaseFreezingPeriodFor = MIN_FREEZING_PERIOD;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

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
            (block.timestamp + increaseFreezingPeriodFor)
        );
        assertEq(vestingPositionAfter.boosterTimestamp, block.timestamp);
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertGt(
            vestingPositionAfter.accumulatedBooster,
            vestingPositionBefore.accumulatedBooster
        );
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

    function test_increaseStakeIncreaseStakingAmountApprovedAddressOpenChest()
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
        uint32 increaseFreezingPeriodFor = MIN_FREEZING_PERIOD;

        vm.prank(testAddress);
        chest.approve(approvedAddress, positionIndex);

        vm.startPrank(approvedAddress);

        jellyToken.approve(address(chest), increaseAmountFor);

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

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
            (block.timestamp + increaseFreezingPeriodFor)
        );
        assertEq(vestingPositionAfter.boosterTimestamp, block.timestamp);
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertGt(
            vestingPositionAfter.accumulatedBooster,
            vestingPositionBefore.accumulatedBooster
        );
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
        uint256 accumulatedaccumulatedBoosterBefore = vestingPositionBefore
            .accumulatedBooster;

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
        uint256 accumulatedBoosterAfter = vestingPositionAfter
            .accumulatedBooster;

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
            vestingPositionAfter.boosterTimestamp,
            vestingPositionBefore.boosterTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(accountJellyBalanceAfter, accountJellyBalanceBefore);
        assertEq(chestJellyBalanceAfter, chestJellyBalanceBefore);
        assertEq(accumulatedBoosterAfter, accumulatedaccumulatedBoosterBefore);
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
        uint256 accumulatedaccumulatedBoosterBefore = vestingPositionBefore
            .accumulatedBooster;

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = MIN_FREEZING_PERIOD;

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
        uint256 accumulatedBoosterAfter = vestingPositionAfter
            .accumulatedBooster;

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            block.timestamp + increaseFreezingPeriodFor
        );
        assertEq(vestingPositionAfter.boosterTimestamp, block.timestamp);
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(accountJellyBalanceAfter, accountJellyBalanceBefore);
        assertEq(chestJellyBalanceAfter, chestJellyBalanceBefore);
        assertGt(accumulatedBoosterAfter, accumulatedaccumulatedBoosterBefore);
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
        uint256 accumulatedBoosterBefore = vestingPositionBefore
            .accumulatedBooster;

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
        uint256 boosterAfter = vestingPositionAfter.accumulatedBooster;

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
            vestingPositionAfter.boosterTimestamp,
            vestingPositionBefore.boosterTimestamp
        );
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(accountJellyBalanceAfter, accountJellyBalanceBefore);
        assertEq(chestJellyBalanceAfter, chestJellyBalanceBefore);
        assertEq(boosterAfter, accumulatedBoosterBefore);
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
        uint256 accumulatedBoosterBefore = vestingPositionBefore
            .accumulatedBooster;

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = MIN_FREEZING_PERIOD;

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
        uint256 boosterAfter = vestingPositionAfter.accumulatedBooster;

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            (block.timestamp + increaseFreezingPeriodFor)
        );
        assertEq(vestingPositionAfter.boosterTimestamp, block.timestamp);
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(accountJellyBalanceAfter, accountJellyBalanceBefore);
        assertEq(chestJellyBalanceAfter, chestJellyBalanceBefore);
        assertGt(boosterAfter, accumulatedBoosterBefore);
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
        uint256 accumulatedBoosterBefore = vestingPositionBefore
            .accumulatedBooster;

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

        uint256 boosterAfter = vestingPositionAfter.accumulatedBooster;

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            totalVestedAmountBefore + increaseAmountFor
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp + increaseFreezingPeriodFor
        );
        assertEq(
            vestingPositionAfter.boosterTimestamp,
            vestingPositionBefore.boosterTimestamp
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
        assertEq(boosterAfter, accumulatedBoosterBefore);
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
        uint32 increaseFreezingPeriodFor = MIN_FREEZING_PERIOD;

        uint256 totalVestedAmountBefore = vestingPositionBefore
            .totalVestedAmount;

        uint256 accumulatedBoosterBefore = vestingPositionBefore
            .accumulatedBooster;

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

        uint256 boosterAfter = vestingPositionAfter.accumulatedBooster;

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            totalVestedAmountBefore + increaseAmountFor
        );
        assertEq(vestingPositionAfter.releasedAmount, 0);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            block.timestamp + increaseFreezingPeriodFor
        );
        assertEq(vestingPositionAfter.boosterTimestamp, block.timestamp);
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
        assertGt(boosterAfter, accumulatedBoosterBefore);
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

        uint120 accumulatedBoosterBefore = vestingPositionBefore
            .accumulatedBooster;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        vm.expectEmit(true, false, false, true, address(chest));
        emit IncreaseStake(
            positionIndex,
            totalVestedAmountBefore + increaseAmountFor,
            vestingPositionBefore.cliffTimestamp + increaseFreezingPeriodFor,
            accumulatedBoosterBefore
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
            uint32 increaseFreezingPeriodFor = MIN_FREEZING_PERIOD;

            uint256 totalVestedAmountBefore = vestingPositionBefore
                .totalVestedAmount;

            uint256 cliffTimestampBefore = vestingPositionBefore.cliffTimestamp;

            vm.warp(cliffTimestampBefore + 1);

            uint120 newBooster = chestHarness.exposed_calculateBooster(
                vestingPositionBefore,
                uint48(block.timestamp)
            );

            vm.startPrank(testAddress);
            jellyToken.approve(address(chest), increaseAmountFor);

            vm.expectEmit(true, false, false, true, address(chest));
            emit IncreaseStake(
                positionIndex,
                totalVestedAmountBefore + increaseAmountFor,
                block.timestamp + increaseFreezingPeriodFor,
                newBooster
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

    function test_increaseStakeInvalidFreezingPeriodMax()
        external
        openPosition
    {
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

    function test_increaseStakeInvalidFreezingPeriodFrozenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 increaseAmountFor = 0;
        uint32 increaseFreezingPeriodFor = uint32(
            MAX_FREEZING_PERIOD_REGULAR_CHEST -
                (vestingPositionBefore.cliffTimestamp - block.timestamp) +
                1
        );

        vm.startPrank(testAddress);
        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        vm.stopPrank();
    }

    function test_increaseStakeInvalidStakingAmountOpenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0; // @dev assigning to zero for clarity & better code readability
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 increaseAmountFor = 1;
        uint32 increaseFreezingPeriodFor = MIN_FREEZING_PERIOD;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

        uint256 unstakeAmount = 2; // it will be one wei below MIN_STAKING_AMOUNT
        chest.unstake(positionIndex, unstakeAmount);

        vm.expectRevert(Chest__InvalidStakingAmount.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );

        vm.stopPrank();
    }

    function test_increaseStakeInvalidFreezingPeriodOpenChest()
        external
        openPosition
    {
        uint256 positionIndex = 0;

        uint256 increaseAmountFor = 100;
        uint32 increaseFreezingPeriodFor = MIN_FREEZING_PERIOD - 1;

        vm.warp(chest.getVestingPosition(positionIndex).cliffTimestamp + 1); // open chest

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
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, unstakeAmount);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(vestingPositionAfter.boosterTimestamp, 0);
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );
        assertEq(vestingPositionAfter.accumulatedBooster, INITIAL_BOOSTER);
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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

        uint256 unstakeAmount = 50;

        vm.prank(testAddress);
        chest.approve(approvedAddress, positionIndex);

        vm.warp(vestingPositionBefore.cliffTimestamp + 1);

        vm.prank(approvedAddress);
        chest.unstake(positionIndex, unstakeAmount);

        Chest.VestingPosition memory vestingPositionAfter = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, unstakeAmount);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(vestingPositionAfter.boosterTimestamp, 0);
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );

        assertEq(vestingPositionAfter.accumulatedBooster, INITIAL_BOOSTER);
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

        uint256 unstakeAmount = 50;

        vm.warp(vestingPosition.cliffTimestamp + 1);

        vm.expectEmit(true, false, false, true, address(chest));
        emit Unstake(
            positionIndex,
            unstakeAmount,
            (vestingPosition.totalVestedAmount -
                vestingPosition.releasedAmount) - unstakeAmount,
            INITIAL_BOOSTER
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
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, unstakeAmount);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(vestingPositionAfter.boosterTimestamp, 0);
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );

        assertEq(vestingPositionAfter.accumulatedBooster, INITIAL_BOOSTER);
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

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
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

        uint256 accountJellyBalanceAfter = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceAfter = jellyToken.balanceOf(address(chest));

        assertEq(
            vestingPositionAfter.totalVestedAmount,
            vestingPositionBefore.totalVestedAmount
        );
        assertEq(vestingPositionAfter.releasedAmount, unstakeAmount);
        assertEq(
            vestingPositionAfter.cliffTimestamp,
            vestingPositionBefore.cliffTimestamp
        );
        assertEq(vestingPositionAfter.boosterTimestamp, 0);
        assertEq(
            vestingPositionAfter.vestingDuration,
            vestingPositionBefore.vestingDuration
        );

        assertEq(vestingPositionAfter.accumulatedBooster, INITIAL_BOOSTER);
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
            totalVestedAmountBefore - unstakeAmount,
            INITIAL_BOOSTER
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
        uint128 newFee = 100;

        vm.prank(i_deployerAddress);
        chest.setFee(newFee);

        assertEq(chest.fee(), newFee);
    }

    function test_setFeeEmitsSetFeeEvent() external {
        uint128 newFee = 100;

        vm.prank(i_deployerAddress);

        vm.expectEmit(false, false, false, true, address(chest));
        emit SetFee(newFee);

        chest.setFee(newFee);
    }

    function test_setFeeCallerIsNotOwner() external {
        uint128 newFee = 100;

        vm.prank(testAddress);
        vm.expectRevert(Ownable__CallerIsNotOwner.selector);

        chest.setFee(newFee);
    }

    function test_withdrawFees() external openPosition {
        uint256 deployerJellyBalanceBefore = jellyToken.balanceOf(
            i_deployerAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 totalFeesBefore = chest.totalFees();

        vm.prank(i_deployerAddress);
        chest.withdrawFees(i_deployerAddress);

        uint256 deployerJellyBalanceAfter = jellyToken.balanceOf(
            i_deployerAddress
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
        vm.prank(i_deployerAddress);

        vm.expectEmit(true, false, false, true, address(chest));
        emit FeeWithdrawn(i_deployerAddress);

        chest.withdrawFees(i_deployerAddress);
    }

    function test_withdrawFeesCallerIsNotOwner() external openPosition {
        vm.prank(testAddress);
        vm.expectRevert(Ownable__CallerIsNotOwner.selector);

        chest.withdrawFees(i_deployerAddress);
    }

    function test_withdrawFeesNoFeesToWithdraw() external openPosition {
        vm.startPrank(i_deployerAddress);
        chest.withdrawFees(i_deployerAddress);

        vm.expectRevert(Chest__NoFeesToWithdraw.selector);
        chest.withdrawFees(i_deployerAddress);

        vm.stopPrank();
    }

    function test_transferFromChest() external openPosition {
        vm.prank(testAddress);

        vm.expectRevert(Chest__NonTransferrableToken.selector);
        chest.transferFrom(testAddress, transferRecipientAddress, 0);
    }

    function test_calculateBooster() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriodMinimum = MIN_FREEZING_PERIOD;
        uint32 freezingPeriodMaximum = MAX_FREEZING_PERIOD_REGULAR_CHEST;
        uint8 nerfParameter = MAX_NERF_PARAMETER;
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

        uint256 boosterTimestamp = vestingPositionMinimumFreezingPeriod
            .boosterTimestamp;

        for (uint256 i = 0; i < 8; i++) {
            uint256 timestamp = boosterTimestamp + (i * 1 days);

            vm.warp(timestamp);
            uint120 booster = chestHarness.exposed_calculateBooster(
                vestingPositionMinimumFreezingPeriod,
                uint48(timestamp)
            );

            assertEq(
                booster,
                INITIAL_BOOSTER +
                    ((i * 1 days) / TIME_FACTOR) *
                    WEEKLY_BOOSTER_INCREMENT
            );
        }

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

        boosterTimestamp = vestingPositionMaximumFreezingPeriod
            .boosterTimestamp;

        for (uint256 i = 0; i < 1093; i++) {
            uint256 timestamp = boosterTimestamp + (i * 1 days);

            vm.warp(timestamp);
            uint120 booster = chestHarness.exposed_calculateBooster(
                vestingPositionMaximumFreezingPeriod,
                uint48(timestamp)
            );
            assertEq(
                booster,
                INITIAL_BOOSTER +
                    ((i * 1 days) / TIME_FACTOR) *
                    WEEKLY_BOOSTER_INCREMENT
            );
        }
    }

    function test_calculateBoosterSpecialChest() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriodMinimum = MIN_FREEZING_PERIOD;
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

        uint120 booster = chestHarness.exposed_calculateBooster(
            vestingPositionVestingDurationZero,
            uint48(block.timestamp)
        );
        assertEq(booster, INITIAL_BOOSTER);
    }

    function test_calculatePowerChestWithMinimumFreezingPeriod() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriodMinimum = MIN_FREEZING_PERIOD;
        uint8 nerfParameter = MAX_NERF_PARAMETER;

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

        uint120 booster = chestHarness.exposed_calculateBooster(
            vestingPositionRegularChestFreezingPeriodMinimum,
            uint48(timestamp)
        );

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        uint256 regularFreezingTime = 1; // @dev expected value for minimum freezing period is 1

        assertEq(
            power,
            (booster * amount * regularFreezingTime) /
                (MIN_STAKING_AMOUNT * DECIMALS)
        );

        // Chest is frozen, day by day check in minimum freezing period range
        for (uint256 i = 1; i < 7; i++) {
            timestamp = block.timestamp + i * 1 days;

            booster = chestHarness.exposed_calculateBooster(
                vestingPositionRegularChestFreezingPeriodMinimum,
                uint48(timestamp)
            );

            power = chestHarness.exposed_calculatePower(
                timestamp,
                vestingPositionRegularChestFreezingPeriodMinimum
            );

            regularFreezingTime = 1;

            assertEq(
                power,
                (booster * amount * regularFreezingTime) /
                    (MIN_STAKING_AMOUNT * DECIMALS)
            );
        }

        // Chest is frozen, end of freezing period check
        timestamp = block.timestamp + freezingPeriodMinimum;

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMinimum
        );

        assertEq(power, 0);
    }

    function test_calculatePowerChestWithMaximumFreezingPeriod() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriodMaximum = MAX_FREEZING_PERIOD_REGULAR_CHEST;
        uint8 nerfParameter = MAX_NERF_PARAMETER;

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

        uint120 booster = chestHarness.exposed_calculateBooster(
            vestingPositionRegularChestFreezingPeriodMaximum,
            uint48(timestamp)
        );

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        uint256 regularFreezingTime = 157; // @dev expected value for maximum freezing period is 157

        assertEq(
            power,
            (booster * amount * regularFreezingTime) /
                (MIN_STAKING_AMOUNT * DECIMALS)
        );
        // Chest is frozen, week by week check in maximum freezing period range
        for (uint256 i = 1; i < 157; i++) {
            timestamp = block.timestamp + (i * 1 weeks);

            booster = chestHarness.exposed_calculateBooster(
                vestingPositionRegularChestFreezingPeriodMaximum,
                uint48(timestamp)
            );

            power = chestHarness.exposed_calculatePower(
                timestamp,
                vestingPositionRegularChestFreezingPeriodMaximum
            );

            regularFreezingTime = 157 - i;

            assertEq(
                power,
                (booster * amount * regularFreezingTime) /
                    (MIN_STAKING_AMOUNT * DECIMALS)
            );
        }
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
        uint256 amount = MIN_STAKING_AMOUNT;
        uint8 nerfParameter = 4; // 4/10 nerfing

        // Special chest position with maximum freezing period
        uint32 vestingDuration = 2 weeks;

        ChestHarness.VestingPosition
            memory vestingPositionRegularChestFreezingPeriodMaximum = chestHarness
                .exposed_createVestingPosition(
                    amount,
                    MAX_FREEZING_PERIOD_SPECIAL_CHEST, // @dev using constant to avoid stack too deep error
                    vestingDuration,
                    INITIAL_BOOSTER,
                    nerfParameter
                );

        // Chest is open
        uint256 timestamp = block.timestamp +
            (MAX_FREEZING_PERIOD_SPECIAL_CHEST + vestingDuration);

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

        uint256 regularFreezingTime = 261; // @dev expected value for maximum freezing period is 261
        uint256 linearFreezingTime = 1; // @dev expected value for 2 weeks vesting duration is 1 and constant until vesting starts

        assertEq(
            power,
            (amount *
                (regularFreezingTime + linearFreezingTime) *
                nerfParameter) / (10 * MIN_STAKING_AMOUNT)
        );

        // Chest is frozen, week by week check in maximum freezing period range
        for (uint256 i = 1; i < 261; i++) {
            timestamp = block.timestamp + (i * 1 weeks);

            power = chestHarness.exposed_calculatePower(
                timestamp,
                vestingPositionRegularChestFreezingPeriodMaximum
            );

            regularFreezingTime = 261 - i;

            assertEq(
                power,
                (amount *
                    (regularFreezingTime + linearFreezingTime) *
                    nerfParameter) / (10 * MIN_STAKING_AMOUNT)
            );
        }

        // Chest is frozen, end of freezing period check, vesting started
        uint256 cliffTimestamp = block.timestamp +
            MAX_FREEZING_PERIOD_SPECIAL_CHEST;

        power = chestHarness.exposed_calculatePower(
            cliffTimestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        regularFreezingTime = 0;
        linearFreezingTime = 1; // @dev expected value at begining for 2 weeks vesting duration is 1

        assertEq(
            power,
            (amount *
                (regularFreezingTime + linearFreezingTime) *
                nerfParameter) / (10 * MIN_STAKING_AMOUNT)
        );

        // Chest is frozen, day by day check in vesting duration range
        // First week
        for (uint256 i = 1; i < 7; i++) {
            timestamp = cliffTimestamp + (i * 1 days);

            power = chestHarness.exposed_calculatePower(
                timestamp,
                vestingPositionRegularChestFreezingPeriodMaximum
            );

            linearFreezingTime = 1; // @dev expected value during week 1

            assertEq(
                power,
                (amount *
                    (regularFreezingTime + linearFreezingTime) *
                    nerfParameter) / (10 * MIN_STAKING_AMOUNT)
            );
        }
        // Second week
        for (uint256 i = 7; i < 14; i++) {
            timestamp = cliffTimestamp + (i * 1 days);

            power = chestHarness.exposed_calculatePower(
                timestamp,
                vestingPositionRegularChestFreezingPeriodMaximum
            );

            linearFreezingTime = 0; // @dev expected value during week 2

            assertEq(
                power,
                (amount *
                    (regularFreezingTime + linearFreezingTime) *
                    nerfParameter) / (10 * MIN_STAKING_AMOUNT)
            );
        }
        // Chest is open, vesting ended
        timestamp = cliffTimestamp + vestingDuration;

        power = chestHarness.exposed_calculatePower(
            timestamp,
            vestingPositionRegularChestFreezingPeriodMaximum
        );

        assertEq(power, 0);
    }

    // Getter tests
    function test_getVotingPower() external {
        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;

        vm.startPrank(testAddress);

        uint256 power;
        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i; i < 5; i++) {
            jellyToken.approve(address(chest), amount + chest.fee());
            chest.stake(amount, testAddress, freezingPeriod);

            power += chestHarness.exposed_calculatePower(
                block.timestamp,
                chest.getVestingPosition(i)
            );
            tokenIds[i] = i;
        }

        uint256 powerGetter = chest.getVotingPower(testAddress, tokenIds);

        assertEq(power, powerGetter);
    }

    function test_getVotingPowerNotAuthorizedForToken() external openPosition {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        vm.expectRevert(Chest__NotAuthorizedForToken.selector);
        chest.getVotingPower(approvedAddress, tokenIds);
    }

    function test_getChestPowerAtSpecificMoment() external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );
        uint256 powerHarness = chestHarness.exposed_calculatePower(
            block.timestamp,
            vestingPosition
        );
        uint256 powerGetter = chest.estimateChestPower(
            block.timestamp,
            vestingPosition
        );

        assertEq(powerHarness, powerGetter);

        vm.warp(
            vestingPosition.cliffTimestamp + MAX_FREEZING_PERIOD_REGULAR_CHEST
        );

        powerHarness = chestHarness.exposed_calculatePower(
            block.timestamp,
            vestingPosition
        );
        powerGetter = chest.estimateChestPower(
            block.timestamp,
            vestingPosition
        );

        assertEq(powerHarness, powerGetter);
    }

    function test_getChestPowerUsingChestId() external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );
        uint256 powerHarness = chestHarness.exposed_calculatePower(
            block.timestamp,
            vestingPosition
        );
        uint256 powerGetter = chest.getChestPower(positionIndex);

        assertEq(powerHarness, powerGetter);

        vm.warp(
            vestingPosition.cliffTimestamp + MAX_FREEZING_PERIOD_REGULAR_CHEST
        );

        powerHarness = chestHarness.exposed_calculatePower(
            block.timestamp,
            vestingPosition
        );
        powerGetter = chest.getChestPower(positionIndex);

        assertEq(powerHarness, powerGetter);
    }

    function test_getVestingPosition()
        external
        openPosition
        openSpecialPosition
    {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        assertEq(vestingPosition.totalVestedAmount, MIN_STAKING_AMOUNT);
        assertEq(vestingPosition.releasedAmount, 0);
        assertEq(
            vestingPosition.cliffTimestamp,
            block.timestamp + MIN_FREEZING_PERIOD
        );
        assertEq(vestingPosition.boosterTimestamp, block.timestamp);
        assertEq(vestingPosition.vestingDuration, 0);

        assertEq(vestingPosition.accumulatedBooster, INITIAL_BOOSTER);
        assertEq(vestingPosition.nerfParameter, 0);

        positionIndex = 1;
        vestingPosition = chest.getVestingPosition(positionIndex);

        assertEq(vestingPosition.totalVestedAmount, MIN_STAKING_AMOUNT);
        assertEq(vestingPosition.releasedAmount, 0);
        assertEq(
            vestingPosition.cliffTimestamp,
            block.timestamp + MIN_FREEZING_PERIOD
        );
        assertEq(vestingPosition.boosterTimestamp, block.timestamp);
        assertEq(vestingPosition.vestingDuration, 1000);
        assertEq(vestingPosition.accumulatedBooster, 0);
        assertEq(vestingPosition.nerfParameter, 5);
    }

    function test_getVestingPositionNonExistentToken() external {
        uint256 positionIndex = 0;

        vm.expectRevert(Chest__NonExistentToken.selector);

        chest.getVestingPosition(positionIndex);
    }

    function test_totalSupply() external openPosition {
        uint256 totalSupply = chest.totalSupply();

        assertEq(totalSupply, 1);

        uint256 amount = MIN_STAKING_AMOUNT;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD;

        vm.startPrank(testAddress);

        for (uint256 i; i < 10; i++) {
            jellyToken.approve(address(chest), amount + chest.fee());
            chest.stake(amount, testAddress, freezingPeriod);

            ++totalSupply;

            assertEq(chest.totalSupply(), totalSupply);
        }

        vm.stopPrank();
    }
}
