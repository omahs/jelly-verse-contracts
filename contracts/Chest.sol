// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {SafeCast} from "./vendor/openzeppelin/v4.9.0/utils/math/SafeCast.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {Ownable} from "./utils/Ownable.sol";
import {VestingLib} from "./utils/VestingLibVani.sol";

contract Chest is ERC721, Ownable, VestingLib, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint256 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;

    uint256 private constant DECIMALS = 1e18;
    uint256 private constant INITIAL_BOOSTER = 1 * DECIMALS;

    string constant BASE_SVG =
        "<svg id='jellys' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 300 100' shape-rendering='geometricPrecision' text-rendering='geometricPrecision'><defs><linearGradient id='ekns5QaWV3l2-fill' x1='0' y1='0.5' x2='1' y2='0.5' spreadMethod='pad' gradientUnits='objectBoundingBox' gradientTransform='translate(0 0)'><stop id='ekns5QaWV3l2-fill-0' offset='0%' stop-color='#9292ff'/><stop id='ekns5QaWV3l2-fill-1' offset='100%' stop-color='#fb42ff'/></linearGradient></defs><rect width='300' height='111.780203' rx='0' ry='0' transform='matrix(1 0 0 0.900963 0 0)' fill='url(#ekns5QaWV3l2-fill)'/><text dx='0' dy='0' font-family='&quot;jellys:::Montserrat&quot;' font-size='16' font-weight='400' transform='translate(15.979677 21.500672)' fill='#fff' stroke-width='0' xml:space='preserve'><tspan y='0' font-weight='400' stroke-width='0'><![CDATA[{]]></tspan><tspan x='0' y='16' font-weight='400' stroke-width='0'><![CDATA[    until:";

    string constant MIDDLE_PART_SVG =
        "]]></tspan><tspan x='0' y='32' font-weight='400' stroke-width='0'><![CDATA[    amount:";

    string constant VESTING_PERIOD_SVG =
        "]]></tspan><tspan x='0' y='48' font-weight='400' stroke-width='0'><![CDATA[    vestingPeriod:";

    string constant END_SVG =
        "]]></tspan><tspan x='0' y='64' font-weight='400' stroke-width='0'><![CDATA[}]]></tspan></text></svg>";

    address internal immutable i_jellyToken;
    address internal immutable i_allocator;
    address internal immutable i_distributor;

    uint256 internal tokenId;
    uint256 public fee;
    uint256 internal boosterThreshold;
    uint256 internal minimalStakingPower;
    uint256 internal maxBooster;
    uint256 internal timeFactor;

    mapping(uint256 => uint256) internal chestData;

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
    error Chest__CastOverflowedDowncast();
    error Chest__NotAuthorizedForSpecial();
    error Chest__NothingToIncrease();
    error Chest__InvalidFreezingPeriod();
    error Chest__CannotModifySpecial();
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
        if (amount == 0) revert Chest__InvalidStakingAmount();
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
        if (cliffTimestamp > type(uint128).max) {
            revert Chest__CastOverflowedDowncast();
        }

        chestData[currentTokenId] = _packData(block.timestamp, cliffTimestamp);

        _safeMint(beneficiary, currentTokenId);

        unchecked {
            ++tokenId;
        }

        // should user in event be beneficiary or msg.sender?
        // changed to beneficiary, makes more sense imo
        // beneficiary != msg.sender  double check with frontend
        emit Staked(beneficiary, currentTokenId, amount, cliffTimestamp, 0);
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
        if (amount == 0) revert Chest__InvalidStakingAmount();
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
        if (cliffTimestamp > type(uint128).max) {
            revert Chest__CastOverflowedDowncast();
        }

        chestData[currentTokenId] = _packData(block.timestamp, cliffTimestamp);

        _safeMint(beneficiary, currentTokenId);

        unchecked {
            ++tokenId;
        }

        emit Staked(
            beneficiary,
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

        VestingPosition memory vestingPosition = vestingPositions[tokenId_];

        if (vestingPosition.vestingDuration == 0) {
            if (freezingPeriod > MAX_FREEZING_PERIOD_REGULAR_CHEST)
                revert Chest__InvalidFreezingPeriod();
        } else {
            // special chest
            revert Chest__CannotModifySpecial();
        }

        IERC20(i_jellyToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 newTotalStaked = vestingPosition.totalVestedAmount + amount;
        uint48 newCliffTimestamp = vestingPosition.cliffTimestamp +
            SafeCast.toUint48(freezingPeriod);

        vestingPositions[tokenId_].totalVestedAmount = newTotalStaked;
        vestingPositions[tokenId_].cliffTimestamp = newCliffTimestamp;

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
        if (releasableAmount == 0 || amount == 0) {
            revert Chest__NothingToUnstake();
        }

        if (amount > releasableAmount) {
            revert Chest__CannotUnstakeMoreThanReleasable();
        }

        uint256 newTotalStaked = vestingPosition.totalVestedAmount - amount;

        vestingPositions[tokenId_].totalVestedAmount = newTotalStaked;
        vestingPositions[tokenId_].releasedAmount += amount;

        chestData[tokenId_] = _packData(
            block.timestamp,
            vestingPosition.cliffTimestamp
        );

        IERC20(i_jellyToken).safeTransfer(msg.sender, amount);

        emit Unstake(tokenId_, amount, newTotalStaked);
    }

    /**
     * @notice Calculates the voting power of all account's chests.
     *
     * @param account - address of the account.
     *
     * @return power - voting power of the account.
     */
    function getVotingPower(
        address account,
        uint256[] calldata tokenIds
    ) external view returns (uint256) {
        uint256 power;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (ownerOf(tokenIds[i]) != account)
                revert Chest__NotAuthorizedForToken();
            power += getChestPower(tokenIds[i]);
        }
        return power;
    } // TO-DO

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

    /**
     * @notice Calculates the booster of the chest.
     *
     * @param tokenId_ - id of the chest.
     * @param vestingDuration_ - duration of vesting period in seconds.
     *
     * @return booster - booster of the chest.
     */
    function calculateBooster(
        uint256 tokenId_,
        uint256 vestingDuration_
    ) public view returns (uint256 booster) {
        if (vestingDuration_ > 0) {
            return INITIAL_BOOSTER;
        }

        uint256 timeSinceUnstaked = block.timestamp -
            getLatestUnstake(tokenId_);

        booster =
            INITIAL_BOOSTER +
            ((timeSinceUnstaked * (maxBooster - INITIAL_BOOSTER)) /
                MAX_FREEZING_PERIOD_REGULAR_CHEST);

        if (booster > maxBooster) {
            booster = maxBooster;
        }
    }

    /**
     * @notice Calculates the voting power of the chest.
     *
     * @param tokenId_ - id of the chest.
     *
     * @return power - voting power of the chest.
     */
    function getChestPower(
        uint256 tokenId_
    ) public view returns (uint256 power) {} // TO-DO

    function tokenURI(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId_),
            "ERC721Metadata: URI query for nonexistent token"
        );
        VestingPosition memory vestingPosition = vestingPositions[tokenId_];

        string memory svg = string(
            abi.encodePacked(
                BASE_SVG,
                Strings.toString(vestingPosition.cliffTimestamp),
                MIDDLE_PART_SVG,
                Strings.toString(vestingPosition.totalVestedAmount),
                VESTING_PERIOD_SVG,
                Strings.toString(vestingPosition.vestingDuration),
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

    function totalSupply() public view returns (uint256) {
        return tokenId;
    }

    /**
     * @notice Retrieves the latest unstake timestamp for the vesting position at the specified index.
     * @param index The index of the vesting position to retrieve the latest unstake timestamp from.
     * @return The latest unstake timestamp for the vesting position at the specified index.
     */
    function getLatestUnstake(uint256 index) public view returns (uint256) {
        uint256 latestUnstake = chestData[index] >> 128;

        return latestUnstake;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        if (!(from == address(0) || to == address(0))) {
            revert Chest__NonTransferrableToken();
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function getPreviousCliff(uint256 index) private view returns (uint256) {
        uint256 previousCliffTimestamp = chestData[index] & type(uint128).max;

        return previousCliffTimestamp;
    }

    function _packData(
        uint256 latestUnstake,
        uint256 cliffTimestamp
    ) private pure returns (uint256) {
        return cliffTimestamp | (latestUnstake << 128);
    }
}
