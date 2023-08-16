// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IJellyToken {
  /**
   * @dev Mints the specified amount of tokens for an address.
   # Only addresses with MINTER_ROLE can call.
   */
  function mint(address to, uint256 amount) external;
}
