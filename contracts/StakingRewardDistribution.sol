// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Ownable} from "./utils/Ownable.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {RewardVesting} from "./RewardVesting.sol";
import {IJellyToken} from "./interfaces/IJellyToken.sol";
import {MerkleProof} from "./vendor/openzeppelin/v4.9.0/utils/cryptography/MerkleProof.sol";

/**
 * @title StakingRewardDistributioncontract
 * @notice Contract for distributing staking rewards
 */

contract StakingRewardDistribution is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IJellyToken;

    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => mapping(IERC20 => mapping(address => bool)))
        public claimed;
    mapping(uint256 => mapping(IERC20 => uint256)) public tokensDeposited;
    IJellyToken public  immutable jellyToken;
    address vestingContract;

    uint96 public epoch;

    event Claimed(
        address claimant,
        uint256 balance,
        IERC20 token,
        uint96 epoch
    );
    event EpochAdded(uint96 epoch, bytes32 merkleRoot, string ipfs);
    event EpochRemoved(uint96 epoch);
    event Deposited(IERC20 token, uint256 amount, uint96 epoch);
    event ContractChanged(address vestingContract);

    error Claim_LenMissmatch();
    error Claim_ZeroAmount();
    error Claim_FutureEpoch();
    error Claim_AlreadyClaimed();
    error Claim_WrongProof();

    constructor(
        IJellyToken _jellyToken,
        address _owner,
        address _pendingOwner
    ) Ownable(_owner, _pendingOwner) {
        jellyToken = _jellyToken;
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

        epoch =epoch+1;

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
     * @notice Deposit funds into contract
     *
     * @param _amount - amount of tokens to deposit
     * @param _token - token to deposit
     *
     * @dev not using this function to deposit funds will lock the tokens
     *
     * No return only Owner can call
     */

    function deposit(IERC20 _token, uint256 _amount) public returns (uint96) {
        uint96 _epoch=epoch;
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        tokensDeposited[_epoch][_token] += _amount;

        emit Deposited(_token, _amount, epoch);

        return _epoch;
    }

    /**
     * @notice Claim tokens for epoch
     *
     * @param _epochId - id of epoch to be claimed
     * @param _tokens - tokens to clam
     * @param _relativeVotingPower - relative voting power of user
     * @param _merkleProof - merkle proof of claim
     *
     * No return reverts an error
     */

    function claimWeek(
        uint96 _epochId,
        IERC20[] calldata _tokens,
        uint256 _relativeVotingPower,
        bytes32[] memory _merkleProof,
        bool _isVesting
    ) public {
        if (_relativeVotingPower == 0) revert Claim_ZeroAmount();

        if (_epochId >= epoch) revert Claim_FutureEpoch();

        if (
            !_verifyClaim(
                msg.sender,
                _epochId,
                _relativeVotingPower,
                _merkleProof
            )
        ) revert Claim_WrongProof();

        for (uint256 token = 0; token < _tokens.length; token++) {
            uint256 amount = _claim(
                _epochId,
                _tokens[token],
                _relativeVotingPower
            );

            if (_tokens[token] == jellyToken) {
                if (_isVesting) {
                    _tokens[token].approve(vestingContract, amount);
                    RewardVesting(vestingContract).vestStaking(
                        amount,
                        msg.sender
                    );
                } else {
                    jellyToken.burn(amount - amount / 2);
                    jellyToken.safeTransfer(msg.sender, amount / 2);
                }
            } else _tokens[token].safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @notice Claims multiple epochs
     *
     * @param _epochIds - ids of epochs to be claimed
     * @param _tokens - tokens to clam
     * @param _relativeVotingPowers - relative voting power per epoch of user
     * @param _merkleProofs - merkle proofs of claim
     *
     * No return reverts an error
     */

    function claimWeeks(
        uint96[] memory _epochIds,
        IERC20[] calldata _tokens,
        uint256[] memory _relativeVotingPowers,
        bytes32[][] memory _merkleProofs,
        bool _isVesting
    ) public {
        uint256 lenWeeks = _epochIds.length;

        if (
            lenWeeks != _relativeVotingPowers.length ||
            lenWeeks != _merkleProofs.length
        ) revert Claim_LenMissmatch();

        for (uint256 week = 0; week < lenWeeks; week++) {
            if (
                !_verifyClaim(
                    msg.sender,
                    _epochIds[week],
                    _relativeVotingPowers[week],
                    _merkleProofs[week]
                )
            ) revert Claim_WrongProof();
        }

        for (uint256 token = 0; token < _tokens.length; token++) {
            uint256 totalBalance = 0;

            for (uint256 week = 0; week < lenWeeks; week++) {
                uint256 amount = _claim(
                    _epochIds[week],
                    _tokens[token],
                    _relativeVotingPowers[week]
                );

                totalBalance = totalBalance + amount;
            }

            if (totalBalance > 0) {
                if (_tokens[token] == jellyToken) {
                    if (_isVesting) {
                        _tokens[token].approve(vestingContract, totalBalance);
                        RewardVesting(vestingContract).vestStaking(
                            totalBalance,
                            msg.sender
                        );
                    } else
                        _tokens[token].safeTransfer(
                            msg.sender,
                            totalBalance / 2
                        );
                } else _tokens[token].safeTransfer(msg.sender, totalBalance);
            }
        }
    }

    /**
     * @notice Verifies a claim
     *
     * @param _reciver - address of user to verify
     * @param _epochId - id of epoch to be verified
     * @param _relativeVotingPower - relative voting power of user
     * @param _merkleProof - merkle proof of claim
     *
     * No return reverts an error
     */

    function verifyClaim(
        address _reciver,
        uint256 _epochId,
        uint256 _relativeVotingPower,
        bytes32[] memory _merkleProof
    ) public view returns (bool valid) {
        return
            _verifyClaim(
                _reciver,
                _epochId,
                _relativeVotingPower,
                _merkleProof
            );
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

    function _claim(
        uint96 _epochId,
        IERC20 _token,
        uint256 _relativeVotingPower
    ) private returns (uint256 amount) {
        if (claimed[_epochId][_token][msg.sender])
            revert Claim_AlreadyClaimed();

        amount =
            (tokensDeposited[_epochId][_token] * _relativeVotingPower) /
            10 ** 18;

        claimed[_epochId][_token][msg.sender] = true;

        emit Claimed(msg.sender, amount, _token, _epochId);
    }

    function _verifyClaim(
        address _receiver,
        uint256 _epochId,
        uint256 _relativeVotingPower,
        bytes32[] memory _merkleProof
    ) private view returns (bool valid) {
        bytes32 encodedData = keccak256(
            abi.encode(_receiver, _relativeVotingPower)
        );
        bytes32 leaf = keccak256(abi.encodePacked(encodedData));

        return MerkleProof.verify(_merkleProof, merkleRoots[_epochId], leaf);
    }
}
