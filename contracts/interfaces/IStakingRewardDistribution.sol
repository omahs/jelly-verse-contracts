// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;
import {IERC20} from "../vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IStakingRewardDistribution {
    /**
     * @notice Deposit funds into contract
     *
     * @param _amount - amount of tokens to deposit
     * @param _token - token to deposit
     *
     * @return epochId - epoch id of deposit
     *
     * @dev not using this function to deposit funds will lock the tokens
     *
     * No return only Owner can call
     */
    function deposit(IERC20 _token, uint256 _amount) external returns (uint256);
}