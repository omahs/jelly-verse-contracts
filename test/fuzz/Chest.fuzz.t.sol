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
        assertEq(vestingPosition.nerfParameter, 0);

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

    // setFee fuzz tests
    function testFuzz_setFee(uint256 newFee) external {
        vm.prank(deployerAddress);
        chest.setFee(newFee);

        assertEq(chest.fee(), newFee);
    }

    function testFuzz_setFeeCallerIsNotOwner(
        uint256 newFee,
        address caller
    ) external {
        vm.assume(caller != deployerAddress);
        vm.prank(caller);

        vm.expectRevert(Ownable__CallerIsNotOwner.selector);

        chest.setFee(newFee);
    }

    // setMaxBooster fuzz tests
    function testFuzz_setMaxBooster(uint128 newMaxBooster) external {
        vm.assume(newMaxBooster > INITIAL_BOOSTER);

        vm.prank(deployerAddress);
        chest.setMaxBooster(newMaxBooster);

        assertEq(chest.maxBooster(), newMaxBooster);
    }

    function testFuzz_setMaxBoosterCallerIsNotOwner(
        uint128 newMaxBooster,
        address caller
    ) external {
        vm.assume(caller != deployerAddress);
        vm.prank(caller);

        vm.expectRevert(Ownable__CallerIsNotOwner.selector);
        chest.setMaxBooster(newMaxBooster);
    }

    function testFuzz_setMaxBoosterInvalidBoosterValue(
        uint128 newMaxBooster
    ) external {
        vm.assume(newMaxBooster < INITIAL_BOOSTER);

        vm.prank(deployerAddress);

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

        vm.prank(deployerAddress);
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
        vm.assume(caller != deployerAddress);
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

        vm.startPrank(deployerAddress);
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
