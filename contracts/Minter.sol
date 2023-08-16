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
    require(msg.sender == governance, "Only governance can mint.");
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

    for (uint256 i = 0; i < beneficiaries.length; i++) {
        jellyToken.mint(beneficiaries[i], amount);
    }
  }
}
