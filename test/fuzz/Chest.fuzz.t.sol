// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Chest} from "../../contracts/Chest.sol";
import {ERC20Token} from "../../contracts/test/ERC20Token.sol";

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

contract ChestFuzzTest is Test {
    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;
    uint32 constant MIN_FREEZING_PERIOD_REGULAR_CHEST = 7 days;

    uint64 private constant DECIMALS = 1e18;
    uint64 private constant INITIAL_BOOSTER = 1 * DECIMALS;

    uint256 constant JELLY_MAX_SUPPLY = 1_000_000_000 ether;

    address immutable i_deployerAddress;

    address allocator = makeAddr("allocator");
    address distributor = makeAddr("distributor");
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
    error Chest__NoFeesToWithdraw();
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
        i_deployerAddress = msg.sender;
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
        jellyToken.mint(JELLY_MAX_SUPPLY + fee);

        vm.prank(distributor);
        jellyToken.mint(JELLY_MAX_SUPPLY + fee);

        vm.prank(testAddress);
        jellyToken.mint(JELLY_MAX_SUPPLY + fee);

        vm.prank(approvedAddress);
        jellyToken.mint(JELLY_MAX_SUPPLY + fee);

        vm.prank(nonApprovedAddress);
        jellyToken.mint(JELLY_MAX_SUPPLY + fee);
    }

    // Deployment test
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

    // Regular chest stake fuzz tests
    function testFuzz_stake(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod
    ) external {
        amount = bound(amount, 1, JELLY_MAX_SUPPLY);
        vm.assume(
            beneficiary != address(0) &&
                beneficiary != address(this) &&
                beneficiary != address(jellyToken) &&
                beneficiary != address(chestHarness)
        );
        assumePayable(beneficiary);
        freezingPeriod = uint32(
            bound(
                freezingPeriod,
                MIN_FREEZING_PERIOD_REGULAR_CHEST,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        uint256 totalFeesBefore = chest.totalFees();
        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 beneficiaryChestBalanceBefore = chest.balanceOf(beneficiary);
        uint256 chestTotalSupplyBefore = chest.totalSupply();

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());
        chest.stake(amount, beneficiary, freezingPeriod);
        vm.stopPrank();

        uint256 positionIndex = chest.totalSupply() - 1;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
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
        assertEq(vestingPosition.nerfParameter, 10);

        // using direct calls for balances to avoid stack too deep error
        assertEq(chest.totalFees(), totalFeesBefore + chest.fee());

        assertEq(
            jellyToken.balanceOf(testAddress),
            accountJellyBalanceBefore - amount - chest.fee()
        );
        assertEq(
            jellyToken.balanceOf(address(chest)),
            chestJellyBalanceBefore + amount + chest.fee()
        );

        assertEq(
            chest.balanceOf(beneficiary),
            beneficiaryChestBalanceBefore + 1
        );
        assertEq(chest.totalSupply(), chestTotalSupplyBefore + 1);
        assertEq(chest.releasableAmount(positionIndex), 0);
    }

    function testFuzz_stakeInvalidStakingAmount(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod
    ) external {
        amount = 0;
        vm.assume(
            beneficiary != address(0) &&
                beneficiary != address(this) &&
                beneficiary != address(jellyToken) &&
                beneficiary != address(chestHarness)
        );
        assumePayable(beneficiary);
        freezingPeriod = uint32(
            bound(
                freezingPeriod,
                MIN_FREEZING_PERIOD_REGULAR_CHEST,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());
        vm.expectRevert(Chest__InvalidStakingAmount.selector);
        chest.stake(amount, beneficiary, freezingPeriod);
        vm.stopPrank();
    }

    function testFuzz_stakeZeroAddress(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod
    ) external {
        beneficiary = address(0);
        amount = bound(amount, 1, JELLY_MAX_SUPPLY);
        freezingPeriod = uint32(
            bound(
                freezingPeriod,
                MIN_FREEZING_PERIOD_REGULAR_CHEST,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());
        vm.expectRevert(Chest__ZeroAddress.selector);
        chest.stake(amount, beneficiary, freezingPeriod);
        vm.stopPrank();
    }

    function testFuzz_stakeInvalidMinimumFreezingPeriod(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod
    ) external {
        vm.assume(freezingPeriod < MIN_FREEZING_PERIOD_REGULAR_CHEST);
        amount = bound(amount, 1, JELLY_MAX_SUPPLY);
        vm.assume(
            beneficiary != address(0) &&
                beneficiary != address(this) &&
                beneficiary != address(jellyToken) &&
                beneficiary != address(chestHarness)
        );
        assumePayable(beneficiary);

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());
        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.stake(amount, beneficiary, freezingPeriod);
        vm.stopPrank();
    }

    function testFuzz_stakeInvalidMaximumFreezingPeriod(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod
    ) external {
        vm.assume(freezingPeriod > MAX_FREEZING_PERIOD_REGULAR_CHEST);
        amount = bound(amount, 1, JELLY_MAX_SUPPLY);
        vm.assume(
            beneficiary != address(0) &&
                beneficiary != address(this) &&
                beneficiary != address(jellyToken) &&
                beneficiary != address(chestHarness)
        );
        assumePayable(beneficiary);

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());

        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.stake(amount, beneficiary, freezingPeriod);

        vm.stopPrank();
    }

    // Special chest stake fuzz tests
    function testFuzz_stakeSpecial(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod,
        uint32 vestingDuration,
        uint8 nerfParameter
    ) external {
        amount = bound(amount, 1, JELLY_MAX_SUPPLY);
        vm.assume(
            beneficiary != address(0) &&
                beneficiary != address(this) &&
                beneficiary != address(jellyToken) &&
                beneficiary != address(chestHarness)
        );
        assumePayable(beneficiary);
        freezingPeriod = uint32(
            bound(freezingPeriod, 0, MAX_FREEZING_PERIOD_SPECIAL_CHEST)
        );
        vestingDuration = uint32(
            bound(vestingDuration, 1, MAX_FREEZING_PERIOD_SPECIAL_CHEST / 3)
        ); // 1,5 years
        nerfParameter = uint8(bound(nerfParameter, 1, 10));

        uint256 totalFeesBefore = chest.totalFees();
        uint256 allocatorJellyBalanceBefore = jellyToken.balanceOf(allocator);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 beneficiaryChestBalanceBefore = chest.balanceOf(beneficiary);
        uint256 chestTotalSupplyBefore = chest.totalSupply();

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount + chest.fee());
        chest.stakeSpecial(
            amount,
            beneficiary,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );
        vm.stopPrank();

        uint256 positionIndex = chest.totalSupply() - 1;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        assertEq(vestingPosition.totalVestedAmount, amount);
        assertEq(vestingPosition.releasedAmount, 0);
        assertEq(
            vestingPosition.cliffTimestamp,
            block.timestamp + freezingPeriod
        );
        assertEq(vestingPosition.vestingDuration, vestingDuration);
        assertEq(vestingPosition.freezingPeriod, freezingPeriod);
        assertEq(vestingPosition.booster, INITIAL_BOOSTER);
        assertEq(vestingPosition.nerfParameter, nerfParameter);

        // using direct calls for balances to avoid stack too deep error
        assertEq(chest.totalFees(), totalFeesBefore + chest.fee());

        assertEq(
            jellyToken.balanceOf(allocator),
            allocatorJellyBalanceBefore - amount - chest.fee()
        );
        assertEq(
            jellyToken.balanceOf(address(chest)),
            chestJellyBalanceBefore + amount + chest.fee()
        );

        assertEq(
            chest.balanceOf(beneficiary),
            beneficiaryChestBalanceBefore + 1
        );

        assertEq(chest.totalSupply(), chestTotalSupplyBefore + 1);

        assertEq(chest.releasableAmount(positionIndex), 0);
    }

    function testFuzz_stakeSpecialInvalidStakingAmount(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod,
        uint32 vestingDuration,
        uint8 nerfParameter
    ) external {
        amount = 0;
        vm.assume(
            beneficiary != address(0) &&
                beneficiary != address(this) &&
                beneficiary != address(jellyToken) &&
                beneficiary != address(chestHarness)
        );
        assumePayable(beneficiary);
        freezingPeriod = uint32(
            bound(freezingPeriod, 0, MAX_FREEZING_PERIOD_SPECIAL_CHEST)
        );
        vestingDuration = uint32(
            bound(vestingDuration, 1, MAX_FREEZING_PERIOD_SPECIAL_CHEST / 3)
        );
        nerfParameter = uint8(bound(nerfParameter, 1, 10));

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount + chest.fee());
        vm.expectRevert(Chest__InvalidStakingAmount.selector);
        chest.stakeSpecial(
            amount,
            beneficiary,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );
        vm.stopPrank();
    }

    function testFuzz_stakeSpecialZeroAddress(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod,
        uint32 vestingDuration,
        uint8 nerfParameter
    ) external {
        beneficiary = address(0);
        amount = bound(amount, 1, JELLY_MAX_SUPPLY);
        freezingPeriod = uint32(
            bound(freezingPeriod, 0, MAX_FREEZING_PERIOD_SPECIAL_CHEST)
        );
        vestingDuration = uint32(
            bound(vestingDuration, 1, MAX_FREEZING_PERIOD_SPECIAL_CHEST / 3)
        );
        nerfParameter = uint8(bound(nerfParameter, 1, 10));

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount + chest.fee());
        vm.expectRevert(Chest__ZeroAddress.selector);
        chest.stakeSpecial(
            amount,
            beneficiary,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );
        vm.stopPrank();
    }

    function testFuzz_stakeSpecialInvalidFreezingPeriod(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod,
        uint32 vestingDuration,
        uint8 nerfParameter
    ) external {
        vm.assume(freezingPeriod > MAX_FREEZING_PERIOD_SPECIAL_CHEST);
        amount = bound(amount, 1, JELLY_MAX_SUPPLY);
        vm.assume(
            beneficiary != address(0) &&
                beneficiary != address(this) &&
                beneficiary != address(jellyToken) &&
                beneficiary != address(chestHarness)
        );
        assumePayable(beneficiary);
        vestingDuration = uint32(
            bound(vestingDuration, 1, MAX_FREEZING_PERIOD_SPECIAL_CHEST / 3)
        );
        nerfParameter = uint8(bound(nerfParameter, 1, 10));

        vm.startPrank(allocator);
        jellyToken.approve(address(chest), amount + chest.fee());
        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.stakeSpecial(
            amount,
            beneficiary,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );
        vm.stopPrank();
    }

    // Regular chest increaseStake fuzz tests
    function testFuzz_increaseStakeIncreaseStakingAmount(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        uint256 positionIndex = 0; // @dev assigning to zero for clarity & better code readability

        increaseAmountFor = bound(
            increaseAmountFor,
            1,
            JELLY_MAX_SUPPLY - chest.getVestingPosition(0).totalVestedAmount
        ); // @dev substracting already staked amount
        increaseFreezingPeriodFor = 0;

        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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

    function testFuzz_increaseStakeIncreaseStakingAmountApprovedAddress(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        uint256 positionIndex = 0; // @dev assigning to zero for clarity & better code readability

        increaseAmountFor = bound(
            increaseAmountFor,
            1,
            JELLY_MAX_SUPPLY - chest.getVestingPosition(0).totalVestedAmount
        ); // @dev substracting already staked amount
        increaseFreezingPeriodFor = 0;

        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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

    function testFuzz_increaseStakeIncreaseFreezingPeriodFrozenChest(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        increaseAmountFor = 0;
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        uint256 positionIndex = 0; // @dev assigning to zero for clarity & better code readability

        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;
        uint256 freezingPeriodBefore = vestingPositionBefore.freezingPeriod;

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

    function testFuzz_increaseStakeIncreaseFreezingPeriodOpenChest(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        increaseAmountFor = 0;
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        uint256 positionIndex = 0;

        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;

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

    function testFuzz_increaseStakeIncreaseFreezingPeriodApprovedAddressFrozenChest(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        increaseAmountFor = 0;
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;
        uint256 freezingPeriodBefore = vestingPositionBefore.freezingPeriod;

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

    function testFuzz_increaseStakeIncreaseFreezingPeriodApprovedAddressOpenChest(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        increaseAmountFor = 0;
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;

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

    function testFuzz_increaseStakeIncreaseStakingAmountAndFreezingPeriodFrozenChest(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        increaseAmountFor = bound(
            increaseAmountFor,
            1,
            JELLY_MAX_SUPPLY - chest.getVestingPosition(0).totalVestedAmount
        ); // @dev substracting already staked amount
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));
        uint256 boosterBefore = vestingPositionBefore.booster;
        uint256 freezingPeriodBefore = vestingPositionBefore.freezingPeriod;

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

    function testFuzz_increaseStakeIncreaseStakingAmountAndFreezingPeriodOpenChest(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        increaseAmountFor = bound(
            increaseAmountFor,
            1,
            JELLY_MAX_SUPPLY - chest.getVestingPosition(0).totalVestedAmount
        ); // @dev substracting already staked amount
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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

    function testFuzz_increaseStakeNotAuthorizedForToken(
        address caller,
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        vm.assume(caller != testAddress);
        increaseAmountFor = bound(
            increaseAmountFor,
            1,
            JELLY_MAX_SUPPLY - chest.getVestingPosition(0).totalVestedAmount
        ); // @dev substracting already staked amount
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        uint positionIndex = 0;

        vm.prank(caller);

        vm.expectRevert(Chest__NotAuthorizedForToken.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
    }

    function testFuzz_increaseStakeNonExistentToken(
        uint256 positionIndex,
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external {
        increaseAmountFor = bound(increaseAmountFor, 1, JELLY_MAX_SUPPLY); // @dev substracting already staked amount
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        vm.expectRevert("ERC721: invalid token ID");
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
    }

    function testFuzz_increaseStakeInvalidFreezingPeriodMax(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        uint256 positionIndex = 0;
        vm.assume(
            increaseFreezingPeriodFor > MAX_FREEZING_PERIOD_REGULAR_CHEST
        );

        vm.prank(testAddress);
        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
    }

    function testFuzz_increaseStakeInvalidFreezingPeriodOpenChest(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openPosition {
        uint256 positionIndex = 0;
        vm.assume(increaseAmountFor > 0);
        increaseFreezingPeriodFor = 0;

        vm.warp(chest.getVestingPosition(positionIndex).cliffTimestamp + 1);

        vm.prank(testAddress);
        vm.expectRevert(Chest__InvalidFreezingPeriod.selector);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
    }

    // Special chest increaseStake fuzz tests
    function testFuzz_increaseStakeSpecialChest(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor
    ) external openSpecialPosition {
        increaseAmountFor = bound(
            increaseAmountFor,
            1,
            JELLY_MAX_SUPPLY - chest.getVestingPosition(0).totalVestedAmount
        ); // @dev substracting already staked amount
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );

        uint256 indexPosition = 0;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), increaseAmountFor);

        vm.expectRevert(Chest__CannotModifySpecial.selector);
        chest.increaseStake(
            indexPosition,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
        vm.stopPrank();
    }

    // Regular chest unstake fuzz tests
    function testFuzz_unstake(uint256 unstakeAmount) external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPositionBefore.totalVestedAmount
        );

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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

    function testFuzz_unstakeApprovedAddress(
        uint256 unstakeAmount
    ) external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPositionBefore.totalVestedAmount
        );

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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
            vestingPositionAfter.totalVestedAmount,
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

    function testFuzz_unstakeNotAuthorizedForToken(
        uint256 unstakeAmount,
        address caller
    ) external openPosition {
        vm.assume(caller != testAddress);

        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPosition.totalVestedAmount
        );

        vm.warp(vestingPosition.cliffTimestamp + 1);

        vm.prank(nonApprovedAddress);
        vm.expectRevert(Chest__NotAuthorizedForToken.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    function testFuzz_unstakeNothingToUnstake(
        uint256 unstakeAmount
    ) external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPosition.totalVestedAmount
        );

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

    function testFuzz_unstakeCannotUnstakeMoreThanReleasable(
        uint256 unstakeAmount
    ) external openPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        vm.assume(unstakeAmount > vestingPosition.totalVestedAmount);

        vm.warp(vestingPosition.cliffTimestamp + 1);

        vm.prank(testAddress);
        vm.expectRevert(Chest__CannotUnstakeMoreThanReleasable.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    // Special chest unstake fuzz tests
    function testFuzz_unstakeSpecialChest(
        uint256 unstakeAmount
    ) external openSpecialPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPositionBefore.totalVestedAmount
        );
        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(testAddress);
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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

    function testFuzz_unstakeSpecialChestApprovedAddress(
        uint256 unstakeAmount
    ) external openSpecialPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPositionBefore.totalVestedAmount
        );

        uint256 accountJellyBalanceBefore = jellyToken.balanceOf(
            approvedAddress
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

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
            vestingPositionAfter.totalVestedAmount,
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

    function testFuzz_unstakeSpecialChestNotAuthorizedForToken(
        uint256 unstakeAmount,
        address caller
    ) external openSpecialPosition {
        vm.assume(caller != testAddress);
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPosition.totalVestedAmount
        );

        vm.warp(vestingPosition.cliffTimestamp + 1);

        vm.prank(nonApprovedAddress);
        vm.expectRevert(Chest__NotAuthorizedForToken.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    function testFuzz_unstakeSpecialChestNothingToUnstake(
        uint256 unstakeAmount
    ) external openSpecialPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPosition.totalVestedAmount
        );

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

    function testFuzz_unstakeSpecialChestCannotUnstakeMoreThanReleasable(
        uint256 unstakeAmount
    ) external openSpecialPosition {
        uint256 positionIndex = 0;
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        vm.assume(unstakeAmount > vestingPosition.totalVestedAmount);

        vm.warp(
            vestingPosition.cliffTimestamp + vestingPosition.vestingDuration
        );

        vm.prank(testAddress);
        vm.expectRevert(Chest__CannotUnstakeMoreThanReleasable.selector);
        chest.unstake(positionIndex, unstakeAmount);
    }

    // setFee fuzz tests
    function testFuzz_setFee(uint256 newFee) external {
        vm.prank(i_deployerAddress);
        chest.setFee(newFee);

        assertEq(chest.fee(), newFee);
    }

    function testFuzz_setFeeCallerIsNotOwner(
        uint256 newFee,
        address caller
    ) external {
        vm.assume(caller != i_deployerAddress);
        vm.prank(caller);

        vm.expectRevert(Ownable__CallerIsNotOwner.selector);

        chest.setFee(newFee);
    }

    // setMaxBooster fuzz tests
    function testFuzz_setMaxBooster(uint128 newMaxBooster) external {
        vm.assume(newMaxBooster > INITIAL_BOOSTER);

        vm.prank(i_deployerAddress);
        chest.setMaxBooster(newMaxBooster);

        assertEq(chest.maxBooster(), newMaxBooster);
    }

    function testFuzz_setMaxBoosterCallerIsNotOwner(
        uint128 newMaxBooster,
        address caller
    ) external {
        vm.assume(caller != i_deployerAddress);
        vm.prank(caller);

        vm.expectRevert(Ownable__CallerIsNotOwner.selector);
        chest.setMaxBooster(newMaxBooster);
    }

    function testFuzz_setMaxBoosterInvalidBoosterValue(
        uint128 newMaxBooster
    ) external {
        vm.assume(newMaxBooster < INITIAL_BOOSTER);

        vm.prank(i_deployerAddress);

        vm.expectRevert(Chest__InvalidBoosterValue.selector);
        chest.setMaxBooster(newMaxBooster);
    }

    // withdrawFees fuzz tests
    function testFuzz_withdrawFees(address beneficiary) external openPosition {
        vm.assume(
            beneficiary != address(0) &&
                beneficiary != address(this) &&
                beneficiary != address(jellyToken) &&
                beneficiary != address(chestHarness)
        );
        assumePayable(beneficiary);

        uint256 totalFeesBefore = chest.totalFees();
        uint256 beneficiaryJellyBalanceBefore = jellyToken.balanceOf(
            beneficiary
        );
        uint256 chestJellyBalanceBefore = jellyToken.balanceOf(address(chest));

        vm.prank(i_deployerAddress);
        chest.withdrawFees(beneficiary);

        assertEq(chest.totalFees(), 0);
        assertEq(
            jellyToken.balanceOf(beneficiary),
            beneficiaryJellyBalanceBefore + totalFeesBefore
        );
        assertEq(
            jellyToken.balanceOf(address(chest)),
            chestJellyBalanceBefore - totalFeesBefore
        );
    }

    function testFuzz_withdrawFeesCallerIsNotOwner(
        address beneficiary,
        address caller
    ) external openPosition {
        vm.assume(beneficiary != address(0));
        vm.assume(caller != i_deployerAddress);
        vm.prank(caller);

        vm.expectRevert(Ownable__CallerIsNotOwner.selector);
        chest.withdrawFees(beneficiary);
    }

    function testFuzz_withdrawFeesNoFeesToWithdraw(
        address beneficiary
    ) external openPosition {
        vm.assume(
            beneficiary != address(0) &&
                beneficiary != address(this) &&
                beneficiary != address(jellyToken) &&
                beneficiary != address(chestHarness)
        );
        assumePayable(beneficiary);

        vm.startPrank(i_deployerAddress);
        chest.withdrawFees(beneficiary);

        vm.expectRevert(Chest__NoFeesToWithdraw.selector);
        chest.withdrawFees(beneficiary);

        vm.stopPrank();
    }

    // getVotingPower fuzz tests
    function testFuzz_getVotingPower(
        uint256 amount,
        uint32 freezingPeriod,
        uint256 numberOfChests
    ) external {
        freezingPeriod = uint32(
            bound(
                freezingPeriod,
                MIN_FREEZING_PERIOD_REGULAR_CHEST,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );
        numberOfChests = bound(numberOfChests, 1, 100);
        amount = bound(
            amount,
            1,
            ((JELLY_MAX_SUPPLY / numberOfChests) - chest.fee() * numberOfChests)
        );

        vm.startPrank(testAddress);

        uint256 power;
        uint256[] memory tokenIds = new uint256[](numberOfChests);
        for (uint256 i; i < numberOfChests; i++) {
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

    function testFuzz_getVotingPowerNotAuthorizedForToken(
        address account
    ) external {
        // create positions
        uint256 amount = 100;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD_REGULAR_CHEST;
        uint256 numberOfChests = 100;

        vm.startPrank(testAddress);
        uint256[] memory tokenIds = new uint256[](numberOfChests);

        for (uint256 i; i < numberOfChests; i++) {
            jellyToken.approve(address(chest), amount + chest.fee());
            chest.stake(amount, testAddress, freezingPeriod);
            tokenIds[i] = i;
        }
        vm.stopPrank();

        vm.assume(account != testAddress);
        vm.prank(account);

        vm.expectRevert(Chest__NotAuthorizedForToken.selector);
        chest.getVotingPower(account, tokenIds);
    }
}
