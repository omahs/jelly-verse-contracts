// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "./Governor.sol";
import "./interfaces/IChest.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotes is Governor {
    IChest public immutable chest;

    constructor(address chestAddress) {
        chest = IChest(chestAddress);
    }

    /**
     * @dev Block timestamp as a proxy for the current time.
     */
    function clock() public view virtual override returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }

    /**
     * @dev Machine-readable description of the clock as specified in EIP-6372.
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view virtual override returns (string memory) {
        return "mode=timestamp&from=default";
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     * @dev timepoint parameter is not actually timpoint of the vote, but it's
     *      the last chest ID that is viable for voting.
     *      It's left for compatibility with the Governor Votes mechanism.
     */
    function _getVotes(
        address account,
        uint256 timepoint,
        bytes memory params
    ) internal view virtual override returns (uint256) {
        require(params.length > 0, "JellyGovernor: no params provided in voting weight query");
        (uint256[] memory chestIDs) = abi.decode(params, (uint256[]));
        require(chestIDs.length > 0, "JellyGovernor: no chest IDs provided");

        for (uint8 i = 0; i < chestIDs.length; i++) {
            require(chestIDs[i] <= timepoint, "JellyGovernor: chest not viable for voting");
        }
        return chest.getVotingPower(account, chestIDs);
    }
}
