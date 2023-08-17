// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import {IJellyToken} from "./interfaces/IJellyToken.sol";

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

  function addBeneficiary(address beneficiary) public onlyGovernance {
    beneficiaries.push(beneficiary);
  }

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
