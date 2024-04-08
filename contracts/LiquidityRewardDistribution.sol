// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Ownable} from "./utils/Ownable.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {RewardVesting} from "./RewardVesting.sol";
import {IJellyToken} from "./interfaces/IJellyToken.sol";
import {MerkleProof} from "./vendor/openzeppelin/v4.9.0/utils/cryptography/MerkleProof.sol";

/**
 * @title LiquidityRewardDistribution contract
 * @notice Contract for distributing liqidty mining rewards
 */

contract LiquidityRewardDistribution is Ownable {
    using SafeERC20 for IJellyToken;

    IJellyToken public token;

    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => mapping(address => bool)) public claimed;
    address vestingContract;

    uint96 public epoch;

    event Claimed(address claimant, uint96 epoch, uint256 balance);
    event EpochAdded(uint96 epoch, bytes32 merkleRoot, string ipfs);
    event EpochRemoved(uint96 epoch);
    event ContractChanged(address vestingContract);

    error Claim_LenMissmatch();
    error Claim_ZeroAmount();
    error Claim_FutureEpoch();
    error Claim_AlreadyClaimed();
    error Claim_WrongProof();

    constructor(
        IJellyToken _token,
        address _owner,
        address _pendingOwner
    ) Ownable(_owner, _pendingOwner) {
        token = _token;
    }

    /**
     * @notice Creates epoch for distribtuin
     *
     * @param _merkleRoot - root of merkle tree.
     *
     * No return only Owner can call
     */

    function createEpoch(
        bytes32 _merkleRoot,
        string memory _ipfs
    ) public onlyOwner returns (uint96 epochId) {
        epochId = epoch;

        merkleRoots[epochId] = _merkleRoot;

        epoch =epoch+ 1;

        emit EpochAdded(epochId, _merkleRoot, _ipfs);
    }

    /**
     * @notice Removes an epoch
     *
     * @param _epochId - id of epoch to be removed
     *
     * No return only Owner can call
     */

    function removeEpoch(uint96 _epochId) public onlyOwner {
        merkleRoots[_epochId] = bytes32(0);

        emit EpochRemoved(_epochId);
    }

    /**
     * @notice Claims a single week
     *
     * @param _epochId - id of epoch to be claimed
     * @param _amount - amount of tokens to be claimed
     * @param _merkleProof - merkle proof of claim
     *
     * No return reverts an error
     */

    function claimWeek(
        uint96 _epochId,
        uint256 _amount,
        bytes32[] memory _merkleProof,
        bool _isVesting
    ) public {
        if (_amount == 0) revert Claim_ZeroAmount();

        _claimWeek(_epochId, _amount, _merkleProof);

        if (_isVesting) {
            token.approve(vestingContract, _amount);
            RewardVesting(vestingContract).vestLiquidity(_amount, msg.sender);
        } else {
            token.burn(_amount - _amount / 2);
            token.safeTransfer(msg.sender, _amount / 2);
        }
    }

    /**
     * @notice Claims multiple weeks
     *
     * @param _epochIds - id sof epochs to be claimed
     * @param _amounts - amounts of tokens to be claimed
     * @param _merkleProofs - merkle proofs of claim
     *
     * No return reverts an error
     */

    function claimWeeks(
        uint96[] memory _epochIds,
        uint256[] memory _amounts,
        bytes32[][] memory _merkleProofs,
        bool _isVesting
    ) public {
        uint256 len = _epochIds.length;

        if (len != _amounts.length || len != _merkleProofs.length)
            revert Claim_LenMissmatch();

        uint256 totalBalance = 0;

        for (uint256 i = 0; i < len; i++) {
            _claimWeek(_epochIds[i], _amounts[i], _merkleProofs[i]);

            totalBalance = totalBalance + _amounts[i];
        }

        if (totalBalance > 0) {
            if (_isVesting) {
                token.approve(vestingContract, totalBalance);
                RewardVesting(vestingContract).vestLiquidity(
                    totalBalance,
                    msg.sender
                );
            } else {
                token.burn(totalBalance - totalBalance / 2);
                token.safeTransfer(msg.sender, totalBalance / 2);
            }
        } else {
            revert Claim_ZeroAmount();
        }
    }

    /**
     * @notice Verifies claim
     *
     * @param _reciver - address of user to claim
     * @param _epochId - id of epoch to be claimed
     * @param _amount - amount of tokens to be claimed
     * @param _merkleProof - merkle proof of claim
     *
     * No return reverts an error
     */

    function verifyClaim(
        address _reciver,
        uint256 _epochId,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) public view returns (bool valid) {
        return _verifyClaim(_reciver, _epochId, _amount, _merkleProof);
    }

    /**
     * @notice Changes the vesting contract
     *
     * @param _vestingContract - address of vesting contract
     *
     * No return only Owner can call
     */
    function setVestingContract(address _vestingContract) public onlyOwner {
        vestingContract = _vestingContract;

        emit ContractChanged(_vestingContract);
    }

    function _claimWeek(
        uint96 _epochId,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) private {
        if (_epochId >= epoch) revert Claim_FutureEpoch();

        if (claimed[_epochId][msg.sender]) revert Claim_AlreadyClaimed();

        if (!_verifyClaim(msg.sender, _epochId, _amount, _merkleProof))
            revert Claim_WrongProof();

        claimed[_epochId][msg.sender] = true;

        emit Claimed(msg.sender, _epochId, _amount);
    }

    function _verifyClaim(
        address _receiver,
        uint256 _epochId,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) private view returns (bool valid) {
        bytes32 encodedData = keccak256(abi.encode(_receiver, _amount));
        bytes32 leaf = keccak256(abi.encodePacked(encodedData));

        return MerkleProof.verify(_merkleProof, merkleRoots[_epochId], leaf);
    }
}
