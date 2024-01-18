// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title LiquidityRewardDistrubtion contract
 * @notice Contract for distributing liqidty mining rewards
 */

contract LiquidityRewardDistrubtion is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;

    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => mapping(address => bool)) public claimed;

    uint256 public epoch;

    event Claimed(address claimant, uint256 week, uint256 balance);
    event EpochAdded(uint256 Epoch, bytes32 merkleRoot, string _ipfs);
    event EpochRemoved(uint256 epoch);

    error Claim_LenMissmatch();
    error Claim_ZeroAmount();
    error Claim_FutureEpoch();
    error Claim_AlreadyClaimed();
    error Claim_WrongProof();

    constructor(
        IERC20 _token,
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
    ) public onlyOwner returns (uint256 epochId) {
        epochId = epoch;

        merkleRoots[epochId] = _merkleRoot;

        epoch += 1;

        emit EpochAdded(epochId, _merkleRoot, _ipfs);
    }

    /**
     * @notice Removes an epoch
     *
     * @param _epochId - id of epoch to be removed
     *
     * No return only Owner can call
     */

    function removeEpoch(uint256 _epochId) public onlyOwner {
        merkleRoots[_epochId] = bytes32(0);

        emit EpochRemoved(_epochId);
    }

    /**
     * @notice Removes an epoch
     *
     * @param _epochId - id of epoch to be claimed
     * @param _amount - amount of tokens to be claimed
     * @param _merkleProof - merkle proof of claim
     *
     * No return reverts an error
     */

    function claimWeek(
        uint256 _epochId,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) public {
        if (_amount == 0) revert Claim_ZeroAmount();

        _claimWeek(_epochId, _amount, _merkleProof);

        token.safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Removes an epoch
     *
     * @param _epochIds - id sof epochs to be claimed
     * @param _amounts - amounts of tokens to be claimed
     * @param _merkleProofs - merkle proofs of claim
     *
     * No return reverts an error
     */

    function claimWeeks(
        uint256[] memory _epochIds,
        uint256[] memory _amounts,
        bytes32[][] memory _merkleProofs
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
            token.safeTransfer(msg.sender, totalBalance);
        } else {
            revert Claim_ZeroAmount();
        }
    }

    /**
     * @notice Removes an epoch
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

    function _claimWeek(
        uint256 _epochId,
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
