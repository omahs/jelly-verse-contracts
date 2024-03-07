// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./interfaces/IChest.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";

contract TeamDistribution is Ownable {
  
    uint32 constant LIST_LEN = 15;
    uint256 constant JELLY_AMOUNT = 110000000;

    IERC20 public immutable jellyToken;
    address public chestContract;
    uint32 public index;

    event ChestSet(address chest);
    event BatchDistributed(uint256 indexed startIndex, uint256 batchLength);

    error TeamDistribution__InvalidBatchLength();
    error TeamDistribution__DistributionIndexOutOfBounds();
    error TeamDistribution__ChestAlreadySet();
    struct Team {
        uint256 amount;
        address beneficiary;
        uint32 freezingPeriod;
        uint32 vestingDuration;
        uint8 nerfParameter;
    }

    Team[LIST_LEN] public teamList;

    constructor(
        address _jellyTooken,
        address _owner,
        address _pendingOwner
    ) Ownable(_owner, _pendingOwner) {
        jellyToken = IERC20(_jellyTooken);
        _initialize();
    }

    function distribute(uint32 batchLength) external onlyOwner {
        if (batchLength == 0) {
            revert TeamDistribution__InvalidBatchLength();
        }

        uint32 currentIndex = index;

        uint32 endIndex = currentIndex + batchLength;
        if (endIndex > LIST_LEN) {
            revert TeamDistribution__DistributionIndexOutOfBounds();
        }

        index = endIndex;

        for (uint256 i = currentIndex; i < endIndex; i++) {
            IChest(chestContract).stakeSpecial(
                teamList[i].amount * 1e18,
                teamList[i].beneficiary,
                teamList[i].freezingPeriod,
                teamList[i].vestingDuration,
                teamList[i].nerfParameter
            );
        }

        emit BatchDistributed(currentIndex, batchLength);
    }

    function setChest(address _chestContract) external onlyOwner {
        if (chestContract != address(0)) {
            revert TeamDistribution__ChestAlreadySet();
        }

        chestContract = _chestContract;

        uint256 totalFees = LIST_LEN * IChest(chestContract).fee();
        jellyToken.approve(chestContract, JELLY_AMOUNT * 1e18 + totalFees);

        emit ChestSet(_chestContract);
    }

    function _initialize() private {
        teamList[0] = Team({
            amount: 20000000,
            beneficiary: 0x886dD9472c88f09b94bfF3333FfFe2EB2234e821,
            freezingPeriod: 180 days,
            vestingDuration: 1, // @dev 1 second to differentiate from regular chest
            nerfParameter: 10
        });
        teamList[1] = Team({
            amount: 55000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 10
        });
        teamList[2] = Team({
            amount: 2000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[3] = Team({
            amount: 2000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[4] = Team({
            amount: 1000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[5] = Team({
            amount: 2000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[6] = Team({
            amount: 2000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[7] = Team({
            amount: 1000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[8] = Team({
            amount: 2000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[9] = Team({
            amount: 2000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[10] = Team({
            amount: 1000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[11] = Team({
            amount: 2000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[12] = Team({
            amount: 2000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[13] = Team({
            amount: 1000000,
            beneficiary: 0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D,
            freezingPeriod: 180 days,
            vestingDuration: 540 days,
            nerfParameter: 0
        });
        teamList[14] = Team({
            amount: 15000000,
            beneficiary: 0xb28fB8D317d0973F14710921E2215C6AbCcAC139,
            freezingPeriod: 180 days,
            vestingDuration: 180 days,
            nerfParameter: 10
        });
    }
}
