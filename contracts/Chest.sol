// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {ERC721} from "./vendor/openzeppelin/v4.9.0/token/ERC721/ERC721.sol";
import {IERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/openzeppelin/v4.9.0/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol";
import {Math} from "./vendor/openzeppelin/v4.9.0/utils/math/Math.sol";
import {Strings} from "./vendor/openzeppelin/v4.9.0/utils/Strings.sol";
import {Base64} from "./vendor/openzeppelin/v4.9.0/utils/Base64.sol";
import {Ownable} from "./utils/Ownable.sol";
import {VestingLibChest} from "./utils/VestingLibChest.sol";

contract Chest is ERC721, Ownable, VestingLibChest, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint32 constant MAX_FREEZING_PERIOD_REGULAR_CHEST = 3 * 365 days;
    uint32 constant MAX_FREEZING_PERIOD_SPECIAL_CHEST = 5 * 365 days;
    uint32 constant MIN_FREEZING_PERIOD = 7 days;
    uint32 constant MIN_VESTING_DURATION = 1; // @dev need this to make difference between special and regular chest
    uint32 constant MAX_VESTING_DURATION = 3 * 365 days;
    uint8 constant MAX_NERF_PARAMETER = 10;
    uint32 constant TIME_FACTOR = 7 days;

    uint120 private constant DECIMALS = 1e18;
    uint120 private constant INITIAL_BOOSTER = 1 * DECIMALS;
    uint120 private constant WEEKLY_BOOSTER_INCREMENT = 6_410_256_410_256_410; // @dev 1 / 156 weeks

    uint256 public constant MIN_STAKING_AMOUNT = 1_000 * DECIMALS;
    uint120 public constant MAX_BOOSTER = 2 * DECIMALS;

    string constant BASE_SVG =
        "<svg id='jellys' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 300 100' shape-rendering='geometricPrecision' text-rendering='geometricPrecision'><defs><linearGradient id='ekns5QaWV3l2-fill' x1='0' y1='0.5' x2='1' y2='0.5' spreadMethod='pad' gradientUnits='objectBoundingBox' gradientTransform='translate(0 0)'><stop id='ekns5QaWV3l2-fill-0' offset='0%' stop-color='#9292ff'/><stop id='ekns5QaWV3l2-fill-1' offset='100%' stop-color='#fb42ff'/></linearGradient></defs><rect width='300' height='111.780203' rx='0' ry='0' transform='matrix(1 0 0 0.900963 0 0)' fill='url(#ekns5QaWV3l2-fill)'/><text dx='0' dy='0' font-family='&quot;jellys:::Montserrat&quot;' font-size='16' font-weight='400' transform='translate(15.979677 21.500672)' fill='#fff' stroke-width='0' xml:space='preserve'><tspan y='0' font-weight='400' stroke-width='0'><![CDATA[{]]></tspan><tspan x='0' y='16' font-weight='400' stroke-width='0'><![CDATA[    until:";

    string constant MIDDLE_PART_SVG =
        "]]></tspan><tspan x='0' y='32' font-weight='400' stroke-width='0'><![CDATA[    amount:";

    string constant VESTING_PERIOD_SVG =
        "]]></tspan><tspan x='0' y='48' font-weight='400' stroke-width='0'><![CDATA[    vestingPeriod:";

    string constant END_SVG =
        "]]></tspan><tspan x='0' y='64' font-weight='400' stroke-width='0'><![CDATA[}]]></tspan></text></svg>";

    address internal immutable i_jellyToken;

    uint128 public fee;
    uint128 public totalFees;

    event Staked(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 freezedUntil,
        uint32 vestingDuration,
        uint120 booster,
        uint8 nerfParameter
    );
    event IncreaseStake(
        uint256 indexed tokenId,
        uint256 totalStaked,
        uint256 freezedUntil,
        uint120 booster
    );
    event Unstake(
        uint256 indexed tokenId,
        uint256 amount,
        uint256 totalStaked,
        uint120 booster
    );
    event SetFee(uint128 fee);
    event FeeWithdrawn(address indexed beneficiary);

    error Chest__ZeroAddress();
    error Chest__InvalidStakingAmount();
    error Chest__NonExistentToken();
    error Chest__NothingToIncrease();
    error Chest__InvalidFreezingPeriod();
    error Chest__InvalidVestingDuration();
    error Chest__InvalidNerfParameter();
    error Chest__CannotModifySpecial();
    error Chest__NonTransferrableToken();
    error Chest__NotAuthorizedForToken();
    error Chest__FreezingPeriodNotOver();
    error Chest__CannotUnstakeMoreThanReleasable();
    error Chest__NothingToUnstake();
    error Chest__InvalidBoosterValue();
    error Chest__NoFeesToWithdraw();

    modifier onlyAuthorizedForToken(uint256 _tokenId) {
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) {
            revert Chest__NotAuthorizedForToken();
        }
        _;
    }

    constructor(
        address jellyToken,
        uint128 mintingFee,
        address owner,
        address pendingOwner
    ) ERC721("Chest", "CHEST") Ownable(owner, pendingOwner) {
        if (jellyToken == address(0)) {
            revert Chest__ZeroAddress();
        }

        i_jellyToken = jellyToken;
        fee = mintingFee;
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
        if (
            freezingPeriod > MAX_FREEZING_PERIOD_REGULAR_CHEST ||
            freezingPeriod < MIN_FREEZING_PERIOD
        ) {
            revert Chest__InvalidFreezingPeriod();
        }

        uint256 currentTokenId = index;
        createVestingPosition(
            amount,
            freezingPeriod,
            0,
            INITIAL_BOOSTER,
            10 // @dev nerf parameter is hardcoded to 10 for regular chests (no nerf, not included in calculations)
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
            0,
            INITIAL_BOOSTER,
            10
        );

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
     * @dev Anyone can call this function, it's meant to be used by
     *      partners and investors because of vestingPeriod.
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
    ) external nonReentrant {
        if (amount < MIN_STAKING_AMOUNT) revert Chest__InvalidStakingAmount();
        if (beneficiary == address(0)) revert Chest__ZeroAddress();
        if (
            freezingPeriod > MAX_FREEZING_PERIOD_SPECIAL_CHEST ||
            freezingPeriod < MIN_FREEZING_PERIOD
        ) {
            revert Chest__InvalidFreezingPeriod();
        }
        if (
            vestingDuration < MIN_VESTING_DURATION ||
            vestingDuration > MAX_VESTING_DURATION
        ) {
            revert Chest__InvalidVestingDuration();
        }
        if (nerfParameter > MAX_NERF_PARAMETER)
            revert Chest__InvalidNerfParameter();

        uint256 currentTokenId = index;
        createVestingPosition(
            amount,
            freezingPeriod,
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
            vestingDuration,
            INITIAL_BOOSTER,
            nerfParameter
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
     * @param extendFreezingPeriod - duration of freezing period extension in seconds.
     *
     * No return, reverts on error.
     */
    function increaseStake(
        uint256 tokenId,
        uint256 amount,
        uint32 extendFreezingPeriod
    ) external onlyAuthorizedForToken(tokenId) nonReentrant {
        if (amount == 0 && extendFreezingPeriod == 0) {
            revert Chest__NothingToIncrease();
        }

        if (extendFreezingPeriod > MAX_FREEZING_PERIOD_REGULAR_CHEST) {
            revert Chest__InvalidFreezingPeriod();
        }

        VestingPosition memory vestingPosition = vestingPositions[tokenId];
        uint48 newCliffTimestamp = vestingPosition.cliffTimestamp;
        uint120 newAccumulatedBooster = vestingPosition.accumulatedBooster; // I think I will need this one :)
        if (vestingPosition.vestingDuration == 0) {
            // regular chest
            if (block.timestamp < vestingPosition.cliffTimestamp) {
                // chest is frozen
                newCliffTimestamp =
                    vestingPosition.cliffTimestamp +
                    extendFreezingPeriod;

                if (
                    newCliffTimestamp >
                    block.timestamp + MAX_FREEZING_PERIOD_REGULAR_CHEST
                ) {
                    revert Chest__InvalidFreezingPeriod();
                }
                vestingPositions[tokenId].cliffTimestamp = newCliffTimestamp;
            } else {
                // chest is open
                if (extendFreezingPeriod == 0) {
                    // chest is open, freezing period must be set to non-zero value
                    revert Chest__InvalidFreezingPeriod();
                }
                if (
                    vestingPosition.totalVestedAmount -
                        vestingPosition.releasedAmount +
                        amount <
                    MIN_STAKING_AMOUNT
                ) revert Chest__InvalidStakingAmount();

                newAccumulatedBooster = calculateBooster(
                    vestingPosition,
                    uint48(block.timestamp)
                );

                newCliffTimestamp = uint48(
                    block.timestamp + extendFreezingPeriod
                );

                vestingPositions[tokenId]
                    .accumulatedBooster = newAccumulatedBooster;
                vestingPositions[tokenId].cliffTimestamp = newCliffTimestamp;
                vestingPositions[tokenId].boosterTimestamp = uint48(
                    block.timestamp
                );
            }
        } else {
            // special chest
            revert Chest__CannotModifySpecial();
        }

        uint256 newTotalStaked = vestingPosition.totalVestedAmount + amount;

        vestingPositions[tokenId].totalVestedAmount = newTotalStaked;

        emit IncreaseStake(
            tokenId,
            newTotalStaked,
            newCliffTimestamp,
            newAccumulatedBooster
        );

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
        VestingPosition storage vestingPosition = vestingPositions[tokenId];
        uint256 releasableAmount = releasableAmount(tokenId);
        if (releasableAmount == 0 || amount == 0) {
            revert Chest__NothingToUnstake();
        }

        if (amount > releasableAmount) {
            revert Chest__CannotUnstakeMoreThanReleasable();
        }

        vestingPosition.releasedAmount += amount;
        vestingPosition.accumulatedBooster = INITIAL_BOOSTER;
        vestingPosition.boosterTimestamp = 0; // @dev this indicates that the chest is unstaked
        uint256 newTotalStaked = vestingPosition.totalVestedAmount -
            vestingPosition.releasedAmount;

        emit Unstake(tokenId, amount, newTotalStaked, INITIAL_BOOSTER);

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
    function setFee(uint128 fee_) external onlyOwner {
        fee = fee_;
        emit SetFee(fee_);
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
        if (amountToWithdraw == 0) revert Chest__NoFeesToWithdraw();

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
     * @return - voting power of the account.
     */
    function getVotingPower(
        address account,
        uint256[] memory tokenIds
    ) external view returns (uint256) {
        uint256 power;
        for (uint256 i = 0; i < tokenIds.length; ) {
            if (ownerOf(tokenIds[i]) != account) {
                revert Chest__NotAuthorizedForToken();
            }
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
     * @return - voting power of the chest.
     */
    function estimateChestPower(
        uint256 timestamp,
        VestingPosition memory vestingPosition
    ) external pure returns (uint256) {
        uint256 power = calculatePower(timestamp, vestingPosition);
        return power;
    }

    /**
     * @dev Retrieves the vesting position at the specified index.
     * @param tokenId The index of the vesting position to retrieve.
     * @return - The vesting position at the specified index.
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
     * @return - voting power of the chest.
     */
    function getChestPower(uint256 tokenId) public view returns (uint256) {
        VestingPosition memory vestingPosition = getVestingPosition(tokenId);

        uint256 power = calculatePower(block.timestamp, vestingPosition);
        return power;
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
     * @return - The total supply of tokens.
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
     * @return - booster of the chest.
     */
    function calculateBooster(
        VestingPosition memory vestingPosition,
        uint48 timestamp
    ) internal pure returns (uint120) {
        uint120 booster;
        if (vestingPosition.vestingDuration > 0) {
            // special chest
            return INITIAL_BOOSTER;
        }
        if (vestingPosition.boosterTimestamp == 0) {
            // unstaked chest
            return INITIAL_BOOSTER;
        }
        timestamp = vestingPosition.cliffTimestamp > timestamp
            ? timestamp
            : vestingPosition.cliffTimestamp;
        uint120 accumulatedBooster = vestingPosition.accumulatedBooster;

        uint120 weeksPassed = uint120(
            Math.ceilDiv(
                timestamp - vestingPosition.boosterTimestamp,
                TIME_FACTOR
            )
        );

        booster = accumulatedBooster + (weeksPassed * WEEKLY_BOOSTER_INCREMENT);
        if (booster > MAX_BOOSTER) {
            booster = MAX_BOOSTER;
        }
        return booster;
    }

    /**
     * @notice Calculates the voting power of the chest based on the timestamp and vesting position.
     *
     * @param timestamp - current timestamp.
     * @param vestingPosition - vesting position of the chest.
     *
     * @return - voting power of the chest.
     */
    function calculatePower(
        uint256 timestamp,
        VestingPosition memory vestingPosition
    ) internal pure returns (uint256) {
        uint256 power;

        uint256 vestingDuration = vestingPosition.vestingDuration;
        uint256 cliffTimestamp = vestingPosition.cliffTimestamp;
        uint256 unfreezeTime = cliffTimestamp + vestingDuration;

        // chest is open, return 0 power
        if (timestamp > unfreezeTime) {
            return 0;
        }

        // calculate regular freezing time in weeks
        uint256 regularFreezingTime = (cliffTimestamp > timestamp)
            ? Math.ceilDiv(cliffTimestamp - timestamp, TIME_FACTOR)
            : 0;

        // calculate power based on vesting type
        if (vestingPosition.vestingDuration == 0) {
            // regular chest
            uint120 booster = calculateBooster(
                vestingPosition,
                uint48(timestamp)
            );
            power =
                (booster *
                    (vestingPosition.totalVestedAmount -
                        vestingPosition.releasedAmount) *
                    regularFreezingTime) /
                (MIN_STAKING_AMOUNT * DECIMALS); // @dev scaling because of minimum staking amount and booster
        } else {
            // special chest
            uint256 linearFreezingTime;
            if (timestamp < cliffTimestamp) {
                // before the cliff, linear freezing time remains constant
                linearFreezingTime =
                    Math.ceilDiv(vestingDuration, TIME_FACTOR) /
                    2;
            } else {
                // after the cliff, linear freezing time starts to decrease
                linearFreezingTime =
                    Math.ceilDiv(unfreezeTime - timestamp, TIME_FACTOR) /
                    2;
            }

            // calculate total freezing time in weeks
            uint256 totalFreezingTimeInWeeks = regularFreezingTime +
                linearFreezingTime;

            // apply nerf parameter
            uint8 nerfParameter = vestingPosition.nerfParameter;
            power =
                ((vestingPosition.totalVestedAmount -
                    vestingPosition.releasedAmount) *
                    totalFreezingTimeInWeeks *
                    nerfParameter) /
                (10 * MIN_STAKING_AMOUNT); // @dev scaling because of minimum staking amount
        }
        return power;
    }
}
