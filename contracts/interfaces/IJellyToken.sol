// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "../vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";

interface IJellyToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 value) external;
    function transfer(address to, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}