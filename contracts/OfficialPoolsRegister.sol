// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";

/**
 * @title Official Pool Register
 *
 * @notice Store, delete & retrieve pools
 */
contract OfficialPoolsRegister is Ownable {
  bytes32[] private officialPoolsIds;
  mapping(bytes32 => bool) private isOfficialPoolRegistered;
  
  event OfficialPoolRegistered(address indexed sender, bytes32 indexed poolId);
  event OfficalPoolDeregistered(address indexed sender, bytes32 indexed poolId);
  
  error OfficialPoolsRegister_InvalidPool();

  constructor(address newOwner_, address pendingOwner_) Ownable(newOwner_, pendingOwner_) {}

  /**
  * @notice Store poolId in official pools array
  *
  * @dev Only owner can call.
  * 
  * @param poolId_ to store
  */
  function registerOfficialPool(bytes32 poolId_) external onlyOwner {
    if(isOfficialPoolRegistered[poolId_]) {
      revert OfficialPoolsRegister_InvalidPool();
    }

    officialPoolsIds.push(poolId_);
    isOfficialPoolRegistered[poolId_] = true;

    emit OfficialPoolRegistered(msg.sender, poolId_);
  }

  /**
  * @notice Delete poolId from official pools array
  *
  * @dev Only owner can call.
  *
  * @param poolIdIndex_ to delete
  */
  function deregisterOfficialPool(uint256 poolIdIndex_) external onlyOwner {
    uint256 officialPoolsSize = officialPoolsIds.length;
    if(poolIdIndex_ >= officialPoolsSize) {
        revert OfficialPoolsRegister_InvalidPool();
    }

    bytes32 poolIdToDelete = officialPoolsIds[poolIdIndex_];
    isOfficialPoolRegistered[poolIdToDelete] = false;
    
    officialPoolsIds[poolIdIndex_] = officialPoolsIds[officialPoolsSize - 1];
    officialPoolsIds.pop();
    
    emit OfficalPoolDeregistered(msg.sender, poolIdToDelete);
  }

  /**
  * @notice Return all official pools ids
  * 
  * @return all 'officailPoolsIds'
  */
  function getAllOfficialPools() public view returns(bytes32[] memory) {
    return officialPoolsIds;
  }
}
