// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "./Chest.sol";

contract Snapshot {
    address internal immutable i_chest;
    uint internal immutable snapshotCounter;
    mapping(uint256 => mapping(address => uint256)) public snapshots;

    event SnapshotTaken(uint indexed snapshotCounter, address indexed snapshotTaker, uint numberOfNfts);

    error Chest__ZeroAddress();
    
    constructor(address _chest) {
        if (_chest == address(0)) revert Chest__ZeroAddress();
        i_chest = _chest;
    }

    function snapshot(uint numberOfNfts) external {
        snapshotCounter++;
        for (uint256 index = 0; index < numberOfNfts; index++) {
            uint256 _votingPower = Chest(i_chest).getChestPower(index);
            address _owner = Chest(i_chest).ownerOf(index);
            snapshots[snapshotCounter][_owner] += _votingPower;
            snapshots[snapshotCounter][address(0)] += _votingPower;
        }
        emit SnapshotTaken(snapshotCounter, msg.sender, numberOfNfts);
    }
}