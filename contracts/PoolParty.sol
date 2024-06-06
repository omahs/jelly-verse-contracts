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
    bytes32 public immutable jellySwapPoolId;
    address public immutable jellySwapVault; // ──-╮
    bool public isOver; // ────────────----------──╯
    bool public hasStarted;
    uint88 public seiToJellyRatio;
    address public immutable governance;

    event BuyWithSei(uint256 seiAmount, uint256 jellyAmount, address buyer);
    event EndBuyingPeriod();
    event NativeToJellyRatioSet(uint256 seiToJellyRatio);
    event Started();

    error PoolParty__CannotBuy();
    error PoolParty__NoValueSent();
    error PoolParty__AddressZero();
    error PoolParty__ZeroValue();

    modifier canBuy() {
        if (isOver || !hasStarted) {
            revert PoolParty__CannotBuy();
        }
        _;
    }

    constructor(
        address _jellyToken,
        address _governance,
        uint88 _seiToJellyRatio,
        address _jellySwapVault,
        bytes32 _jellySwapPoolId,
        address _owner,
        address _pendingOwner
    ) Ownable(_owner, _pendingOwner) {
        if (
            _jellyToken == address(0) ||
            _jellySwapVault == address(0) ||
            _jellySwapPoolId == 0 ||
            _governance == address(0) ||
            _seiToJellyRatio == 0
        ) {
            revert PoolParty__AddressZero();
        }
        i_jellyToken = _jellyToken;
        governance = _governance;
        seiToJellyRatio = _seiToJellyRatio;
        jellySwapVault = _jellySwapVault;
        jellySwapPoolId = _jellySwapPoolId;
    }



    /**
     * @notice Starts buying period.
     * @dev Only owner can call.
     *
     * No return, reverts on error.
     */
    function startBuyingPeriod() external onlyOwner {
        hasStarted = true;
        emit Started();
    }

    /**
     * @notice Buys jelly tokens with SEI tokens.
     *
     *
     * No return value
     */
      function buyWithSei() external payable nonReentrant canBuy {

        uint256 _amount=msg.value;

        if (_amount == 0) {
            revert PoolParty__NoValueSent();
        }


        uint256 jellyAmount = _amount * seiToJellyRatio / 1000;

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
                tokens[i] = IERC20(address(0));
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
            fromInternalBalance: false 
        });

        address sender = address(this);
        address recipient = governance; // send LP tokens to governance

        //approve jelly tokens to be spent by jellySwapVault
        IJellyToken(i_jellyToken).approve(jellySwapVault, jellyAmount);

        IVault(jellySwapVault).joinPool{value:_amount}(
            jellySwapPoolId,
            sender,
            recipient,
            request
        );

        IJellyToken(i_jellyToken).safeTransfer(msg.sender, jellyAmount);

        emit BuyWithSei(_amount, jellyAmount, msg.sender);
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
     * @param _seiToJellyRatio - ratio of native to jelly tokens.
     *
     * No return, reverts on error.
     */
    function setSeiToJellyRatio(uint88 _seiToJellyRatio) external onlyOwner {
        if (_seiToJellyRatio == 0) revert PoolParty__ZeroValue();
        seiToJellyRatio = _seiToJellyRatio;

        emit NativeToJellyRatioSet(seiToJellyRatio);
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
