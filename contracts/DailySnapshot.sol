// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

// i change to import {} from 
import "./utils/Ownable.sol";

/**
 * @title Daily Snapshot Contract
 *
 * @notice Store & retrieve daily snapshots blocknumbers per epoch
 */

// @audit storage is not OK
contract DailySnapshot is Ownable {
  bool public started;
  uint8 public epochDaysIndex;
  uint48 public epoch;
  uint48 public beginningOfTheNewDayBlocknumber;
  // i blocks not accurate, dependend on chain.. change name of constant, maybe also put it above storage vars
  // maybe it's better to set this as immutable and set it in constructor depending on the chain of deployment
  uint48 constant ONE_DAY = 7200; // 7200 blocks = 1 day
  mapping(uint48 => uint48[7]) public dailySnapshotsPerEpoch;
  
  event SnapshotingStarted(address sender);
  event DailySnapshotAdded(address sender, uint48 indexed epoch, uint48 indexed randomDayBlocknumber, uint8 indexed epochDaysIndex);

  error DailySnapshot_AlreadyStarted(); 
  error DailySnapshot_NotStarted(); 
  error DailySnapshot_TooEarly(); 

  modifier onlyStarted() {
      if(!started) {
          revert DailySnapshot_NotStarted();
      }
      _;
  }
  // i naming convention different accross contracts
  // i Snapshoting -> Snapshotting
  constructor(address newOwner_, address pendingOwner_) Ownable(newOwner_, pendingOwner_) {}

  // q who is the owner?
  function startSnapshoting() external onlyOwner {
    if(started) {
      revert DailySnapshot_AlreadyStarted();
    }
    started = true;
    beginningOfTheNewDayBlocknumber = uint48(block.number);
    
    emit SnapshotingStarted(msg.sender);
  }

  /**
  * @notice Store random daily snapshot block number
  *
  * @dev Only callable when snapshoting has already started
  */
  function dailySnapshot() external onlyStarted {
    if (block.number - beginningOfTheNewDayBlocknumber <= ONE_DAY) {
      revert DailySnapshot_TooEarly();
    }
    uint48 randomBlockOffset = uint48(block.prevrandao) % ONE_DAY;
    uint48 randomDailyBlock = beginningOfTheNewDayBlocknumber + randomBlockOffset;
    dailySnapshotsPerEpoch[epoch][epochDaysIndex] = randomDailyBlock;

    emit DailySnapshotAdded(msg.sender, epoch, randomDailyBlock, epochDaysIndex);

    unchecked {
      beginningOfTheNewDayBlocknumber += ONE_DAY;
      ++epochDaysIndex;
    }
    if (epochDaysIndex == 7) {
      unchecked {
        epochDaysIndex = 0;
        ++epoch;
      }
    }
  }
}
