// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Governor, IGovernor} from "./Governor.sol";
import {GovernorSettings} from "./extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "./extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "./GovernorVotes.sol";
import {GovernorTimelockControl, TimelockController} from "./extensions/GovernorTimelockControl.sol";
import {IChest} from "./interfaces/IChest.sol";

contract JellyGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorTimelockControl
{
    error JellyGovernor__InvalidOperation();
    constructor(
        address _chest,
        TimelockController _timelock
    )
        Governor("JellyGovernor", _chest, 3600 /* 1 hour */, 86400 /* 1 day */) // minimum voting delay and period
        GovernorSettings(86400 /* 1 day */, 604800 /* 1 week */, 0) // default voting delay, period and threshold
        GovernorVotes(_chest)
        GovernorTimelockControl(_timelock)
    {}

    function quorum(uint256) public pure override returns (uint256) {
        return 424000; // Chest power of 8_000_000 JELLY staked for a year
    }

    /// @dev JellyGovernor overrides but does not support below functions due to non-standard parameter requirements.
    ///      Removing these methods would necessitate altering the Governor interface, affecting many dependent contracts.
    ///      To preserve interface compatibility while indicating non-support, these functions are explicitly reverted.
    function castVote(
        uint256,
        uint8
    ) public virtual override(IGovernor, Governor) returns (uint256) {
        revert JellyGovernor__InvalidOperation();
    }

    function castVoteWithReason(
        uint256,
        uint8,
        string calldata
    ) public virtual override(IGovernor, Governor) returns (uint256) {
        revert JellyGovernor__InvalidOperation();
    }

    function castVoteBySig(
        uint256,
        uint8,
        uint8,
        bytes32,
        bytes32
    ) public virtual override(IGovernor, Governor) returns (uint256) {
        revert JellyGovernor__InvalidOperation();
    }

    function getVotes(
        address,
        uint256
    ) public view virtual override(IGovernor, Governor) returns (uint256) {
        revert JellyGovernor__InvalidOperation();
    }

    // The following functions are overrides required by Solidity.

    /**
     * @dev Returns the delay period for the Governor.
     */
    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    /**
     * @dev Returns the voting period for the Governor.
     */
    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    /**
     * @dev Returns the state of the proposal.
     */
    function state(
        uint256 proposalId
    )
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @dev Returns the exectuor for the Governor.
     */
    function getExecutor() public view returns (address) {
        return _executor();
    }
    /**
     * @dev Returns the proposal threshold for the Governor.
     */
    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }
}
