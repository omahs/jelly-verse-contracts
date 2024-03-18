// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
// q is this final compiler version? pragma solidity 0.8.19;  
// q is vendor copied well?
import {ERC20, ERC20Capped} from "./vendor/openzeppelin/v4.9.0/token/ERC20/extensions/ERC20Capped.sol";
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

// i storage is OK
contract JellyToken is ERC20Capped, AccessControl, ReentrancyGuard {
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool internal preminted;
    

    event Preminted(
        address indexed vestingTeam,
        address indexed vestingInvestor,
        address indexed allocator
    );

    error JellyToken__AlreadyPreminted();

    modifier onlyOnce() {
        if (preminted) {
            revert JellyToken__AlreadyPreminted();
        }
        _;
    } 
     // i 10 ** decimals() should be maybe changed to constant 
     // @audit missing input validation(it's redundant I guess) 
     // q who is _defaultAdminRole? is it a multi-sig? because they can mint supply later as they do not rennounce the role? constructor( address _defaultAdminRole )
    constructor(
        address _defaultAdminRole
    )   
        ERC20("Jelly Token", "JLY")
        ERC20Capped(1_000_000_000 * 10 ** decimals())
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdminRole);
        _grantRole(MINTER_ROLE, _defaultAdminRole);
    }

    // @audit missing input validation(it's redundant I guess), not for _minterContract?
    function premint(
        address _vestingTeam,
        address _vestingInvestor,
        address _allocator,
        address _minterContract
    ) external onlyRole(MINTER_ROLE) onlyOnce nonReentrant {
        preminted = true;

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
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) public {
        _burn(_msgSender(), value);
    }
}
