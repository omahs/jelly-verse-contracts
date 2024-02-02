// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";

/**
 * @title Official Pool Register
 *
 * @notice Store, delete & retrieve pools
 */
contract OfficialPoolsRegister is Ownable {
  uint256 public totalPools;

  struct Pool {
    bytes32 poolId;
    uint256 weight;
  }

  bytes32[] private poolIds;
  mapping(bytes32 => uint256) private officialPools;
  mapping(bytes32 => bool) private isOfficialPoolRegistered;
  
  event OfficialPoolRegistered(address indexed sender, bytes32 indexed poolId, uint256 weight);
  
  error OfficialPoolsRegister_MaxPools50();

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
    if(size > 50) {
       revert OfficialPoolsRegister_MaxPools50();
     }

    for(uint256 i; i < size; i++) {
        Pool memory newPool = pools_[i];
        bytes32 poolId = newPool.poolId;
        uint256 weight = newPool.weight;
        if(!isOfficialPoolRegistered[poolId]) {
          poolIds.push(poolId);
          isOfficialPoolRegistered[poolId] = true;
          ++totalPools;
        }
        officialPools[poolId] = weight;

        emit OfficialPoolRegistered(msg.sender, poolId, weight);
    }
  }

  /**
  /**
  * @notice Return all official pools ids
  * 
  * @return all 'pools'
  */
  function getAllOfficialPools() public view returns(Pool[] memory) {
    Pool[] memory pools = new Pool[](totalPools);
    for (uint256 i=0; i < totalPools; i++) {
      bytes32 poolId = poolIds[i];
      uint256 weight = officialPools[poolId];
      Pool memory pool = Pool(poolId, weight);
      pools[i] = pool;
    }
    return pools;
  }
}
