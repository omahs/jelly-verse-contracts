// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {IJellyToken} from "./interfaces/IJellyToken.sol";
import {IVault, IAsset, IERC20} from "./vendor/balancer-labs/v2-interfaces/v0.4.0/vault/IVault.sol";
import {WeightedPoolUserData} from "./vendor/balancer-labs/v2-interfaces/v0.4.0/pool-weighted/WeightedPoolUserData.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {Ownable} from "./utils/Ownable.sol";

/**
 * @title The Allocator contract
 * @notice Contract for swapping dusd tokens for jelly tokens
 */
contract Allocator is ReentrancyGuard, Ownable {
    address internal immutable i_jellyToken;
    uint256 internal nativeToJellyRatio;
    bytes32 internal jellySwapPoolId;
    address internal jellySwapVault; // ───╮
    bool internal isOver; // ──────────────╯

    event BuyWithNative(uint256 nativeAmount, uint256 jellyAmount);
    event EndBuyingPeriod();
    event NativeToJellyRatioSet(uint256 nativeToJellyRatio);

    error Allocator__CannotBuy();
    error Allocator__NoValueSent();
    error Allocator__NothingToRelease();
    error Allocator__InsufficientFunds();

    modifier canBuy() {
        if (isOver) {
            revert Allocator__CannotBuy();
        }
        _;
    }

    constructor(
        address _jellyToken,
        uint256 _nativeToJellyRatio,
        address _jellySwapVault,
        bytes32 _jellySwapPoolId,
        address _owner,
        address _pendingOwner
    ) Ownable(_owner, _pendingOwner) {
        i_jellyToken = _jellyToken;
        nativeToJellyRatio = _nativeToJellyRatio;
        jellySwapVault = _jellySwapVault;
        jellySwapPoolId = _jellySwapPoolId;
    }

    /**
     * @notice Buys jelly tokens with native token.
     */
    function buyWithNative() external payable nonReentrant canBuy {
        uint256 amount = msg.value;
        if (amount == 0) {
            revert Allocator__NoValueSent();
        }
        uint256 jellyAmount = msg.value * nativeToJellyRatio;

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
            0
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
        IJellyToken(i_jellyToken).approve(jellySwapVault, jellyAmount); 

        IVault(jellySwapVault).joinPool(
            jellySwapPoolId,
            sender,
            recipient,
            request
        );

        IJellyToken(i_jellyToken).mint(msg.sender, jellyAmount);

        emit BuyWithNative(amount, jellyAmount);
    }

    /**
     * @notice Ends buying period.
     * @dev Only owner can call.
     *
     * No return, reverts on error.
     */
    function endBuyingPeriod() external onlyOwner {
        isOver = true;

        emit EndBuyingPeriod();
    }

    /**
     * @notice Sets native to jelly ratio.
     * @dev Only owner can call.
     *
     * @param _nativeToJellyRatio - ratio of native to jelly tokens.
     *
     * No return, reverts on error.
     */
    function setNativeToJellyRatio(uint256 _nativeToJellyRatio) external onlyOwner {
        nativeToJellyRatio = _nativeToJellyRatio;

        emit NativeToJellyRatioSet(nativeToJellyRatio);
    }

    /**
     * @notice Gets Native Token To Jelly Ratio.
     *
     * @return nativeToJellyRatio - ratio of native token to jelly.
     */
    function getRatio() external view returns (uint256) {
        return nativeToJellyRatio;
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