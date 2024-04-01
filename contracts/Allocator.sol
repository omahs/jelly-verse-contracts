// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {IJellyToken} from "./interfaces/IJellyToken.sol";
import {IVault, IAsset, IERC20} from "./vendor/balancer-labs/v2-interfaces/v0.4.0/vault/IVault.sol";
import {WeightedPoolUserData} from "./vendor/balancer-labs/v2-interfaces/v0.4.0/pool-weighted/WeightedPoolUserData.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {Ownable} from "./utils/Ownable.sol";

/**
 * @title The PoolParty contract
 * @notice Contract for swapping native tokens for jelly tokens
 */
contract PoolParty is ReentrancyGuard, Ownable {
    address public immutable i_jellyToken;
    address public immutable usdToken;
    uint256 public usdToJellyRatio;
    bytes32 public jellySwapPoolId; // @audit change this to immutable variable, no need to waste storage // done
    address public jellySwapVault; // ───╮ // @audit change this to immutable variable, no need to waste storage // done
    bool public isOver; // ──────────────╯ // @audit put this above usdToJellyRatio to save storage slot // done

    event BuyWithUsd(uint256 usdAmount, uint256 jellyAmount, address buyer);
    event EndBuyingPeriod();
    event NativeToJellyRatioSet(uint256 usdToJellyRatio);

    error PoolParty__CannotBuy();
    error PoolParty__NoValueSent();

    modifier canBuy() {
        if (isOver) {
            revert PoolParty__CannotBuy();
        }
        _;
    }

    constructor(
        address _jellyToken,
        address _usdToken,
        uint256 _usdToJellyRatio,
        address _jellySwapVault,
        bytes32 _jellySwapPoolId,
        address _owner,
        address _pendingOwner
    ) Ownable(_owner, _pendingOwner) {
        // @audit input validation missing? // done
        i_jellyToken = _jellyToken;
        usdToJellyRatio = _usdToJellyRatio;
        jellySwapVault = _jellySwapVault;
        jellySwapPoolId = _jellySwapPoolId;
        usdToken = _usdToken;
    }

    /**
     * @notice Buys jelly tokens with USD pegged token.
     */
    function buyWithUsd(uint256 amount) external payable nonReentrant canBuy {
        if (amount == 0) {
            revert PoolParty__NoValueSent();
        }
        IERC20(usdToken).transferFrom(msg.sender, address(this), amount); // @audit [M] use safeTransferFrom // done

        uint256 jellyAmount = amount * usdToJellyRatio; // q: how you set ratio below 1? // done

        (IERC20[] memory tokens, , ) = IVault(jellySwapVault).getPoolTokens(
            jellySwapPoolId
        );

        uint256 length = tokens.length;
        uint256[] memory maxAmountsIn = new uint256[](length);

        for (uint256 i; i < length; ) {
            if (tokens[i] == IERC20(i_jellyToken)) {
                maxAmountsIn[i] = jellyAmount;
            } else {
                maxAmountsIn[i] = amount;
            }

            unchecked {
                ++i;
            }
        }

        bytes memory userData = abi.encode(
            WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            maxAmountsIn,
            0 // why 0?
        );

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: _convertERC20sToAssets(tokens),
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: false // False if sending ERC20
        });

        address sender = address(this);
        address recipient = address(0); // burning LP tokens

        //approve jelly tokens to be spent by jellySwapVault
        IJellyToken(i_jellyToken).approve(jellySwapVault, jellyAmount); // @audit use IERC20 or IJellyToken? IERC20 must be used // done

        IVault(jellySwapVault).joinPool(
            jellySwapPoolId,
            sender,
            recipient, // burning LP tokens
            request
        );

        IJellyToken(i_jellyToken).transfer(msg.sender, jellyAmount);

        emit BuyWithUsd(amount, jellyAmount, msg.sender);
    }

    /**
     * @notice Ends buying period and burns remaining JellyTokens.
     * @dev Only owner can call.
     *
     * No return, reverts on error.
     */
    // @audit add sale duration so owner can't end it before the sale ends
    function endBuyingPeriod() external onlyOwner {
        isOver = true;

        uint256 remainingJelly = IJellyToken(i_jellyToken).balanceOf(
            address(this)
        );
        IJellyToken(i_jellyToken).burn(remainingJelly); // burn remaining jelly tokens

        emit EndBuyingPeriod();
    }

    /**
     * @notice Sets native to jelly ratio.
     * @dev Only owner can call.
     *
     * @param _usdToJellyRatio - ratio of native to jelly tokens.
     *
     * No return, reverts on error.
     */
    function setUSDToJellyRatio(uint256 _usdToJellyRatio) external onlyOwner {
        // @audit input validation, e.g. != 0 // done
        usdToJellyRatio = _usdToJellyRatio;

        emit NativeToJellyRatioSet(usdToJellyRatio);
    }

    function _convertERC20sToAssets(
        IERC20[] memory tokens
    ) internal pure returns (IAsset[] memory assets) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            assets := tokens
        }
    }
}
