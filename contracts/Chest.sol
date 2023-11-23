// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {SafeCast} from "./vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {UD60x18, ud, exp, intoUint256} from "./vendor/prb/math/v0.4.1/UD60x18.sol";
import {Ownable} from "./utils/Ownable.sol";
import {VestingLib} from "./utils/VestingLibVani.sol";

contract Chest is ERC721URIStorage, Ownable, VestingLib, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 constant MIN_STAKING_AMOUNT = 100; // change to real value if there is minimum

    string constant BASE_SVG =
        "<svg id='jellys' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 300 100' shape-rendering='geometricPrecision' text-rendering='geometricPrecision'><defs><linearGradient id='ekns5QaWV3l2-fill' x1='0' y1='0.5' x2='1' y2='0.5' spreadMethod='pad' gradientUnits='objectBoundingBox' gradientTransform='translate(0 0)'><stop id='ekns5QaWV3l2-fill-0' offset='0%' stop-color='#9292ff'/><stop id='ekns5QaWV3l2-fill-1' offset='100%' stop-color='#fb42ff'/></linearGradient></defs><rect width='300' height='111.780203' rx='0' ry='0' transform='matrix(1 0 0 0.900963 0 0)' fill='url(#ekns5QaWV3l2-fill)'/><text dx='0' dy='0' font-family='&quot;jellys:::Montserrat&quot;' font-size='16' font-weight='400' transform='translate(15.979677 32.100672)' fill='#fff' stroke-width='0' xml:space='preserve'><tspan y='0' font-weight='400' stroke-width='0'><![CDATA[{]]></tspan><tspan x='0' y='16' font-weight='400' stroke-width='0'><![CDATA[    until:";

    string constant MIDDLE_PART_SVG =
        "]]></tspan><tspan x='0' y='32' font-weight='400' stroke-width='0'><![CDATA[    amount:";

    string constant END_SVG =
        "]]></tspan><tspan x='0' y='48' font-weight='400' stroke-width='0'><![CDATA[}]]></tspan></text></svg>";

    address internal immutable i_jellyToken;
    address internal immutable i_allocator;
    address internal immutable i_distributor;

    uint256 internal tokenId;
    uint256 public fee;
    uint256 internal boosterThreshold;
    uint256 internal minimalStakingPower;
    uint256 internal maxBooster;
    uint256 internal timeFactor;

    mapping(uint256 => uint256) internal latestUnstake;

    event Staked(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 freezedUntil,
        uint32 vestingDuration
    );
    event IncreaseStake(
        uint256 indexed tokenId,
        uint256 totalStaked,
        uint256 freezedUntil
    );
    event Unstake(uint256 indexed tokenId, uint256 amount, uint256 totalStaked);
    event SetFee(uint256 fee);
    event SetBoosterThreshold(uint256 boosterThreshold);
    event SetMinimalStakingPower(uint256 minimalStakingPower);
    event SetMaxBooster(uint256 maxBooster);

    error Chest__ZeroAddress();
    error Chest__InvalidStakingAmount();
    error Chest__NotAuthorizedForSpecial();
    error Chest__NothingToIncrease();
    error Chest__NonTransferrableToken();
    error Chest__NotAuthorizedForToken();
    error Chest__FreezingPeriodNotOver();
    error Chest__CannotUnstakeMoreThanReleasable();
    error Chest__NothingToUnstake();

    modifier onlyAuthorizedForToken(uint256 _tokenId) {
        if (!_isApprovedOrOwner(msg.sender, _tokenId))
            revert Chest__NotAuthorizedForToken();
        _;
    }

    modifier onlyAuthorizedForSpecialChest() {
        if (msg.sender != i_allocator && msg.sender != i_distributor)
            revert Chest__NotAuthorizedForSpecial();
        _;
    }

    constructor(
        address jellyToken,
        address allocator,
        address distributor,
        uint256 fee_,
        uint256 boosterThreshold_,
        uint256 minimalStakingPower_,
        uint256 maxBooster_,
        uint256 timeFactor_,
        address owner,
        address pendingOwner
    ) ERC721("Chest", "CHEST") Ownable(owner, pendingOwner) {
        if (
            jellyToken == address(0) ||
            allocator == address(0) ||
            distributor == (address(0))
        ) revert Chest__ZeroAddress();

        i_jellyToken = jellyToken;
        i_allocator = allocator;
        i_distributor = distributor;
        fee = fee_;
        boosterThreshold = boosterThreshold_;
        minimalStakingPower = minimalStakingPower_;
        maxBooster = maxBooster_;
        timeFactor = timeFactor_;
    }

    /**
     * @notice Stakes tokens and freezes them for a period of time in regular chest.
     *
     * @param amount - amount of tokens to freeze.
     * @param beneficiary - address of the beneficiary.
     * @param freezingPeriod - duration of freezing period in seconds.
     *
     * No return, reverts on error.
     */
    function stake(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod
    ) external nonReentrant {
        if (amount < MIN_STAKING_AMOUNT) revert Chest__InvalidStakingAmount();
        if (beneficiary == address(0)) revert Chest__ZeroAddress();

        IERC20(i_jellyToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount + fee
        );

        uint256 currentTokenId = tokenId;
        vestingPositions[currentTokenId] = createVestingPosition(
            amount,
            beneficiary,
            freezingPeriod > 0 ? freezingPeriod : 1,
            0
        );

        uint256 cliffTimestamp = block.timestamp + freezingPeriod;
        string memory tokenUri = formatTokenUri(amount, cliffTimestamp);

        _safeMint(beneficiary, currentTokenId);
        _setTokenURI(currentTokenId, tokenUri);

        unchecked {
            ++tokenId;
        }
        // should user in event be beneficiary or msg.sender?
        emit Staked(msg.sender, currentTokenId, amount, cliffTimestamp, 0);
    }

    /**
     * @notice Stakes tokens and freezes them for a period of time in special chest.
     *
     * @dev Only allocator and distributor can call this method.
     *
     * @param amount - amount of tokens to freeze.
     * @param beneficiary - address of the beneficiary.
     * @param freezingPeriod - duration of freezing period in seconds.
     * @param vestingDuration - duration of vesting period in seconds.
     *
     * No return, reverts on error.
     */
    function stakeSpecial(
        uint256 amount,
        address beneficiary,
        uint32 freezingPeriod,
        uint32 vestingDuration
    ) external onlyAuthorizedForSpecialChest nonReentrant {
        if (amount < MIN_STAKING_AMOUNT) revert Chest__InvalidStakingAmount();
        if (beneficiary == address(0)) revert Chest__ZeroAddress();
        // maybe check for minimum vesting duration/freeze in this case

        IERC20(i_jellyToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount + fee
        );

        uint256 currentTokenId = tokenId;
        vestingPositions[currentTokenId] = createVestingPosition(
            amount,
            beneficiary,
            freezingPeriod > 0 ? freezingPeriod : 1,
            vestingDuration
        );

        uint256 cliffTimestamp = block.timestamp + freezingPeriod;
        string memory tokenUri = formatTokenUri(amount, cliffTimestamp);

        _safeMint(beneficiary, currentTokenId);
        _setTokenURI(currentTokenId, tokenUri);

        unchecked {
            ++tokenId;
        }

        emit Staked(
            msg.sender,
            currentTokenId,
            amount,
            cliffTimestamp,
            vestingDuration
        );
    }

    /**
     * @notice Increases stake.
     *
     * @param tokenId_ - id of the chest.
     * @param amount - amount of tokens to stake.
     * @param freezingPeriod - duration of freezing period in seconds.
     *
     * No return, reverts on error.
     */
    function increaseStake(
        uint256 tokenId_,
        uint256 amount,
        uint32 freezingPeriod
    ) external onlyAuthorizedForToken(tokenId_) nonReentrant {
        if (amount == 0 && freezingPeriod == 0)
            revert Chest__NothingToIncrease();

        IERC20(i_jellyToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        VestingPosition memory vestingPosition = vestingPositions[tokenId_];

        uint256 newTotalStaked = vestingPosition.totalVestedAmount + amount;
        uint48 newCliffTimestamp = vestingPosition.cliffTimestamp +
            SafeCast.toUint48(freezingPeriod);

        vestingPositions[tokenId_].totalVestedAmount = newTotalStaked;
        vestingPositions[tokenId_].cliffTimestamp = newCliffTimestamp;

        string memory tokenUri = formatTokenUri(
            newTotalStaked,
            newCliffTimestamp
        );

        _setTokenURI(tokenId_, tokenUri);

        emit IncreaseStake(tokenId_, newTotalStaked, newCliffTimestamp);
    }

    /**
     * @notice Unstakes tokens.
     *
     * @param tokenId_ - id of the chest.
     * @param amount - amount of tokens to unstake.
     *
     * No return, reverts on error.
     */
    function unstake(
        uint256 tokenId_,
        uint256 amount
    ) external onlyAuthorizedForToken(tokenId_) nonReentrant {
        VestingPosition memory vestingPosition = vestingPositions[tokenId_];

        uint256 releasableAmount = releasableAmount(tokenId_);

        // shall we use updateReleasedAmount method here?
        if (releasableAmount == 0) {
            revert Chest__NothingToUnstake();
        }

        if (amount > releasableAmount) {
            revert Chest__CannotUnstakeMoreThanReleasable();
        }

        uint256 newTotalStaked = vestingPosition.totalVestedAmount - amount;

        vestingPositions[tokenId_].totalVestedAmount = newTotalStaked;
        vestingPositions[tokenId_].releasedAmount += amount;
        latestUnstake[tokenId_] = block.timestamp;

        IERC20(i_jellyToken).safeTransfer(msg.sender, amount);

        emit Unstake(tokenId_, amount, newTotalStaked);
    }

    /**
     * @dev Retrieves the vesting position at the specified index.
     * @param index The index of the vesting position to retrieve.
     * @return The vesting position at the specified index.
     */
    function getVestingPosition(
        uint256 index
    ) external view returns (VestingPosition memory) {
        return vestingPositions[index];
    }

    /**
     * @notice Retrieves the latest unstake timestamp for the vesting position at the specified index.
     * @param index The index of the vesting position to retrieve the latest unstake timestamp from.
     * @return The latest unstake timestamp for the vesting position at the specified index.
     */
    function getLatestUnstake(uint256 index) external view returns (uint256) {
        return latestUnstake[index];
    }

    /**
     * @notice Sets fee in Jelly token for minting a chest.
     * @dev Only owner can call.
     *
     * @param _fee - new fee.
     *
     * No return, reverts on error.
     */
    function setFee(uint256 _fee) external onlyOwner {
        // should define minimum and maximum values for fee
        fee = _fee;
        emit SetFee(_fee);
    }

    /**
     * @notice Sets booster threshold.
     * @dev Only owner can call.
     *
     * @param _boosterThreshold - new booster threshold.
     *
     * No return, reverts on error.
     */
    function setBoosterThreshold(uint256 _boosterThreshold) external onlyOwner {
        // should define minimum and maximum values for booster threshold
        boosterThreshold = _boosterThreshold;
        emit SetBoosterThreshold(_boosterThreshold);
    }

    /**
     * @notice Sets minimal staking power.
     * @dev Only owner can call.
     *
     * @param _minimalStakingPower - new minimal staking power.
     *
     * No return, reverts on error.
     */
    function setMinimalStakingPower(
        uint256 _minimalStakingPower
    ) external onlyOwner {
        // should define maximum value for this
        minimalStakingPower = _minimalStakingPower;
        emit SetMinimalStakingPower(_minimalStakingPower);
    }

    /**
     * @notice Sets maximal booster.
     * @dev Only owner can call.
     *
     * @param _maxBooster - new maximal booster.
     *
     * No return, reverts on error.
     */
    function setMaxBooster(uint256 _maxBooster) external onlyOwner {
        // should define maximum value for this
        maxBooster = _maxBooster;
        emit SetMaxBooster(_maxBooster);
    }

    function totalSupply() external view returns (uint256) {
        return tokenId;
    }

    function formatTokenUri(
        uint256 amount,
        uint256 cliffTimestamp
    ) internal pure returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                BASE_SVG,
                Strings.toString(cliffTimestamp),
                MIDDLE_PART_SVG,
                Strings.toString(amount),
                END_SVG
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Jelly Chest", "description": "NFT that represents a staking position", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256,
        uint256
    ) internal pure override {
        if (!(from == address(0) || to == address(0))) {
            revert Chest__NonTransferrableToken();
        }
    }
}
