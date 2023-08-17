// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import {IJellyToken} from "./interfaces/IJellyToken.sol";

/**
 * @title The Minter contract
 * @notice Contract for distributing jelly token rewards
 */
contract Minter {
  IJellyToken public jellyToken;

  uint256 public inflationRate;
  uint256 public inflationPeriod;
  uint256 public lastMintedAt;

  address[] public beneficiaries;
  address public governance;

  modifier onlyGovernance() {
    require(msg.sender == governance, "Only governance can call.");
    _;
  }

  constructor(
    IJellyToken _jellyToken,
    uint256 _inflationRate,
    uint256 _inflationPeriod,
    address _governance,
    address[] memory _beneficiaries
  ) {
    jellyToken = _jellyToken;

    inflationRate = _inflationRate;
    inflationPeriod = _inflationPeriod;
    lastMintedAt = block.timestamp;

    governance = _governance;
    beneficiaries = _beneficiaries;
  }

  /**
   * @notice Mints jelly tokens to beneficiaries based on a fixed inflation curve
   *
   * @dev Only the governance address can call
   *
   * No return, reverts on error.
   */
  function mint() public onlyGovernance {
    uint256 timeSinceLastMint = block.timestamp - lastMintedAt;
    uint256 amount = (timeSinceLastMint * inflationRate) / inflationPeriod;
    lastMintedAt = block.timestamp;

    for (uint256 i = 0; i < beneficiaries.length;) {
      jellyToken.mint(beneficiaries[i], amount);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Adds a new address as a beneficiary
   *
   * @dev Only the governance address can call
   *
   * No return, reverts if address already in beneficiary list
   */
  function addBeneficiary(address beneficiary) public onlyGovernance {
    for (uint256 i = 0; i < beneficiaries.length;) {
      require(beneficiaries[i] != beneficiary, "Address already in beneficiary list.");
      unchecked {
        ++i;
      }
    }

    beneficiaries.push(beneficiary);
  }

  /**
   * @notice Removes an address as a beneficiary
   *
   * @dev Only the governance address can call
   *
   * No return, reverts if invalid address is passed.
   */
  function removeBeneficiary(address beneficiary) public onlyGovernance {
    uint256 beneficiaryIndex = beneficiaries.length; // value denoting invalid address

    for (uint256 i = 0; i < beneficiaries.length;) {
      if (beneficiaries[i] == beneficiary) {
        beneficiaryIndex = i;
      }
      unchecked {
        ++i;
      }
    }

    require(beneficiaryIndex < beneficiaries.length, "Address not in beneficiary list.");

    beneficiaries[beneficiaryIndex] = beneficiaries[beneficiaries.length - 1];
    beneficiaries.pop();
  }
}
