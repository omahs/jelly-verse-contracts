// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/ERC20.sol";
import {AccessControl} from "./vendor/openzeppelin/v4.9.0/access/AccessControl.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";

/**
 * @title The Jelly ERC20 contract
 *
 *         ## ######## ##       ##       ##    ##
 *         ## ##       ##       ##        ##  ##
 *         ## ##       ##       ##         ####
 *         ## ######   ##       ##          ##
 *   ##    ## ##       ##       ##          ##
 *   ##    ## ##       ##       ##          ##
 *    ######  ######## ######## ########    ##
 *
 */
contract JellyToken is ERC20, AccessControl, ReentrancyGuard {
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private immutable _cap;

    uint256 private _burnedSupply;
    bool private _preminted;

    event Preminted(
        address indexed vestingTeam,
        address indexed vestingInvestor,
        address indexed allocator
    );

    error JellyToken__AlreadyPreminted();
    error JellyToken__ZeroAddress();
    error JellyToken__CapExceeded();

    modifier onlyOnce() {
        if (_preminted) {
            revert JellyToken__AlreadyPreminted();
        }
        _;
    }

    constructor(address _defaultAdminRole) ERC20("Jelly Token", "JLY") {
        if (_defaultAdminRole == address(0)) {
            revert JellyToken__ZeroAddress();
        }

        _cap = 1_000_000_000 * 10 ** decimals();

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdminRole);
        _grantRole(MINTER_ROLE, _defaultAdminRole);
    }

    /**
     * @notice Premints tokens to specified addresses.
     *
     * @dev Only addresses with MINTER_ROLE can call.
     *
     * @param _vestingTeam - address to mint tokens for the vesting team.
     * @param _vestingInvestor - address to mint tokens for the vesting investor.
     * @param _allocator - address to mint tokens for the allocator.
     * @param _minterContract - address of the minter contract.
     *
     * No return, reverts on error.
     */
    function premint(
        address _vestingTeam,
        address _vestingInvestor,
        address _allocator,
        address _minterContract
    ) external onlyRole(MINTER_ROLE) onlyOnce nonReentrant {
        if (
            _vestingTeam == address(0) ||
            _vestingInvestor == address(0) ||
            _allocator == address(0) ||
            _minterContract == address(0)
        ) revert JellyToken__ZeroAddress();

        _preminted = true;

        _mint(_vestingTeam, 133_000_000 * 10 ** decimals());
        _mint(_vestingInvestor, 133_000_000 * 10 ** decimals());
        _mint(_allocator, 133_000_000 * 10 ** decimals());

        _grantRole(MINTER_ROLE, _minterContract);

        emit Preminted(_vestingTeam, _vestingInvestor, _allocator);
    }

    /**
     * @notice Mints specified amount of tokens to address.
     *
     * @dev Only addresses with MINTER_ROLE can call.
     *
     * @param to - address to mint tokens for.
     *
     * @param amount - amount of tokens to mint.
     *
     * No return, reverts on error.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * @param value - the amount of tokens to burn.
     * No return, reverts on error.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) external {
        _burn(_msgSender(), value);

        _burnedSupply += value;
    }

    /**
     * @dev Returns the amount of burned tokens.
     */
    function burnedSupply() external view returns (uint256) {
        return _burnedSupply;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() external view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        uint256 _circulatingSupply = totalSupply();
        if (_circulatingSupply + _burnedSupply + amount > _cap) {
            revert JellyToken__CapExceeded();
        }

        super._mint(account, amount);
    }
}
