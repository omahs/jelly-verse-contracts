// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "forge-std/console.sol";

/**
 * @title Official Pool Register
 *
 * @notice Store & retrieve pool IDs
 */
contract OfficialPoolsRegisterNew is Ownable {
    uint256 private constant MAX_POOLS = 50;
    bytes32[] public poolIds;
    mapping(bytes32 => bool) public isPoolRegistered;

    event OfficialPoolRegistered(bytes32 indexed poolId, uint32 weight);
    event OfficialPoolDeregistered(bytes32 indexed poolId);

    constructor(address newOwner_, address pendingOwner_) Ownable(newOwner_, pendingOwner_) {}

    function registerOfficialPools(bytes32[] calldata poolIds_, uint32[] calldata weights) external onlyOwner {
        require(poolIds_.length == weights.length, "Mismatched arrays");
        require(poolIds.length + poolIds_.length <= MAX_POOLS, "Max pools reached");

        for (uint256 i = 0; i < poolIds_.length; i++) {
            bytes32 poolId = poolIds_[i];
            require(!isPoolRegistered[poolId], "Pool already registered");

            poolIds.push(poolId);
            uint256 start = gasleft();
            isPoolRegistered[poolId] = true;
            uint256 gasUsed = start - gasleft();
            console.log(gasUsed);
            emit OfficialPoolRegistered(poolId, weights[i]);
        }
    }

    function deregisterOfficialPool(uint256 index, bytes32 poolId) external onlyOwner {
        require(index < poolIds.length, "Invalid index");
        require(poolIds[index] == poolId, "Pool ID mismatch at index");
        require(isPoolRegistered[poolId], "Pool not registered");

        // Move the last poolId to the deregistered pool's slot to avoid gaps
        bytes32 lastPoolId = poolIds[poolIds.length - 1];
        poolIds[index] = lastPoolId;
        // Update the mapping for the new index if it's not the last pool
        if (index != poolIds.length - 1) {
            isPoolRegistered[lastPoolId] = true;
        }
        // Remove the last element
        poolIds.pop();
        // Update the mapping for the deregistered pool
        isPoolRegistered[poolId] = false;

        emit OfficialPoolDeregistered(poolId);
    }

    function getAllOfficialPools() external view returns (bytes32[] memory) {
        return poolIds;
    }
}
