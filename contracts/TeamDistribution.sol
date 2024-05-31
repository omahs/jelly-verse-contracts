// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./interfaces/IChest.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";

contract TeamDistribution is Ownable {
    uint32 constant LIST_LEN = 15;
    uint256 constant JELLY_AMOUNT = 21_597_390;
    uint32 constant FREEZING_PERIOD = 6 * 30 days;
    uint32 constant VESTING_DURATION = 18 * 30 days;
    uint8 constant NERF_PARAMETER = 0; 

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

    /**
     * @notice Distributes tokens to team members in batches.
     * @dev Only the contract owner can call this function.
     * @dev The `batchLength` must be greater than 0 and within the bounds of the team list.
     * @param batchLength The number of team members to distribute tokens to.
     */
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
                FREEZING_PERIOD,
                VESTING_DURATION,
                NERF_PARAMETER
            );
        }

        emit BatchDistributed(currentIndex, batchLength);
    }

    /**
     * @notice Sets the chest contract address.
     * @dev Only the contract owner can call this function.
     * @dev The chest contract address must not be already set.
     * @param _chestContract The address of the chest contract.
     */
    function setChest(address _chestContract) external onlyOwner {
        if (chestContract != address(0)) {
            revert TeamDistribution__ChestAlreadySet();
        }

        chestContract = _chestContract;

        uint256 totalFees = LIST_LEN * IChest(chestContract).fee();
        jellyToken.approve(chestContract, JELLY_AMOUNT * 1e18 + totalFees);

        emit ChestSet(_chestContract);
    }
    /**
     * @notice Initializes the contract by setting the team members values.
     * @dev This function is called during contract deployment.
     * @dev Only the contract owner can call this function.
     */
    function _initialize() private {
        teamList[0] = Team({
            amount: 2_000_000,
            beneficiary: 0x541CA4922C8C6D1Bb61428Cb449cb7978BF2Eb38
        });
        teamList[1] = Team({
            amount: 2_000_000,
            beneficiary: 0x6D03EFCe3D0fE344E046B313be6eCC6716CF8e32
        });
        teamList[2] = Team({
            amount: 1_011_200,
            beneficiary: 0x661Dc99c45F122Cbc2B03a7DB5888656b9142139
        });
        teamList[3] = Team({
            amount: 2_000_000,
            beneficiary: 0x1C3F3994d288971Dfa9E5f0bE0Abd44dB0aE00Bb
        });
        teamList[4] = Team({
            amount: 2_000_000,
            beneficiary: 0x6dd556BBEE6AD6Cb042B4058695ba5671AbEa579
        });
        teamList[5] = Team({
            amount: 1_011_200,
            beneficiary: 0x7E288F26b4d8428604E5b216477b4823eA8e7c7e
        });
        teamList[6] = Team({
            amount: 2_000_000,
            beneficiary: 0xb182a9AfCc45695f3F63D718Bb98d783E6e3210C
        });
        teamList[7] = Team({
            amount: 2_000_000,
            beneficiary: 0xC48acD04a9887a77e3Fd13ba67016bf19f508423
        });
        teamList[8] = Team({
            amount: 1_011_200,
            beneficiary: 0xFE3adED660C81cCAaDB782C9f0a1cbe81505CB11
        });
        teamList[9] = Team({
            amount: 600_000,
            beneficiary: 0xfF0e0c7E623Fef137945C31A7d3b1e4711eC4Ba5
        });
        teamList[10] = Team({
            amount: 251_750,
            beneficiary: 0x744F5f9f9f83B20f89A8FAE4B3764FB6795D07aF
        });
        teamList[11] = Team({
            amount: 312_040,
            beneficiary: 0x3e3705a554237246137A1e51d626CA4aEC6ddd54
        });
        teamList[12] = Team({
            amount: 2_000_000,
            beneficiary: 0x55863380200ac21cf234462Fd7B94744C3A34B7f
        });
        teamList[13] = Team({
            amount: 2_000_000,
            beneficiary: 0xF9bB310816fe4C277DAe7a6308456f395cD345C2
        });
        teamList[14] = Team({
            amount: 1_400_000,
            beneficiary: 0x4b721A67573297651cd8B4746Ac2e13997d92790
        });
    }
}
