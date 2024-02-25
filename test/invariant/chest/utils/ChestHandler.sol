pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Chest} from "../../../../contracts/Chest.sol";
import {ERC20Token} from "../../../../contracts/test/ERC20Token.sol";

contract ChestHandler is Test {
    uint256 constant JELLY_MAX_SUPPLY = 1_000_000_000 ether;
    uint256 constant MIN_STAKING_AMOUNT = 1_000 ether;

    uint32 constant MIN_FREEZING_PERIOD_REGULAR_CHEST = 7 days;
    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;
    
    address immutable i_beneficiary;

    Chest private immutable i_chest;
    ERC20Token private immutable i_jellyToken;

    constructor(
        address beneficiary,
        Chest chest,
        ERC20Token jellyToken
    ) {
        i_beneficiary = beneficiary;
        i_chest = chest;
        i_jellyToken = jellyToken;
    }

    // ERC721 functionalities
    function transferFrom(address from, address to, uint256 tokenId) external {
        tokenId = bound(tokenId, 0, i_chest.totalSupply() - 1);
        from = i_chest.ownerOf(tokenId);
        vm.assume(to != address(0) && to != address(this));

        vm.prank(from);
        i_chest.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        tokenId = bound(tokenId, 0, i_chest.totalSupply() - 1);
        from = i_chest.ownerOf(tokenId);
        vm.assume(to != address(0) && to != address(this));
        assumePayable(to);

        vm.prank(from);
        i_chest.safeTransferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        vm.assume(tokenId < i_chest.totalSupply());
        vm.assume(to != address(0) && to != address(this));

        address owner = i_chest.ownerOf(tokenId);

        vm.prank(owner);
        i_chest.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        vm.assume(
            operator != address(0) &&
                operator != address(this) &&
                operator != msg.sender
        );

        i_chest.setApprovalForAll(operator, approved);
    }

    // Staking functionalities
    function stake(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod,
        address caller
    ) external {
        amount = bound(amount, MIN_STAKING_AMOUNT, JELLY_MAX_SUPPLY - i_chest.fee()); // @dev substracting fee so it's not bigger than max supply
        vm.assume(beneficiary != address(0) && beneficiary != address(this));
        assumePayable(beneficiary);
        freezingPeriod = uint32(
            bound(
                freezingPeriod,
                MIN_FREEZING_PERIOD_REGULAR_CHEST,
                MAX_FREEZING_PERIOD_REGULAR_CHEST
            )
        );
        vm.assume(caller != address(0));

        vm.startPrank(caller);
        i_jellyToken.mint(amount + i_chest.fee());

        i_jellyToken.approve(address(i_chest), amount + i_chest.fee());
        i_chest.stake(amount, beneficiary, freezingPeriod);

        vm.stopPrank();
    }

    function stakeSpecial(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod,
        uint32 vestingDuration,
        uint8 nerfParameter,
        uint256 actorIndexSeed
    ) external {
        amount = bound(amount, MIN_STAKING_AMOUNT, JELLY_MAX_SUPPLY - i_chest.fee()); // @dev substracting fee so it's not bigger than max supply
        vm.assume(beneficiary != address(0) && beneficiary != address(this));
        assumePayable(beneficiary);
        freezingPeriod = uint32(
            bound(freezingPeriod, 0, MAX_FREEZING_PERIOD_SPECIAL_CHEST)
        );
        vestingDuration = uint32(
            bound(vestingDuration, 1, MAX_FREEZING_PERIOD_SPECIAL_CHEST / 3)
        ); // 1,5 years
        nerfParameter = uint8(bound(nerfParameter, 1, 10));

        address sender = makeAddr("specialChestCreator");

        vm.startPrank(sender);
        i_jellyToken.mint(amount + i_chest.fee());

        i_jellyToken.approve(address(i_chest), amount + i_chest.fee());
        i_chest.stakeSpecial(
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
        positionIndex = bound(positionIndex, 0, i_chest.totalSupply() - 1);
        Chest.VestingPosition memory vestingPosition = i_chest
            .getVestingPosition(positionIndex);

        uint256 maxStakingAmount = JELLY_MAX_SUPPLY - i_chest.fee();
        if (vestingPosition.totalVestedAmount >= maxStakingAmount) {
            return;
        } else {
            uint256 stakedAmount = vestingPosition.totalVestedAmount -
                vestingPosition.releasedAmount;
            increaseAmountFor = bound(
                increaseAmountFor,
                1,
                JELLY_MAX_SUPPLY - stakedAmount - i_chest.fee()
            ); // @dev in this way we assure that we can't increase staking amount above JELLY_MAX_SUPPLY

            increaseFreezingPeriodFor = 0;

            address owner = i_chest.ownerOf(positionIndex);

            vm.startPrank(owner);
            i_jellyToken.mint(increaseAmountFor + i_chest.fee());

            i_jellyToken.approve(
                address(i_chest),
                increaseAmountFor + i_chest.fee()
            );
            i_chest.increaseStake(
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
        positionIndex = bound(positionIndex, 0, i_chest.totalSupply() - 1);

        address owner = i_chest.ownerOf(positionIndex);

        vm.startPrank(owner);
        i_chest.increaseStake(
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
        positionIndex = bound(positionIndex, 0, i_chest.totalSupply() - 1);
        Chest.VestingPosition memory vestingPosition = i_chest
            .getVestingPosition(positionIndex);

        uint256 maxStakingAmount = JELLY_MAX_SUPPLY - i_chest.fee();
        if (vestingPosition.totalVestedAmount >= maxStakingAmount) {
            return;
        } else {
            uint256 stakedAmount = vestingPosition.totalVestedAmount -
                vestingPosition.releasedAmount;
            increaseAmountFor = bound(
                increaseAmountFor,
                1,
                JELLY_MAX_SUPPLY - stakedAmount - i_chest.fee()
            ); // @dev in this way we assure that we can't increase staking amount above JELLY_MAX_SUPPLY

            increaseFreezingPeriodFor = 100;

            address owner = i_chest.ownerOf(positionIndex);

            vm.startPrank(owner);
            i_jellyToken.mint(increaseAmountFor + i_chest.fee());

            i_jellyToken.approve(
                address(i_chest),
                increaseAmountFor + i_chest.fee()
            );
            i_chest.increaseStake(
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
        positionIndex = bound(positionIndex, 0, i_chest.totalSupply() - 1);
        Chest.VestingPosition memory vestingPosition = i_chest
            .getVestingPosition(positionIndex);

        unstakeAmount = bound(
            unstakeAmount,
            1,
            vestingPosition.totalVestedAmount
        );

        uint256 cliffTimestamp = vestingPosition.cliffTimestamp;

        timestamp = bound(timestamp, cliffTimestamp, type(uint32).max);
        address owner = i_chest.ownerOf(positionIndex);

        vm.warp(timestamp);

        vm.startPrank(owner);
        i_chest.unstake(positionIndex, unstakeAmount);
        vm.stopPrank();
    }

    function withdrawFees() external {
        uint256 totalFees = i_chest.totalFees();
        if (totalFees > 0) {
            vm.startPrank(i_chest.owner());
            i_chest.withdrawFees(i_beneficiary);
            vm.stopPrank();
        }
    }
}
