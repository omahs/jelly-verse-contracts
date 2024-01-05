// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Chest} from "../../contracts/Chest.sol";
import {ERC20Token} from "../../contracts/test/ERC20Token.sol";

// Invariants Definitions:
// 1. TransferFrom Restriction: Prohibits the transfer of any chest token.
// 2. Withdrawal Limit: Guarantees that the withdrawal amount cannot exceed the staked balance.
// 4. Booster Cap: Ensures that the booster value for any chest does not surpass the defined maximum booster limit.
// 5. Voting Power Cap: Confirms that the voting power associated with any chest remains within the stipulated maximum threshold.
// 6. Fee Withdrawal Bound: Restricts the owner from withdrawing more fees than the total amount of fees accumulated.

contract ChestHandler is Test {
    uint256 constant JELLY_MAX_SUPPLY = 1_000_000_000 ether;

    uint32 constant MIN_FREEZING_PERIOD_REGULAR_CHEST = 7 days;
    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;

    address immutable beneficiary;

    address[] private actors;

    Chest private immutable chest;
    ERC20Token private immutable jellyToken;

    constructor(
        address beneficiary_,
        Chest chest_,
        ERC20Token jellyToken_,
        address allocator,
        address distributor
    ) {
        beneficiary = beneficiary_;
        chest = chest_;
        jellyToken = jellyToken_;
        actors.push(allocator);
        actors.push(distributor);
    }

    // ERC721 functionalities
    function transferFrom(address from, address to, uint256 tokenId) external {
        tokenId = bound(tokenId, 0, chest.totalSupply() - 1);
        from = chest.ownerOf(tokenId);
        vm.assume(to != address(0) && to != address(this));

        vm.prank(from);
        chest.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        tokenId = bound(tokenId, 0, chest.totalSupply() - 1);
        from = chest.ownerOf(tokenId);
        vm.assume(to != address(0) && to != address(this));
        assumePayable(to);

        vm.prank(from);
        chest.safeTransferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        vm.assume(tokenId < chest.totalSupply());
        vm.assume(to != address(0) && to != address(this));

        address owner = chest.ownerOf(tokenId);

        vm.prank(owner);
        chest.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        vm.assume(
            operator != address(0) &&
                operator != address(this) &&
                operator != msg.sender
        );

        chest.setApprovalForAll(operator, approved);
    }

    // staking functionalities
    function stake(
        uint256 amount,
        address beneficiary_,
        uint32 freezingPeriod,
        address caller
    ) external {
        amount = bound(amount, 1, JELLY_MAX_SUPPLY - chest.fee()); // @dev substracting fee so it's not bigger than max supply
        vm.assume(beneficiary_ != address(0) && beneficiary_ != address(this));
        assumePayable(beneficiary_);
        freezingPeriod = uint32(
            bound(
                freezingPeriod,
                MIN_FREEZING_PERIOD_REGULAR_CHEST,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );
        vm.assume(caller != address(0));

        vm.startPrank(caller);
        jellyToken.mint(amount + chest.fee());

        jellyToken.approve(address(chest), amount + chest.fee());
        chest.stake(amount, beneficiary, freezingPeriod);

        vm.stopPrank();
    }

    function stakeSpecial(
        uint256 amount,
        address beneficiary_,
        uint32 freezingPeriod,
        uint32 vestingDuration,
        uint8 nerfParameter,
        uint256 actorIndexSeed
    ) external {
        amount = bound(amount, 1, JELLY_MAX_SUPPLY - chest.fee()); // @dev substracting fee so it's not bigger than max supply
        vm.assume(beneficiary_ != address(0) && beneficiary_ != address(this));
        assumePayable(beneficiary_);
        freezingPeriod = uint32(
            bound(freezingPeriod, 0, MAX_FREEZING_PERIOD_SPECIAL_CHEST)
        );
        vestingDuration = uint32(
            bound(vestingDuration, 1, MAX_FREEZING_PERIOD_SPECIAL_CHEST / 3)
        ); // 1,5 years
        nerfParameter = uint8(bound(nerfParameter, 1, 10));

        address sender = actors[bound(actorIndexSeed, 0, actors.length - 1)];

        vm.startPrank(sender);
        jellyToken.mint(amount + chest.fee());

        jellyToken.approve(address(chest), amount + chest.fee());
        chest.stakeSpecial(
            amount,
            beneficiary,
            freezingPeriod,
            vestingDuration,
            nerfParameter
        );
        vm.stopPrank();
    }

    function increaseStakingAmount(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor,
        uint256 positionIndex
    ) external {
        positionIndex = bound(positionIndex, 0, chest.totalSupply() - 1);
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 maxStakingAmount = JELLY_MAX_SUPPLY - chest.fee();
        if (vestingPosition.totalVestedAmount >= maxStakingAmount) {
            return;
        } else {
            uint256 stakedAmount = vestingPosition.totalVestedAmount -
                vestingPosition.releasedAmount;
            increaseAmountFor = bound(
                increaseAmountFor,
                1,
                JELLY_MAX_SUPPLY - stakedAmount - chest.fee()
            ); // @dev in this way we assure that we can't increase staking amount above JELLY_MAX_SUPPLY

            increaseFreezingPeriodFor = 0;

            address owner = chest.ownerOf(positionIndex);

            vm.startPrank(owner);
            jellyToken.mint(increaseAmountFor + chest.fee());

            jellyToken.approve(address(chest), increaseAmountFor + chest.fee());
            chest.increaseStake(
                positionIndex,
                increaseAmountFor,
                increaseFreezingPeriodFor
            );

            vm.stopPrank();
        }
    }

    function increaseFreezingPeriod(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor,
        uint256 positionIndex
    ) external {
        increaseAmountFor = 0;
        increaseFreezingPeriodFor = uint32(
            bound(
                increaseFreezingPeriodFor,
                1,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );
        positionIndex = bound(positionIndex, 0, chest.totalSupply() - 1);

        address owner = chest.ownerOf(positionIndex);

        vm.startPrank(owner);
        chest.increaseStake(
            positionIndex,
            increaseAmountFor,
            increaseFreezingPeriodFor
        );
        vm.stopPrank();
    }

    function increaseStakingAmountAndFreezingPeriod(
        uint256 increaseAmountFor,
        uint32 increaseFreezingPeriodFor,
        uint256 positionIndex
    ) external {
        positionIndex = bound(positionIndex, 0, chest.totalSupply() - 1);
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 maxStakingAmount = JELLY_MAX_SUPPLY - chest.fee();
        if (vestingPosition.totalVestedAmount >= maxStakingAmount) {
            return;
        } else {
            uint256 stakedAmount = vestingPosition.totalVestedAmount -
                vestingPosition.releasedAmount;
            increaseAmountFor = bound(
                increaseAmountFor,
                1,
                JELLY_MAX_SUPPLY - stakedAmount - chest.fee()
            ); // @dev in this way we assure that we can't increase staking amount above JELLY_MAX_SUPPLY

            increaseFreezingPeriodFor = 100;

            address owner = chest.ownerOf(positionIndex);

            vm.startPrank(owner);
            jellyToken.mint(increaseAmountFor + chest.fee());

            jellyToken.approve(address(chest), increaseAmountFor + chest.fee());
            chest.increaseStake(
                positionIndex,
                increaseAmountFor,
                increaseFreezingPeriodFor
            );

            vm.stopPrank();
        }
    }

    function unstake(
        uint256 unstakeAmount,
        uint256 positionIndex,
        uint256 timestamp
    ) external {
        positionIndex = bound(positionIndex, 0, chest.totalSupply() - 1);
        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPosition.totalVestedAmount
        );

        uint256 cliffTimestamp = vestingPosition.cliffTimestamp;

        timestamp = bound(timestamp, cliffTimestamp, type(uint32).max);
        address owner = chest.ownerOf(positionIndex);

        vm.warp(timestamp);

        vm.startPrank(owner);
        chest.unstake(positionIndex, unstakeAmount);
        vm.stopPrank();
    }

    function withdrawFees() external {
        uint256 totalFees = chest.totalFees();
        if (totalFees > 0) {
            vm.startPrank(chest.owner());
            chest.withdrawFees(beneficiary);
            vm.stopPrank();
        }
    }
}

contract InvariantChest is Test {
    uint256 constant JELLY_MAX_SUPPLY = 1_000_000_000 ether;

    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;
    uint32 constant MIN_FREEZING_PERIOD_REGULAR_CHEST = 7 days;

    uint64 private constant DECIMALS = 1e18;
    uint64 private constant INITIAL_BOOSTER = 1 * DECIMALS;

    uint256 positionIndex;

    address allocator = makeAddr("allocator");
    address distributor = makeAddr("distributor");
    address testAddress = makeAddr("testAddress");
    address approvedAddress = makeAddr("approvedAddress");
    address nonApprovedAddress = makeAddr("nonApprovedAddress");
    address transferRecipientAddress = makeAddr("transferRecipientAddress");
    address beneficiary = makeAddr("beneficiary");

    Chest public chest;
    ERC20Token public jellyToken;
    ChestHandler public chestHandler;

    error Chest__NonTransferrableToken();

    function setUp() public {
        uint256 fee = 10;
        uint128 maxBooster = 2e18;
        address owner = msg.sender;
        address pendingOwner = testAddress;
        uint32 timeFactor = 7 days;

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
        chestHandler = new ChestHandler(
            beneficiary,
            chest,
            jellyToken,
            allocator,
            distributor
        );

        targetContract(address(chestHandler));
        excludeContract(address(jellyToken));

        vm.prank(allocator);
        jellyToken.mint(1000);

        vm.prank(distributor);
        jellyToken.mint(1000);

        vm.prank(testAddress);
        jellyToken.mint(1000);

        vm.prank(approvedAddress);
        jellyToken.mint(1000);

        // @dev open regular positions so handler has always position to work with
        uint256 amount = 100;
        uint32 freezingPeriod = MIN_FREEZING_PERIOD_REGULAR_CHEST;

        vm.startPrank(testAddress);
        jellyToken.approve(address(chest), amount + chest.fee());
        chest.stake(amount, testAddress, freezingPeriod);

        positionIndex = chest.totalSupply() - 1;
        vm.stopPrank();
    }

    function invariant_unstake() external {
        Chest.VestingPosition memory vestingPositionBefore = chest
            .getVestingPosition(positionIndex);

        uint256 cliffTimestamp = vestingPositionBefore.cliffTimestamp;
        uint256 totalVestedAmount = vestingPositionBefore.totalVestedAmount;

        uint256 maxToRelease = totalVestedAmount -
            vestingPositionBefore.releasedAmount;

        if (maxToRelease > 0) {
            uint256 balanceBefore = jellyToken.balanceOf(address(testAddress));

            uint256 amount;
            amount = bound(amount, 1, maxToRelease);

            vm.warp(cliffTimestamp);

            vm.prank(testAddress);
            chest.unstake(positionIndex, amount);

            uint256 balanceAfter = jellyToken.balanceOf(address(testAddress));

            assertLe(balanceAfter - balanceBefore, totalVestedAmount);
        }
    }

    function invariant_transferFrom() external {
        vm.startPrank(testAddress); // @dev using startPrank to avoid revert

        vm.expectRevert(Chest__NonTransferrableToken.selector);
        chest.transferFrom(
            testAddress,
            transferRecipientAddress,
            positionIndex
        );
        vm.stopPrank();
    }

    function invariant_maxBooster() external {
        uint256 booster = chest.getVestingPosition(positionIndex).booster;
        assertLe(booster, chest.maxBooster());
    }

    function invariant_votingPower() external {
        // @dev this is the maximum voting power in case fee and booster are constant
        uint256 maxStakingAmount = JELLY_MAX_SUPPLY - chest.fee();
        uint256 maxFreezingPeriod = 157 weeks;
        uint256 maxVotingPower = maxStakingAmount *
            maxFreezingPeriod *
            chest.maxBooster();

        Chest.VestingPosition memory vestingPosition = chest.getVestingPosition(
            positionIndex
        );

        uint256 chestPower = chest.getChestPower(
            block.timestamp,
            vestingPosition
        );

        assertLe(chestPower, maxVotingPower);
    }

    function invariant_withdrawFees() external {
        uint256 totalFees = chest.totalFees();
        if (totalFees > 0) {
            uint256 balanceBefore = jellyToken.balanceOf(beneficiary);

            vm.startPrank(chest.owner()); // @dev using startPrank to avoid revert
            chest.withdrawFees(beneficiary);
            vm.stopPrank();

            uint256 balanceAfter = jellyToken.balanceOf(beneficiary);

            assertEq(balanceAfter - balanceBefore, totalFees);
        }
    }
}
