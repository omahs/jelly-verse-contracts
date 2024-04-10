// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {IJellyToken} from "./interfaces/IJellyToken.sol";
import {IVault, IAsset, IERC20} from "./vendor/balancer-labs/v2-interfaces/v0.4.0/vault/IVault.sol";
import {WeightedPoolUserData} from "./vendor/balancer-labs/v2-interfaces/v0.4.0/pool-weighted/WeightedPoolUserData.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {Ownable} from "./utils/Ownable.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";

/**
 * @title The PoolParty contract
 * @notice Contract for swapping native tokens for jelly tokens
 */
contract PoolParty is ReentrancyGuard, Ownable {
    using SafeERC20 for IJellyToken;
 

    address public immutable i_jellyToken;
    address public immutable usdToken;
    bytes32 public immutable jellySwapPoolId;
    address public immutable jellySwapVault; // ───╮
    bool public isOver; // ────────────----------──╯
    uint88 public  usdToJellyRatio;

    event BuyWithUsd(uint256 usdAmount, uint256 jellyAmount, address buyer);
    event EndBuyingPeriod();
    event NativeToJellyRatioSet(uint256 usdToJellyRatio);

    error PoolParty__CannotBuy();
    error PoolParty__NoValueSent();
    error PoolParty__AddressZero();
    error PoolParty__ZeroValue();

    modifier canBuy() {
        if (isOver) {
            revert PoolParty__CannotBuy();
        }
        _;
    }

    constructor(
        address _jellyToken,
        address _usdToken,
        uint88 _usdToJellyRatio,
        address _jellySwapVault,
        bytes32 _jellySwapPoolId,
        address _owner,
        address _pendingOwner
    ) Ownable(_owner, _pendingOwner) {
        if (
            _jellyToken == address(0) ||
            _jellySwapVault == address(0) ||
            _jellySwapPoolId == 0 ||
            _usdToken == address(0) ||
            _usdToJellyRatio == 0
        ) {
            revert PoolParty__AddressZero();
        }
        i_jellyToken = _jellyToken;
        usdToJellyRatio = _usdToJellyRatio;
        jellySwapVault = _jellySwapVault;
        jellySwapPoolId = _jellySwapPoolId;
        usdToken = _usdToken;
    }

    /**
     * @notice Buys jelly tokens with USD pegged token
     *
     * @param _amount amount of usd to be sold
     *
     * No return value
     */
    function buyWithUsd(uint256 _amount) external payable nonReentrant canBuy {
        if (_amount == 0) {
            revert PoolParty__NoValueSent();
        }

       IJellyToken(usdToken).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 jellyAmount = _amount * usdToJellyRatio;

        (IERC20[] memory tokens, , ) = IVault(jellySwapVault).getPoolTokens(
            jellySwapPoolId
        );

        uint256 length = tokens.length;
        uint256[] memory maxAmountsIn = new uint256[](length);

        for (uint256 i; i < length; ) {
            if (tokens[i] == IERC20(i_jellyToken)) {
                maxAmountsIn[i] = jellyAmount;
            } else {
                maxAmountsIn[i] = _amount;
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
        IERC20(usdToken).approve(jellySwapVault, amount); 

        IVault(jellySwapVault).joinPool(
            jellySwapPoolId,
            sender,
            recipient,
            request
        );

        IJellyToken(i_jellyToken).safeTransfer(msg.sender, jellyAmount);

        emit BuyWithUsd(_amount, jellyAmount, msg.sender);
    }

    /**
     * @notice Ends buying period and burns remaining JellyTokens.
     * @dev Only owner can call.
     *
     * No return, reverts on error.
     */
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
    function setUSDToJellyRatio(uint88 _usdToJellyRatio) external onlyOwner {
        if(_usdToJellyRatio==0) revert PoolParty__ZeroValue();
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
