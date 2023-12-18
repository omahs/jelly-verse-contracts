// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {Ownable} from "./utils/Ownable.sol";
import {VestingLib} from "./utils/VestingLibVani.sol";

// TO-DO:
// maybe change first 3 imports to be also from vendor folder
// maybe reduntant checks in stake and stakeSpecial as VestingLib already checks for zero address/amount
// events for booster/nerf parameters? changed structure in vesting
// return values consistency in style
// timeFactor changeable?

contract Chest is ERC721, Ownable, VestingLib, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;
    uint32 constant MIN_FREEZING_PERIOD_REGULAR_CHEST = 7 days;

    uint64 private constant DECIMALS = 1e18;
    uint64 private constant INITIAL_BOOSTER = 1 * DECIMALS;

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

    uint256 public fee;
    uint256 public totalFees;
    uint128 public maxBooster;
    uint8 internal timeFactor;

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
    event SetMaxBooster(uint256 maxBooster);
    event FeeWithdrawn(address indexed beneficiary);

    error Chest__ZeroAddress();
    error Chest__InvalidStakingAmount();
    error Chest__NotAuthorizedForSpecial();
    error Chest__NonExistentToken();
    error Chest__NothingToIncrease();
    error Chest__InvalidFreezingPeriod();
    error Chest__CannotModifySpecial();
    error Chest__NonTransferrableToken();
    error Chest__NotAuthorizedForToken();
    error Chest__FreezingPeriodNotOver();
    error Chest__CannotUnstakeMoreThanReleasable();
    error Chest__NothingToUnstake();
    error Chest__InvalidBoosterValue();

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
        uint128 maxBooster_,
        uint8 timeFactor_,
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
        if (
            freezingPeriod > MAX_FREEZING_PERIOD_REGULAR_CHEST ||
            freezingPeriod < MIN_FREEZING_PERIOD_REGULAR_CHEST
        ) revert Chest__InvalidFreezingPeriod();

        uint256 currentTokenId = index;
        createVestingPosition(
            amount,
            freezingPeriod,
            0,
            INITIAL_BOOSTER,
            0 // OR 1? shouldn't be included in calculation anyway
        );

        unchecked {
            totalFees += fee;
        }
        uint256 cliffTimestamp = block.timestamp + freezingPeriod;

        emit Staked(beneficiary, currentTokenId, amount, cliffTimestamp, 0);

        IERC20(i_jellyToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount + fee
        );
        _safeMint(beneficiary, currentTokenId);
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
        uint32 vestingDuration,
        uint8 nerfParameter
    ) external onlyAuthorizedForSpecialChest nonReentrant {
        if (amount == 0) revert Chest__InvalidStakingAmount();
        if (beneficiary == address(0)) revert Chest__ZeroAddress();
        if (freezingPeriod > MAX_FREEZING_PERIOD_SPECIAL_CHEST)
            revert Chest__InvalidFreezingPeriod();
        // maybe check for minimum vesting duration/freeze in this case

        uint256 currentTokenId = index;
        createVestingPosition(
            amount,
            freezingPeriod > 0 ? freezingPeriod : 1,
            vestingDuration,
            INITIAL_BOOSTER,
            nerfParameter
        );
        unchecked {
            totalFees += fee;
        }
        uint256 cliffTimestamp = block.timestamp + freezingPeriod;

        emit Staked(
            beneficiary,
            currentTokenId,
            amount,
            cliffTimestamp,
            vestingDuration
        );

        IERC20(i_jellyToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount + fee
        );
        _safeMint(beneficiary, currentTokenId);
    }

    /**
     * @notice Increases stake.
     *
     * @param tokenId - id of the chest.
     * @param amount - amount of tokens to stake.
     * @param freezingPeriod - duration of freezing period in seconds.
     *
     * No return, reverts on error.
     */
    function increaseStake(
        uint256 tokenId,
        uint256 amount,
        uint32 freezingPeriod
    ) external onlyAuthorizedForToken(tokenId) nonReentrant {
        if (amount == 0 && freezingPeriod == 0)
            revert Chest__NothingToIncrease();

        if (freezingPeriod > MAX_FREEZING_PERIOD_REGULAR_CHEST)
            revert Chest__InvalidFreezingPeriod();

        VestingPosition memory vestingPosition = vestingPositions[tokenId]; // check this, no need imo for reduntant checks for existance
        uint48 newCliffTimestamp = vestingPosition.cliffTimestamp;

        if (vestingPosition.vestingDuration == 0) {
            // regular chest
            if (freezingPeriod != 0) {
                if (block.timestamp < vestingPosition.cliffTimestamp) {
                    // chest is frozen
                    uint32 currentFreezingPeriod = vestingPosition
                        .freezingPeriod;

                    freezingPeriod =
                        MAX_FREEZING_PERIOD_REGULAR_CHEST -
                        currentFreezingPeriod;

                    newCliffTimestamp =
                        vestingPosition.cliffTimestamp +
                        freezingPeriod;

                    vestingPositions[tokenId]
                        .freezingPeriod = MAX_FREEZING_PERIOD_REGULAR_CHEST;
                    vestingPositions[tokenId]
                        .cliffTimestamp = newCliffTimestamp;
                } else {
                    // chest is open
                    uint128 newBooster = calculateBooster(vestingPosition);

                    newCliffTimestamp = uint48(
                        block.timestamp + freezingPeriod
                    );
                    vestingPositions[tokenId].freezingPeriod = freezingPeriod;

                    vestingPositions[tokenId].booster = newBooster;
                    vestingPositions[tokenId]
                        .cliffTimestamp = newCliffTimestamp;
                }
            }
        } else {
            // special chest
            revert Chest__CannotModifySpecial();
        }

        uint256 newTotalStaked = vestingPosition.totalVestedAmount + amount;

        vestingPositions[tokenId].totalVestedAmount = newTotalStaked;

        emit IncreaseStake(tokenId, newTotalStaked, newCliffTimestamp);

        IERC20(i_jellyToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Unstakes tokens.
     *
     * @param tokenId - id of the chest.
     * @param amount - amount of tokens to unstake.
     *
     * No return, reverts on error.
     */
    function unstake(
        uint256 tokenId,
        uint256 amount
    ) external onlyAuthorizedForToken(tokenId) nonReentrant {
        VestingPosition memory vestingPosition = vestingPositions[tokenId]; // check this, no need imo for reduntant checks for existance
        uint256 releasableAmount = releasableAmount(tokenId);

        // shall we use updateReleasedAmount method here?
        if (releasableAmount == 0 || amount == 0) {
            revert Chest__NothingToUnstake();
        }

        if (amount > releasableAmount) {
            revert Chest__CannotUnstakeMoreThanReleasable();
        }

        uint256 newTotalStaked = vestingPosition.totalVestedAmount - amount;

        vestingPositions[tokenId].totalVestedAmount = newTotalStaked;
        vestingPositions[tokenId].releasedAmount += amount;
        vestingPositions[tokenId].freezingPeriod = 0; // check this
        vestingPositions[tokenId].booster = INITIAL_BOOSTER;

        emit Unstake(tokenId, amount, newTotalStaked);

        IERC20(i_jellyToken).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Sets fee in Jelly token for minting a chest.
     * @dev Only owner can call.
     *
     * @param fee_ - new fee.
     *
     * No return, reverts on error.
     */
    function setFee(uint256 fee_) external onlyOwner {
        // should define minimum and maximum values for fee
        fee = fee_;
        emit SetFee(fee_);
    }

    /**
     * @notice Sets maximal booster.
     * @dev Only owner can call.
     *
     * @param maxBooster_ - new maximal booster.
     *
     * No return, reverts on error.
     */
    function setMaxBooster(uint128 maxBooster_) external onlyOwner {
        // should define maximum value for this
        if (maxBooster_ < INITIAL_BOOSTER) revert Chest__InvalidBoosterValue();
        maxBooster = maxBooster_;
        emit SetMaxBooster(maxBooster_);
    }

    /**
     * @notice Withdraws accumulated fees to the specified beneficiary.
     * @dev Only the contract owner can call this function.
     *
     * @param beneficiary - address to receive the withdrawn fees.
     *
     * No return, reverts on error.
     */
    function withdrawFees(address beneficiary) external onlyOwner {
        if (beneficiary == address(0)) revert Chest__ZeroAddress();

        uint256 amountToWithdraw = totalFees;
        totalFees = 0;

        emit FeeWithdrawn(beneficiary);

        IERC20(i_jellyToken).safeTransfer(beneficiary, amountToWithdraw);
    }

    /**
     * @notice Calculates the voting power of all account's chests.
     *
     * @param account - address of the account
     *
     * @param tokenIds - ids of the chests.
     *
     * @return power - voting power of the account.
     */
    function getVotingPower(
        address account,
        uint256[] memory tokenIds
    ) external view returns (uint256) {
        uint256 power;
        for (uint256 i = 0; i < tokenIds.length; ) {
            if (ownerOf(tokenIds[i]) != account)
                revert Chest__NotAuthorizedForToken();
            power += getChestPower(tokenIds[i]);

            unchecked {
                ++i;
            }
        }
        return power;
    }

    /**
     * @notice Calculates the voting power of the chest for specific timestamp and position values.
     *
     * @param timestamp - timestamp for which the power is calculated.
     *
     * @param vestingPosition - vesting position of the chest.
     *
     * @return power - voting power of the chest.
     */
    function getChestPower(
        uint256 timestamp,
        VestingPosition memory vestingPosition
    ) external view returns (uint256 power) {
        power = calculatePower(timestamp, vestingPosition);
    }

    /**
     * @dev Retrieves the vesting position at the specified index.
     * @param tokenId The index of the vesting position to retrieve.
     * @return The vesting position at the specified index.
     */
    function getVestingPosition(
        uint256 tokenId
    ) public view returns (VestingPosition memory) {
        if (!_exists(tokenId)) {
            revert Chest__NonExistentToken();
        }

        return vestingPositions[tokenId];
    }

    /**
     * @notice Calculates the voting power of the chest for current block.timestamp.
     *
     * @param tokenId - id of the chest.
     *
     * @return power - voting power of the chest.
     */
    function getChestPower(
        uint256 tokenId
    ) public view returns (uint256 power) {
        VestingPosition memory vestingPosition = getVestingPosition(tokenId);
        power = calculatePower(block.timestamp, vestingPosition);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @notice The URI is calculated based on the position values of the chest when called.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        VestingPosition memory vestingPosition = getVestingPosition(tokenId);

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

    /**
     * @notice Gets the total supply of tokens.
     * @return The total supply of tokens.
     */
    function totalSupply() public view returns (uint256) {
        return index;
    }

    /**
     * @dev Hook that is called before token transfer.
     *      See {ERC721 - _beforeTokenTransfer}.
     * @notice This hook disallows token transfers.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        // shall we allow burning? burning means losing jelly tokens
        if (!(from == address(0) || to == address(0))) {
            revert Chest__NonTransferrableToken();
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @notice Calculates the booster of the chest.
     *
     * @param vestingPosition - chest vesting position.
     *
     * @return booster - booster of the chest.
     */
    function calculateBooster(
        VestingPosition memory vestingPosition
    ) internal view returns (uint128 booster) {
        if (vestingPosition.vestingDuration > 0) {
            // special chest
            return INITIAL_BOOSTER;
        }

        uint128 currentBooster = vestingPosition.booster;
        uint32 freezingPeriod = vestingPosition.freezingPeriod;

        booster =
            currentBooster +
            ((freezingPeriod * (maxBooster - INITIAL_BOOSTER)) /
                MAX_FREEZING_PERIOD_REGULAR_CHEST);

        if (booster > maxBooster) {
            booster = maxBooster;
        }
    }

    /**
     * @notice Calculates the voting power of the chest based on the timestamp and vesting position.
     *
     * @param timestamp - current timestamp.
     * @param vestingPosition - vesting position of the chest.
     *
     * @return power - voting power of the chest.
     */
    function calculatePower(
        uint256 timestamp,
        VestingPosition memory vestingPosition
    ) internal view returns (uint256 power) {
        uint256 vestingDuration = vestingPosition.vestingDuration;
        uint256 cliffTimestamp = vestingPosition.cliffTimestamp;
        if (timestamp >= cliffTimestamp + vestingDuration) {
            return 0; // open chest
        }

        // Calculate unfreezing time based on whether vesting has started
        uint256 unfreezingTime;
        if (timestamp >= vestingPosition.cliffTimestamp) {
            // Vesting has started
            uint256 vestingEndTime = cliffTimestamp + vestingDuration;
            unfreezingTime = (vestingEndTime - timestamp) / timeFactor;
        } else {
            // Vesting has not started
            unfreezingTime = cliffTimestamp - timestamp;
        }

        // Calculate power based on vesting type
        if (vestingPosition.vestingDuration == 0) {
            // Regular chest
            uint256 booster = vestingPosition.booster;
            power =
                (booster * vestingPosition.totalVestedAmount * unfreezingTime) /
                DECIMALS;
        } else {
            // Special chest
            uint16 nerfParameter = vestingPosition.nerfParameter;
            power =
                (vestingPosition.totalVestedAmount *
                    unfreezingTime *
                    nerfParameter) /
                10; // nerf parameter has value between 1 and 10
        }
    }
}
