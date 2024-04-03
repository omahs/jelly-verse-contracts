// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./vendor/openzeppelin/v4.9.0/governance/TimelockController.sol";

/**
 * @title The JellyTimelock smart contract
 * @notice A Timelock contract for executing Governance proposals
 */
contract JellyTimelock is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}
}