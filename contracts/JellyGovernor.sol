// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Governor.sol";
import "./extensions/GovernorSettings.sol";
import "./extensions/GovernorCountingSimple.sol";
import "./GovernorVotes.sol";
import "./extensions/GovernorTimelockControl.sol";
import "./IChest.sol";

contract JellyGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorTimelockControl {
    constructor(address _chest, TimelockController _timelock)
        Governor("JellyGovernor", _chest, 300 /* 1 hour */, 7200 /* 1 day */) // minimum voting delay and period
        GovernorSettings(7200 /* 1 day */, 50400 /* 1 week */, 0) // default voting delay, period and threshold
        GovernorVotes(_chest)
        GovernorTimelockControl(_timelock)
    {}

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 424000000000000000000000000; // Chest power of 8_000_000 JELLY staked for a year
    }

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function getExecutor() public view returns (address) {
        return _executor();
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
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
