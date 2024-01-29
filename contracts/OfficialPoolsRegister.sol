// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";

/**
 * @title Official Pool Register
 *
 * @notice Store, delete & retrieve pools
 */
contract OfficialPoolsRegister is Ownable {
  uint256 public totalWeightSum;
  
  struct Pool {
    bytes32 poolId;
    uint256 weight;
  }

  Pool[] private officialPools;
  mapping(bytes32 => bool) private isOfficialPoolRegistered;
  
  event OfficialPoolRegistered(address indexed sender, bytes32 indexed poolId);
  event OfficialPoolDeregistered(address indexed sender, bytes32 indexed poolId);

  error OfficialPoolsRegister_MaxPools10(); 
  error OfficialPoolsRegister_InvalidPool();

  constructor(address newOwner_, address pendingOwner_) Ownable(newOwner_, pendingOwner_) {}

  /**
  * @notice Store array of poolId in official pools array
  *
  * @dev Only owner can call.
  * 
  * @param pools_ to store
  */
  function registerOfficialPool(Pool[] memory pools_) external onlyOwner {
    uint256 size = pools_.length;
    if(size > 10) {
      revert OfficialPoolsRegister_MaxPools10();
    }

    for(uint256 i; i < size; i++) {
        Pool memory newPool = pools_[i];
        bytes32 poolId = newPool.poolId;
        uint256 weight = newPool.weight;
        if(!isOfficialPoolRegistered[poolId]) {
          officialPools.push(newPool);
          totalWeightSum += weight;
          isOfficialPoolRegistered[poolId] = true;

          emit OfficialPoolRegistered(msg.sender, poolId);
        }
    }
  }

  /**
  * @notice Delete poolId from official pools array
  *
  * @dev Only owner can call.
  *
  * @param poolIndex_ to delete
  */
  function deregisterOfficialPool(uint256 poolIndex_) external onlyOwner {
    uint256 officialPoolsSize = officialPools.length;
    if(poolIndex_ >= officialPoolsSize) {
        revert OfficialPoolsRegister_InvalidPool();
    }

    Pool memory poolIdToDelete = officialPools[poolIndex_];
    totalWeightSum -= poolIdToDelete.weight;
    isOfficialPoolRegistered[poolIdToDelete.poolId] = false;
    officialPools[poolIndex_] = officialPools[officialPoolsSize - 1];
    officialPools.pop();
    
    emit OfficialPoolDeregistered(msg.sender, poolIdToDelete.poolId);
  }

  /**
  * @notice Return all official pools ids
  * 
  * @return all 'officailPools'
  */
  function getAllOfficialPools() public view returns(Pool[] memory) {
    return officialPools;
  }
}

