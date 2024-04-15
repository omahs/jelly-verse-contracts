# Solidity API

## InvestorDistribution

### Investor

```solidity
struct Investor {
  address beneficiary;
  uint96 amount;
}
```

### NUMBER_OF_INVESTORS

```solidity
uint256 NUMBER_OF_INVESTORS
```

### JELLY_AMOUNT

```solidity
uint256 JELLY_AMOUNT
```

### FREEZING_PERIOD

```solidity
uint32 FREEZING_PERIOD
```

### VESTING_DURATION

```solidity
uint32 VESTING_DURATION
```

### NERF_PARAMETER

```solidity
uint8 NERF_PARAMETER
```

### i_jellyToken

```solidity
contract IERC20 i_jellyToken
```

### index

```solidity
uint32 index
```

### investors

```solidity
struct InvestorDistribution.Investor[87] investors
```

### i_chest

```solidity
contract IChest i_chest
```

### ChestSet

```solidity
event ChestSet(address chest)
```

### BatchDistributed

```solidity
event BatchDistributed(uint256 startIndex, uint256 batchLength)
```

### InvestorDistribution\_\_InvalidBatchLength

```solidity
error InvestorDistribution__InvalidBatchLength()
```

### InvestorDistribution\_\_DistributionIndexOutOfBounds

```solidity
error InvestorDistribution__DistributionIndexOutOfBounds()
```

### InvestorDistribution\_\_ChestAlreadySet

```solidity
error InvestorDistribution__ChestAlreadySet()
```

### constructor

```solidity
constructor(address jellyToken, address owner, address pendingOwner) public
```

### distribute

```solidity
function distribute(uint32 batchLength) external
```

Distributes tokens to team members in batches.

_Only the contract owner can call this function.
The `batchLength` must be greater than 0 and within the bounds of the team list._

#### Parameters

| Name        | Type   | Description                                         |
| ----------- | ------ | --------------------------------------------------- |
| batchLength | uint32 | The number of team members to distribute tokens to. |

### setChest

```solidity
function setChest(address chest) external
```

Sets the chest contract address.

_Only the contract owner can call this function.
The chest contract address must not be already set._

#### Parameters

| Name  | Type    | Description                        |
| ----- | ------- | ---------------------------------- |
| chest | address | The address of the chest contract. |

## IChest

\_Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.

\_Available since v4.5.\_\_

### DelegateChanged

```solidity
event DelegateChanged(address delegator, address fromDelegate, address toDelegate)
```

_Emitted when an account changes their delegate._

### DelegateVotesChanged

```solidity
event DelegateVotesChanged(address delegate, uint256 previousBalance, uint256 newBalance)
```

_Emitted when a token transfer or delegate change results in changes to a delegate's number of votes._

### getVotingPower

```solidity
function getVotingPower(address account, uint256[] tokenIds) external view returns (uint256)
```

_Returns the current amount of votes that `account` has._

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

_Returns the amount of votes that `account` had at a specific moment in the past. If the `clock()` is
configured to use block numbers, this will return the value at the end of the corresponding block._

### getPastTotalSupply

```solidity
function getPastTotalSupply(uint256 timepoint) external view returns (uint256)
```

\_Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
configured to use block numbers, this will return the value at the end of the corresponding block.

NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
Votes that have not been delegated are still part of total supply, even though they would not participate in a
vote.\_

### delegates

```solidity
function delegates(address account) external view returns (address)
```

_Returns the delegate that `account` has chosen._

### delegate

```solidity
function delegate(address delegatee) external
```

_Delegates votes from the sender to `delegatee`._

### delegateBySig

```solidity
function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external
```

_Delegates votes from signer to `delegatee`._

### stakeSpecial

```solidity
function stakeSpecial(uint256 amount, address beneficiary, uint32 freezingPeriod, uint32 vestingDuration, uint8 nerfParameter) external
```

_Mints special chest._

### fee

```solidity
function fee() external view returns (uint256)
```

## Ownable

An abstract contract for ownership managment

### OwnershipTransferRequested

```solidity
event OwnershipTransferRequested(address from, address to)
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address from, address to)
```

### OwnershipTransferCanceled

```solidity
event OwnershipTransferCanceled(address from, address to)
```

### Ownable\_\_CannotSetOwnerToZeroAddress

```solidity
error Ownable__CannotSetOwnerToZeroAddress()
```

### Ownable\_\_MustBeProposedOwner

```solidity
error Ownable__MustBeProposedOwner()
```

### Ownable\_\_CallerIsNotOwner

```solidity
error Ownable__CallerIsNotOwner()
```

### Ownable\_\_CannotTransferToSelf

```solidity
error Ownable__CannotTransferToSelf()
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### constructor

```solidity
constructor(address newOwner, address pendingOwner) internal
```

### transferOwnership

```solidity
function transferOwnership(address newOwner) external
```

Requests ownership transfer to the new address which needs to accept it.

_Only owner can call._

#### Parameters

| Name     | Type    | Description                                                  |
| -------- | ------- | ------------------------------------------------------------ |
| newOwner | address | - address of proposed new owner No return, reverts on error. |

### acceptOwnership

```solidity
function acceptOwnership() external
```

Accepts pending ownership transfer request.

\_Only proposed new owner can call.

No return, revets on error.\_

### cancelOwnershipTransfer

```solidity
function cancelOwnershipTransfer() external
```

Cancels ownership request transfer.

\_Only owner can call.

No return, reverts on error.\_

### owner

```solidity
function owner() public view returns (address)
```

Gets current owner address.

#### Return Values

| Name | Type    | Description |
| ---- | ------- | ----------- |
| [0]  | address | owner       |

### getPendingOwner

```solidity
function getPendingOwner() public view returns (address)
```

Gets pending owner address.

#### Return Values

| Name | Type    | Description  |
| ---- | ------- | ------------ |
| [0]  | address | pendingOwner |

## IERC20

_Interface of the ERC20 standard as defined in the EIP._

### Transfer

```solidity
event Transfer(address from, address to, uint256 value)
```

\_Emitted when `value` tokens are moved from one account (`from`) to
another (`to`).

Note that `value` may be zero.\_

### Approval

```solidity
event Approval(address owner, address spender, uint256 value)
```

_Emitted when the allowance of a `spender` for an `owner` is set by
a call to {approve}. `value` is the new allowance._

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

_Returns the amount of tokens in existence._

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

_Returns the amount of tokens owned by `account`._

### transfer

```solidity
function transfer(address to, uint256 amount) external returns (bool)
```

\_Moves `amount` tokens from the caller's account to `to`.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event.\_

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

\_Returns the remaining number of tokens that `spender` will be
allowed to spend on behalf of `owner` through {transferFrom}. This is
zero by default.

This value changes when {approve} or {transferFrom} are called.\_

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

\_Sets `amount` as the allowance of `spender` over the caller's tokens.

Returns a boolean value indicating whether the operation succeeded.

IMPORTANT: Beware that changing an allowance with this method brings the risk
that someone may use both the old and the new allowance by unfortunate
transaction ordering. One possible solution to mitigate this race
condition is to first reduce the spender's allowance to 0 and set the
desired value afterwards:
https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

Emits an {Approval} event.\_

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external returns (bool)
```

\_Moves `amount` tokens from `from` to `to` using the
allowance mechanism. `amount` is then deducted from the caller's
allowance.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event.\_

## Chest

### MAX_FREEZING_PERIOD_REGULAR_CHEST

```solidity
uint32 MAX_FREEZING_PERIOD_REGULAR_CHEST
```

### MAX_FREEZING_PERIOD_SPECIAL_CHEST

```solidity
uint32 MAX_FREEZING_PERIOD_SPECIAL_CHEST
```

### MIN_FREEZING_PERIOD

```solidity
uint32 MIN_FREEZING_PERIOD
```

### MIN_VESTING_DURATION

```solidity
uint32 MIN_VESTING_DURATION
```

### MAX_VESTING_DURATION

```solidity
uint32 MAX_VESTING_DURATION
```

### MAX_NERF_PARAMETER

```solidity
uint8 MAX_NERF_PARAMETER
```

### NERF_NORMALIZATION_FACTOR

```solidity
uint8 NERF_NORMALIZATION_FACTOR
```

### TIME_FACTOR

```solidity
uint32 TIME_FACTOR
```

### MIN_STAKING_AMOUNT

```solidity
uint256 MIN_STAKING_AMOUNT
```

### MAX_BOOSTER

```solidity
uint120 MAX_BOOSTER
```

### BASE_SVG

```solidity
string BASE_SVG
```

### MIDDLE_PART_SVG

```solidity
string MIDDLE_PART_SVG
```

### VESTING_PERIOD_SVG

```solidity
string VESTING_PERIOD_SVG
```

### END_SVG

```solidity
string END_SVG
```

### i_jellyToken

```solidity
contract IERC20 i_jellyToken
```

### fee

```solidity
uint128 fee
```

### totalFees

```solidity
uint128 totalFees
```

### Staked

```solidity
event Staked(address user, uint256 tokenId, uint256 amount, uint256 freezedUntil, uint32 vestingDuration, uint120 booster, uint8 nerfParameter)
```

### IncreaseStake

```solidity
event IncreaseStake(uint256 tokenId, uint256 totalStaked, uint256 freezedUntil, uint120 booster)
```

### Unstake

```solidity
event Unstake(uint256 tokenId, uint256 amount, uint256 totalStaked, uint120 booster)
```

### SetFee

```solidity
event SetFee(uint128 fee)
```

### FeeWithdrawn

```solidity
event FeeWithdrawn(address beneficiary)
```

### Chest\_\_ZeroAddress

```solidity
error Chest__ZeroAddress()
```

### Chest\_\_InvalidStakingAmount

```solidity
error Chest__InvalidStakingAmount()
```

### Chest\_\_NonExistentToken

```solidity
error Chest__NonExistentToken()
```

### Chest\_\_NothingToIncrease

```solidity
error Chest__NothingToIncrease()
```

### Chest\_\_InvalidFreezingPeriod

```solidity
error Chest__InvalidFreezingPeriod()
```

### Chest\_\_InvalidVestingDuration

```solidity
error Chest__InvalidVestingDuration()
```

### Chest\_\_InvalidNerfParameter

```solidity
error Chest__InvalidNerfParameter()
```

### Chest\_\_CannotModifySpecial

```solidity
error Chest__CannotModifySpecial()
```

### Chest\_\_NonTransferrableToken

```solidity
error Chest__NonTransferrableToken()
```

### Chest\_\_NotAuthorizedForToken

```solidity
error Chest__NotAuthorizedForToken()
```

### Chest\_\_FreezingPeriodNotOver

```solidity
error Chest__FreezingPeriodNotOver()
```

### Chest\_\_CannotUnstakeMoreThanReleasable

```solidity
error Chest__CannotUnstakeMoreThanReleasable()
```

### Chest\_\_NothingToUnstake

```solidity
error Chest__NothingToUnstake()
```

### Chest\_\_InvalidBoosterValue

```solidity
error Chest__InvalidBoosterValue()
```

### Chest\_\_NoFeesToWithdraw

```solidity
error Chest__NoFeesToWithdraw()
```

### onlyAuthorizedForToken

```solidity
modifier onlyAuthorizedForToken(uint256 _tokenId)
```

### constructor

```solidity
constructor(address jellyToken, uint128 mintingFee, address owner, address pendingOwner) public
```

### stake

```solidity
function stake(uint256 amount, address beneficiary, uint32 freezingPeriod) external
```

Stakes tokens and freezes them for a period of time in regular chest.

#### Parameters

| Name           | Type    | Description                                                            |
| -------------- | ------- | ---------------------------------------------------------------------- |
| amount         | uint256 | - amount of tokens to freeze.                                          |
| beneficiary    | address | - address of the beneficiary.                                          |
| freezingPeriod | uint32  | - duration of freezing period in seconds. No return, reverts on error. |

### stakeSpecial

```solidity
function stakeSpecial(uint256 amount, address beneficiary, uint32 freezingPeriod, uint32 vestingDuration, uint8 nerfParameter) external
```

Stakes tokens and freezes them for a period of time in special chest.

_Anyone can call this function, it's meant to be used by
partners and investors because of vestingPeriod._

#### Parameters

| Name            | Type    | Description                                                           |
| --------------- | ------- | --------------------------------------------------------------------- |
| amount          | uint256 | - amount of tokens to freeze.                                         |
| beneficiary     | address | - address of the beneficiary.                                         |
| freezingPeriod  | uint32  | - duration of freezing period in seconds.                             |
| vestingDuration | uint32  | - duration of vesting period in seconds. No return, reverts on error. |
| nerfParameter   | uint8   |                                                                       |

### increaseStake

```solidity
function increaseStake(uint256 tokenId, uint256 amount, uint32 extendFreezingPeriod) external
```

Increases stake.

#### Parameters

| Name                 | Type    | Description                                                                      |
| -------------------- | ------- | -------------------------------------------------------------------------------- |
| tokenId              | uint256 | - id of the chest.                                                               |
| amount               | uint256 | - amount of tokens to stake.                                                     |
| extendFreezingPeriod | uint32  | - duration of freezing period extension in seconds. No return, reverts on error. |

### unstake

```solidity
function unstake(uint256 tokenId, uint256 amount) external
```

Unstakes tokens.

#### Parameters

| Name    | Type    | Description                                                 |
| ------- | ------- | ----------------------------------------------------------- |
| tokenId | uint256 | - id of the chest.                                          |
| amount  | uint256 | - amount of tokens to unstake. No return, reverts on error. |

### setFee

```solidity
function setFee(uint128 fee_) external
```

Sets fee in Jelly token for minting a chest.

_Only owner can call._

#### Parameters

| Name  | Type    | Description                             |
| ----- | ------- | --------------------------------------- |
| fee\_ | uint128 | - new fee. No return, reverts on error. |

### withdrawFees

```solidity
function withdrawFees(address beneficiary) external
```

Withdraws accumulated fees to the specified beneficiary.

_Only the contract owner can call this function._

#### Parameters

| Name        | Type    | Description                                                           |
| ----------- | ------- | --------------------------------------------------------------------- |
| beneficiary | address | - address to receive the withdrawn fees. No return, reverts on error. |

### getVotingPower

```solidity
function getVotingPower(address account, uint256[] tokenIds) external view returns (uint256)
```

Calculates the voting power of all account's chests.

#### Parameters

| Name     | Type      | Description              |
| -------- | --------- | ------------------------ |
| account  | address   | - address of the account |
| tokenIds | uint256[] | - ids of the chests.     |

#### Return Values

| Name | Type    | Description                    |
| ---- | ------- | ------------------------------ |
| [0]  | uint256 | - voting power of the account. |

### estimateChestPower

```solidity
function estimateChestPower(uint256 timestamp, struct Vesting.VestingPosition vestingPosition) external pure returns (uint256)
```

Calculates the voting power of the chest for specific timestamp and position values.

#### Parameters

| Name            | Type                           | Description                                    |
| --------------- | ------------------------------ | ---------------------------------------------- |
| timestamp       | uint256                        | - timestamp for which the power is calculated. |
| vestingPosition | struct Vesting.VestingPosition | - vesting position of the chest.               |

#### Return Values

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| [0]  | uint256 | - voting power of the chest. |

### getVestingPosition

```solidity
function getVestingPosition(uint256 tokenId) public view returns (struct Vesting.VestingPosition)
```

_Retrieves the vesting position at the specified index._

#### Parameters

| Name    | Type    | Description                                    |
| ------- | ------- | ---------------------------------------------- |
| tokenId | uint256 | The index of the vesting position to retrieve. |

#### Return Values

| Name | Type                           | Description                                    |
| ---- | ------------------------------ | ---------------------------------------------- |
| [0]  | struct Vesting.VestingPosition | - The vesting position at the specified index. |

### getChestPower

```solidity
function getChestPower(uint256 tokenId) public view returns (uint256)
```

Calculates the voting power of the chest for current block.timestamp.

#### Parameters

| Name    | Type    | Description        |
| ------- | ------- | ------------------ |
| tokenId | uint256 | - id of the chest. |

#### Return Values

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| [0]  | uint256 | - voting power of the chest. |

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view virtual returns (string)
```

The URI is calculated based on the position values of the chest when called.

_Returns the Uniform Resource Identifier (URI) for `tokenId` token._

### totalSupply

```solidity
function totalSupply() public view returns (uint256)
```

Gets the total supply of tokens.

#### Return Values

| Name | Type    | Description                   |
| ---- | ------- | ----------------------------- |
| [0]  | uint256 | - The total supply of tokens. |

### \_beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual
```

This hook disallows token transfers.

_Hook that is called before token transfer.
See {ERC721 - \_beforeTokenTransfer}._

### \_calculateBooster

```solidity
function _calculateBooster(struct Vesting.VestingPosition vestingPosition, uint48 timestamp) internal pure returns (uint120)
```

Calculates the booster of the chest.

#### Parameters

| Name            | Type                           | Description               |
| --------------- | ------------------------------ | ------------------------- |
| vestingPosition | struct Vesting.VestingPosition | - chest vesting position. |
| timestamp       | uint48                         |                           |

#### Return Values

| Name | Type    | Description             |
| ---- | ------- | ----------------------- |
| [0]  | uint120 | - booster of the chest. |

### \_calculatePower

```solidity
function _calculatePower(uint256 timestamp, struct Vesting.VestingPosition vestingPosition) internal pure returns (uint256)
```

Calculates the voting power of the chest based on the timestamp and vesting position.

#### Parameters

| Name            | Type                           | Description                      |
| --------------- | ------------------------------ | -------------------------------- |
| timestamp       | uint256                        | - current timestamp.             |
| vestingPosition | struct Vesting.VestingPosition | - vesting position of the chest. |

#### Return Values

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| [0]  | uint256 | - voting power of the chest. |

## DailySnapshot

Store & retrieve daily snapshots blocknumbers per epoch

### started

```solidity
bool started
```

### epochDaysIndex

```solidity
uint8 epochDaysIndex
```

### epoch

```solidity
uint40 epoch
```

### beginningOfTheNewDayTimestamp

```solidity
uint40 beginningOfTheNewDayTimestamp
```

### beginningOfTheNewDayBlocknumber

```solidity
uint48 beginningOfTheNewDayBlocknumber
```

### oneDayBlocks

```solidity
uint48 oneDayBlocks
```

### ONE_DAY_SECONDS

```solidity
uint40 ONE_DAY_SECONDS
```

### dailySnapshotsPerEpoch

```solidity
mapping(uint48 => uint48[7]) dailySnapshotsPerEpoch
```

### SnapshottingStarted

```solidity
event SnapshottingStarted(address sender)
```

### DailySnapshotAdded

```solidity
event DailySnapshotAdded(address sender, uint48 epoch, uint48 randomDayBlocknumber, uint8 epochDaysIndex)
```

### BlockTimeChanged

```solidity
event BlockTimeChanged(uint48 newBlockTime)
```

### DailySnapshot_AlreadyStarted

```solidity
error DailySnapshot_AlreadyStarted()
```

### DailySnapshot_NotStarted

```solidity
error DailySnapshot_NotStarted()
```

### DailySnapshot_TooEarly

```solidity
error DailySnapshot_TooEarly()
```

### DailySnapshot_ZeroBlockTime

```solidity
error DailySnapshot_ZeroBlockTime()
```

### onlyStarted

```solidity
modifier onlyStarted()
```

### constructor

```solidity
constructor(address newOwner_, address pendingOwner_) public
```

### startSnapshotting

```solidity
function startSnapshotting() external
```

Signals the contract to start

No return only Owner can call

### dailySnapshot

```solidity
function dailySnapshot() external
```

Store random daily snapshot block number

_Only callable when snapshoting has already started_

### setBlockTime

```solidity
function setBlockTime(uint48 _oneDayBlocks) external
```

Changes the block time

No return only Owner can call

## Governor

\_Core of the governance system, designed to be extended though various modules.

This contract is abstract and requires several functions to be implemented in various modules:

- A counting module must implement {quorum}, {\_quorumReached}, {\_voteSucceeded} and {\_countVote}
- A voting module must implement {\_getVotes}
- Additionally, {votingPeriod} must also be implemented

\_Available since v4.3.\_\_

### BALLOT_TYPEHASH

```solidity
bytes32 BALLOT_TYPEHASH
```

### EXTENDED_BALLOT_TYPEHASH

```solidity
bytes32 EXTENDED_BALLOT_TYPEHASH
```

### ProposalCore

```solidity
struct ProposalCore {
  uint64 voteStart;
  address proposer;
  bytes4 __gap_unused0;
  uint64 voteEnd;
  bytes24 __gap_unused1;
  bool executed;
  bool canceled;
  uint256 finalChestId;
}
```

### onlyGovernance

```solidity
modifier onlyGovernance()
```

\_Restricts a function so it can only be executed through governance proposals. For example, governance
parameter setters in {GovernorSettings} are protected using this modifier.

The governance executing address may be different from the Governor's own address, for example it could be a
timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
for example, additional timelock proposers are not able to change governance parameters without going through the
governance protocol (since v4.6)._

### constructor

```solidity
constructor(string name_, address chest_, uint48 minVotingDelay_, uint48 minVotingPeriod_) internal
```

_Sets the value for {name} and {version}_

### receive

```solidity
receive() external payable virtual
```

_Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)_

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### name

```solidity
function name() public view virtual returns (string)
```

_See {IGovernor-name}._

### version

```solidity
function version() public view virtual returns (string)
```

_See {IGovernor-version}._

### hashProposal

```solidity
function hashProposal(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public pure virtual returns (uint256)
```

\_See {IGovernor-hashProposal}.

The proposal id is produced by hashing the ABI encoded `targets` array, the `values` array, the `calldatas` array
and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
advance, before the proposal is submitted.

Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
same proposal (with same operation and same description) will have the same id if submitted on multiple governors
across multiple networks. This also means that in order to execute the same operation twice (on the same
governor) the proposer will have to change the description in order to avoid proposal id conflicts.\_

### state

```solidity
function state(uint256 proposalId) public view virtual returns (enum IGovernor.ProposalState)
```

_See {IGovernor-state}._

### proposalThreshold

```solidity
function proposalThreshold() public view virtual returns (uint256)
```

_Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_._

### proposalSnapshot

```solidity
function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256)
```

_See {IGovernor-proposalSnapshot}._

### proposalDeadline

```solidity
function proposalDeadline(uint256 proposalId) public view virtual returns (uint256)
```

_See {IGovernor-proposalDeadline}._

### proposalFinalChest

```solidity
function proposalFinalChest(uint256 proposalId) public view returns (uint256)
```

_Returns final chest of passed proposal._

### proposalProposer

```solidity
function proposalProposer(uint256 proposalId) public view virtual returns (address)
```

_Returns the account that created a given proposal._

### \_quorumReached

```solidity
function _quorumReached(uint256 proposalId) internal view virtual returns (bool)
```

_Amount of votes already cast passes the threshold limit._

### \_voteSucceeded

```solidity
function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool)
```

_Is the proposal successful or not._

### \_getVotes

```solidity
function _getVotes(address account, uint256 timepoint, bytes params) internal view virtual returns (uint256)
```

_Get the voting weight of `account` at a specific `timepoint`, for a vote as described by `params`._

### \_countVote

```solidity
function _countVote(uint256 proposalId, address account, uint8 support, uint256 weight, bytes params) internal virtual
```

\_Register a vote for `proposalId` by `account` with a given `support`, voting `weight` and voting `params`.

Note: Support is generic and can represent various things depending on the voting system used.\_

### \_defaultParams

```solidity
function _defaultParams() internal view virtual returns (bytes)
```

\_Default additional encoded parameters used by castVote methods that don't include them

Note: Should be overridden by specific implementations to use an appropriate value, the
meaning of the additional params, in the context of that implementation\_

### proposeCustom

```solidity
function proposeCustom(address[] targets, uint256[] values, bytes[] calldatas, string description, uint256 votingDelay, uint256 votingPeriod) public virtual returns (uint256)
```

_See {IGovernor-propose}. This function has opt-in frontrunning protection, described in {\_isValidDescriptionForProposer}._

### propose

```solidity
function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) public virtual returns (uint256)
```

_See {IGovernor-propose}. This function has opt-in frontrunning protection, described in {\_isValidDescriptionForProposer}._

### execute

```solidity
function execute(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public payable virtual returns (uint256)
```

_See {IGovernor-execute}._

### cancel

```solidity
function cancel(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public virtual returns (uint256)
```

_See {IGovernor-cancel}._

### \_execute

```solidity
function _execute(uint256, address[] targets, uint256[] values, bytes[] calldatas, bytes32) internal virtual
```

_Internal execution mechanism. Can be overridden to implement different execution mechanism_

### \_beforeExecute

```solidity
function _beforeExecute(uint256, address[] targets, uint256[], bytes[] calldatas, bytes32) internal virtual
```

_Hook before execution is triggered._

### \_afterExecute

```solidity
function _afterExecute(uint256, address[], uint256[], bytes[], bytes32) internal virtual
```

_Hook after execution is triggered._

### \_cancel

```solidity
function _cancel(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) internal virtual returns (uint256)
```

\_Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
canceled to allow distinguishing it from executed proposals.

Emits a {IGovernor-ProposalCanceled} event.\_

### getVotes

```solidity
function getVotes(address account, uint256 timepoint) public view virtual returns (uint256)
```

_See {IGovernor-getVotes}._

### getVotesWithParams

```solidity
function getVotesWithParams(address account, uint256 timepoint, bytes params) public view virtual returns (uint256)
```

_See {IGovernor-getVotesWithParams}._

### castVote

```solidity
function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256)
```

_See {IGovernor-castVote}._

### castVoteWithReason

```solidity
function castVoteWithReason(uint256 proposalId, uint8 support, string reason) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReason}._

### castVoteWithReasonAndParams

```solidity
function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string reason, bytes params) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReasonAndParams}._

### castVoteBySig

```solidity
function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256)
```

_See {IGovernor-castVoteBySig}._

### castVoteWithReasonAndParamsBySig

```solidity
function castVoteWithReasonAndParamsBySig(uint256 proposalId, uint8 support, string reason, bytes params, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256)
```

_See {IGovernor-castVoteWithReasonAndParamsBySig}._

### \_castVote

```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string reason) internal virtual returns (uint256)
```

\_Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {\_countVote} internal function. Uses the \_defaultParams().

Emits a {IGovernor-VoteCast} event.\_

### \_castVote

```solidity
function _castVote(uint256 proposalId, address account, uint8 support, string reason, bytes params) internal virtual returns (uint256)
```

\_Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
voting weight using {IGovernor-getVotes} and call the {\_countVote} internal function.

Emits a {IGovernor-VoteCast} event.\_

### relay

```solidity
function relay(address target, uint256 value, bytes data) external payable virtual
```

_Relays a transaction or function call to an arbitrary target. In cases where the governance executor
is some contract other than the governor itself, like when using a timelock, this function can be invoked
in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
Note that if the executor is simply the governor itself, use of `relay` is redundant._

### \_executor

```solidity
function _executor() internal view virtual returns (address)
```

_Address through which the governor executes action. Will be overloaded by module that execute actions
through another contract such as a timelock._

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC721Receiver-onERC721Received}._

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155Received}._

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155BatchReceived}._

### \_isValidDescriptionForProposer

```solidity
function _isValidDescriptionForProposer(address proposer, string description) internal view virtual returns (bool)
```

\_Check if the proposer is authorized to submit a proposal with the given description.

If the proposal description ends with `#proposer=0x???`, where `0x???` is an address written as a hex string
(case insensitive), then the submission of this proposal will only be authorized to said address.

This is used for frontrunning protection. By adding this pattern at the end of their proposal, one can ensure
that no other address can submit the same proposal. An attacker would have to either remove or change that part,
which would result in a different proposal id.

If the description does not match this pattern, it is unrestricted and anyone can submit it. This includes:

- If the `0x???` part is not a valid hex string.
- If the `0x???` part is a valid hex string, but does not contain exactly 40 hex digits.
- If it ends with the expected suffix followed by newlines or other whitespace.
- If it ends with some other similar suffix, e.g. `#other=abc`.
- If it does not end with any such suffix.\_

## GovernorVotes

\_Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.

\_Available since v4.3.\_\_

### chest

```solidity
contract IChest chest
```

### constructor

```solidity
constructor(address chestAddress) internal
```

### clock

```solidity
function clock() public view virtual returns (uint48)
```

_Block timestamp as a proxy for the current time._

### CLOCK_MODE

```solidity
function CLOCK_MODE() public view virtual returns (string)
```

_Machine-readable description of the clock as specified in EIP-6372._

### \_getVotes

```solidity
function _getVotes(address account, uint256 timepoint, bytes params) internal view virtual returns (uint256)
```

Read the voting weight from the token's built in snapshot mechanism (see {Governor-\_getVotes}).

_timepoint parameter is not actually timpoint of the vote, but it's
the last chest ID that is viable for voting.
It's left for compatibility with the Governor Votes mechanism._

## JellyGovernor

### JellyGovernor\_\_InvalidOperation

```solidity
error JellyGovernor__InvalidOperation()
```

### constructor

```solidity
constructor(address _chest, contract TimelockController _timelock) public
```

### quorum

```solidity
function quorum(uint256) public pure returns (uint256)
```

### castVote

```solidity
function castVote(uint256, uint8) public virtual returns (uint256)
```

_JellyGovernor overrides but does not support below functions due to non-standard parameter requirements.
Removing these methods would necessitate altering the Governor interface, affecting many dependent contracts.
To preserve interface compatibility while indicating non-support, these functions are explicitly reverted._

### castVoteWithReason

```solidity
function castVoteWithReason(uint256, uint8, string) public virtual returns (uint256)
```

### castVoteBySig

```solidity
function castVoteBySig(uint256, uint8, uint8, bytes32, bytes32) public virtual returns (uint256)
```

### getVotes

```solidity
function getVotes(address, uint256) public view virtual returns (uint256)
```

### votingDelay

```solidity
function votingDelay() public view returns (uint256)
```

### votingPeriod

```solidity
function votingPeriod() public view returns (uint256)
```

### state

```solidity
function state(uint256 proposalId) public view returns (enum IGovernor.ProposalState)
```

### getExecutor

```solidity
function getExecutor() public view returns (address)
```

### proposalThreshold

```solidity
function proposalThreshold() public view returns (uint256)
```

### \_cancel

```solidity
function _cancel(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) internal returns (uint256)
```

### \_executor

```solidity
function _executor() internal view returns (address)
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

### \_execute

```solidity
function _execute(uint256 proposalId, address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) internal
```

## JellyTimelock

A Timelock contract for executing Governance proposals

### constructor

```solidity
constructor(uint256 minDelay, address[] proposers, address[] executors, address admin) public
```

## JellyToken

### MINTER_ROLE

```solidity
bytes32 MINTER_ROLE
```

### Preminted

```solidity
event Preminted(address vestingTeam, address vestingInvestor, address allocator)
```

### JellyToken\_\_AlreadyPreminted

```solidity
error JellyToken__AlreadyPreminted()
```

### JellyToken\_\_ZeroAddress

```solidity
error JellyToken__ZeroAddress()
```

### JellyToken\_\_CapExceeded

```solidity
error JellyToken__CapExceeded()
```

### onlyOnce

```solidity
modifier onlyOnce()
```

### constructor

```solidity
constructor(address _defaultAdminRole) public
```

### premint

```solidity
function premint(address _vestingTeam, address _vestingInvestor, address _allocator, address _minterContract) external
```

Premints tokens to specified addresses.

_Only addresses with MINTER_ROLE can call._

#### Parameters

| Name              | Type    | Description                                                    |
| ----------------- | ------- | -------------------------------------------------------------- |
| \_vestingTeam     | address | - address to mint tokens for the vesting team.                 |
| \_vestingInvestor | address | - address to mint tokens for the vesting investor.             |
| \_allocator       | address | - address to mint tokens for the allocator.                    |
| \_minterContract  | address | - address of the minter contract. No return, reverts on error. |

### mint

```solidity
function mint(address to, uint256 amount) external
```

Mints specified amount of tokens to address.

_Only addresses with MINTER_ROLE can call._

#### Parameters

| Name   | Type    | Description                                              |
| ------ | ------- | -------------------------------------------------------- |
| to     | address | - address to mint tokens for.                            |
| amount | uint256 | - amount of tokens to mint. No return, reverts on error. |

### burn

```solidity
function burn(uint256 value) external
```

_Destroys a `value` amount of tokens from the caller._

#### Parameters

| Name  | Type    | Description                                                                      |
| ----- | ------- | -------------------------------------------------------------------------------- |
| value | uint256 | - the amount of tokens to burn. No return, reverts on error. See {ERC20-\_burn}. |

### burnedSupply

```solidity
function burnedSupply() external view returns (uint256)
```

_Returns the amount of burned tokens._

### cap

```solidity
function cap() external view virtual returns (uint256)
```

_Returns the cap on the token's total supply._

### \_mint

```solidity
function _mint(address account, uint256 amount) internal virtual
```

_See {ERC20-\_mint}._

## JellyTokenDeployer

A contract for deploying JellyToken smart contract using CREATE2 opcode

### Deployed

```solidity
event Deployed(address contractAddress, bytes32 salt)
```

### getBytecode

```solidity
function getBytecode(address _defaultAdminRole) public pure returns (bytes)
```

Returns the bytecode for deploying JellyToken smart contract

#### Parameters

| Name               | Type    | Description                                                     |
| ------------------ | ------- | --------------------------------------------------------------- |
| \_defaultAdminRole | address | - The address of the Jelly Governance (Timelock) smart contract |

#### Return Values

| Name | Type  | Description                                                  |
| ---- | ----- | ------------------------------------------------------------ |
| [0]  | bytes | bytes - The bytecode for deploying JellyToken smart contract |

### computeAddress

```solidity
function computeAddress(bytes32 _salt, address _defaultAdminRole) public view returns (address)
```

Computes the address of the JellyToken smart contract

#### Parameters

| Name               | Type    | Description                                                     |
| ------------------ | ------- | --------------------------------------------------------------- |
| \_salt             | bytes32 |                                                                 |
| \_defaultAdminRole | address | - The address of the Jelly Governance (Timelock) smart contract |

#### Return Values

| Name | Type    | Description                                            |
| ---- | ------- | ------------------------------------------------------ |
| [0]  | address | address - The address of the JellyToken smart contract |

### deployJellyToken

```solidity
function deployJellyToken(bytes32 _salt, address _defaultAdminRole) public payable returns (address JellyTokenAddress)
```

## LiquidityRewardDistribution

Contract for distributing liqidty mining rewards

### token

```solidity
contract IJellyToken token
```

### merkleRoots

```solidity
mapping(uint256 => bytes32) merkleRoots
```

### claimed

```solidity
mapping(uint256 => mapping(address => bool)) claimed
```

### vestingContract

```solidity
address vestingContract
```

### epoch

```solidity
uint96 epoch
```

### Claimed

```solidity
event Claimed(address claimant, uint96 epoch, uint256 balance)
```

### EpochAdded

```solidity
event EpochAdded(uint96 epoch, bytes32 merkleRoot, string ipfs)
```

### ContractChanged

```solidity
event ContractChanged(address vestingContract)
```

### Claim_LenMissmatch

```solidity
error Claim_LenMissmatch()
```

### Claim_ZeroAmount

```solidity
error Claim_ZeroAmount()
```

### Claim_FutureEpoch

```solidity
error Claim_FutureEpoch()
```

### Claim_AlreadyClaimed

```solidity
error Claim_AlreadyClaimed()
```

### Claim_WrongProof

```solidity
error Claim_WrongProof()
```

### constructor

```solidity
constructor(contract IJellyToken _token, address _owner, address _pendingOwner) public
```

### createEpoch

```solidity
function createEpoch(bytes32 _merkleRoot, string _ipfs) public returns (uint96 epochId)
```

Creates epoch for distribtuin

#### Parameters

| Name         | Type    | Description                                          |
| ------------ | ------- | ---------------------------------------------------- |
| \_merkleRoot | bytes32 | - root of merkle tree. No return only Owner can call |
| \_ipfs       | string  |                                                      |

### claimWeek

```solidity
function claimWeek(uint96 _epochId, uint256 _amount, bytes32[] _merkleProof, bool _isVesting) public
```

Claims a single week

#### Parameters

| Name          | Type      | Description                                        |
| ------------- | --------- | -------------------------------------------------- |
| \_epochId     | uint96    | - id of epoch to be claimed                        |
| \_amount      | uint256   | - amount of tokens to be claimed                   |
| \_merkleProof | bytes32[] | - merkle proof of claim No return reverts an error |
| \_isVesting   | bool      |                                                    |

### claimWeeks

```solidity
function claimWeeks(uint96[] _epochIds, uint256[] _amounts, bytes32[][] _merkleProofs, bool _isVesting) public
```

Claims multiple weeks

#### Parameters

| Name           | Type        | Description                                         |
| -------------- | ----------- | --------------------------------------------------- |
| \_epochIds     | uint96[]    | - id sof epochs to be claimed                       |
| \_amounts      | uint256[]   | - amounts of tokens to be claimed                   |
| \_merkleProofs | bytes32[][] | - merkle proofs of claim No return reverts an error |
| \_isVesting    | bool        |                                                     |

### verifyClaim

```solidity
function verifyClaim(address _reciver, uint256 _epochId, uint256 _amount, bytes32[] _merkleProof) public view returns (bool valid)
```

Verifies claim

#### Parameters

| Name          | Type      | Description                                        |
| ------------- | --------- | -------------------------------------------------- |
| \_reciver     | address   | - address of user to claim                         |
| \_epochId     | uint256   | - id of epoch to be claimed                        |
| \_amount      | uint256   | - amount of tokens to be claimed                   |
| \_merkleProof | bytes32[] | - merkle proof of claim No return reverts an error |

### setVestingContract

```solidity
function setVestingContract(address _vestingContract) public
```

Changes the vesting contract

#### Parameters

| Name              | Type    | Description                                                 |
| ----------------- | ------- | ----------------------------------------------------------- |
| \_vestingContract | address | - address of vesting contract No return only Owner can call |

## Minter

mint jelly tokens

### Beneficiary

```solidity
struct Beneficiary {
  address beneficiary;
  uint96 weight;
}
```

### i_jellyToken

```solidity
address i_jellyToken
```

### mintingStartedTimestamp

```solidity
uint32 mintingStartedTimestamp
```

### stakingRewardsContract

```solidity
address stakingRewardsContract
```

### lastMintedTimestamp

```solidity
uint32 lastMintedTimestamp
```

### mintingPeriod

```solidity
uint32 mintingPeriod
```

### started

```solidity
bool started
```

### beneficiaries

```solidity
struct Minter.Beneficiary[] beneficiaries
```

### K

```solidity
int256 K
```

### DECIMALS

```solidity
uint256 DECIMALS
```

### onlyStarted

```solidity
modifier onlyStarted()
```

### onlyNotStarted

```solidity
modifier onlyNotStarted()
```

### MintingStarted

```solidity
event MintingStarted(address sender, uint256 startTimestamp)
```

### MintingPeriodSet

```solidity
event MintingPeriodSet(address sender, uint256 mintingPeriod)
```

### StakingRewardsContractSet

```solidity
event StakingRewardsContractSet(address sender, address stakingRewardsContract)
```

### JellyMinted

```solidity
event JellyMinted(address sender, address stakingRewardsContract, uint256 newLastMintedTimestamp, uint256 mintingPeriod, uint256 mintedAmount, uint256 epochId)
```

### BeneficiariesChanged

```solidity
event BeneficiariesChanged()
```

### Minter_MintingNotStarted

```solidity
error Minter_MintingNotStarted()
```

### Minter_MintingAlreadyStarted

```solidity
error Minter_MintingAlreadyStarted()
```

### Minter_MintTooSoon

```solidity
error Minter_MintTooSoon()
```

### Minter_ZeroAddress

```solidity
error Minter_ZeroAddress()
```

### constructor

```solidity
constructor(address _jellyToken, address _stakingRewardsContract, address _newOwner, address _pendingOwner) public
```

### startMinting

```solidity
function startMinting() external
```

Starts minting process for jelly tokens, and sets last minted timestamp so that minting can start immediately

### mint

```solidity
function mint() external
```

Mint new tokens based on exponential function, callable by anyone

### calculateMintAmount

```solidity
function calculateMintAmount(int256 _daysSinceMintingStarted) public pure returns (uint256)
```

Calculate mint amount based on exponential function

#### Parameters

| Name                      | Type   | Description                            |
| ------------------------- | ------ | -------------------------------------- |
| \_daysSinceMintingStarted | int256 | - number of days since minting started |

#### Return Values

| Name | Type    | Description                           |
| ---- | ------- | ------------------------------------- |
| [0]  | uint256 | mintAmount - amount of tokens to mint |

### setStakingRewardsContract

```solidity
function setStakingRewardsContract(address _newStakingRewardsContract) external
```

Set new Staking Rewards Distribution Contract

_Only owner can call._

#### Parameters

| Name                        | Type    | Description                               |
| --------------------------- | ------- | ----------------------------------------- |
| \_newStakingRewardsContract | address | new staking rewards distribution contract |

### setMintingPeriod

```solidity
function setMintingPeriod(uint32 _mintingPeriod) external
```

Set new minting period

_Only owner can call._

#### Parameters

| Name            | Type   | Description        |
| --------------- | ------ | ------------------ |
| \_mintingPeriod | uint32 | new minitng period |

### setBeneficiaries

```solidity
function setBeneficiaries(struct Minter.Beneficiary[] _beneficiaries) external
```

Store array of beneficiaries to storage

_Only owner can call._

#### Parameters

| Name            | Type                        | Description |
| --------------- | --------------------------- | ----------- |
| \_beneficiaries | struct Minter.Beneficiary[] | to store    |

## OfficialPoolsRegister

Store & sretrieve pools

### Pool

```solidity
struct Pool {
  bytes32 poolId;
  uint32 weight;
}
```

### OfficialPoolRegistered

```solidity
event OfficialPoolRegistered(bytes32 poolId, uint32 weight)
```

### OfficialPoolDeregistered

```solidity
event OfficialPoolDeregistered(bytes32 poolId)
```

### OfficialPoolsRegister_MaxPools50

```solidity
error OfficialPoolsRegister_MaxPools50()
```

### constructor

```solidity
constructor(address newOwner_, address pendingOwner_) public
```

### registerOfficialPool

```solidity
function registerOfficialPool(struct OfficialPoolsRegister.Pool[] pools_) external
```

Store array of poolId in official pools array

_Only owner can call._

#### Parameters

| Name    | Type                                | Description |
| ------- | ----------------------------------- | ----------- |
| pools\_ | struct OfficialPoolsRegister.Pool[] | to store    |

### getAllOfficialPools

```solidity
function getAllOfficialPools() public view returns (bytes32[])
```

/\*\*
Return all official pools ids

#### Return Values

| Name | Type      | Description   |
| ---- | --------- | ------------- |
| [0]  | bytes32[] | all 'poolIds' |

## PoolParty

Contract for swapping native tokens for jelly tokens

### i_jellyToken

```solidity
address i_jellyToken
```

### usdToken

```solidity
address usdToken
```

### jellySwapPoolId

```solidity
bytes32 jellySwapPoolId
```

### jellySwapVault

```solidity
address jellySwapVault
```

### isOver

```solidity
bool isOver
```

### usdToJellyRatio

```solidity
uint88 usdToJellyRatio
```

### BuyWithUsd

```solidity
event BuyWithUsd(uint256 usdAmount, uint256 jellyAmount, address buyer)
```

### EndBuyingPeriod

```solidity
event EndBuyingPeriod()
```

### NativeToJellyRatioSet

```solidity
event NativeToJellyRatioSet(uint256 usdToJellyRatio)
```

### PoolParty\_\_CannotBuy

```solidity
error PoolParty__CannotBuy()
```

### PoolParty\_\_NoValueSent

```solidity
error PoolParty__NoValueSent()
```

### PoolParty\_\_AddressZero

```solidity
error PoolParty__AddressZero()
```

### PoolParty\_\_ZeroValue

```solidity
error PoolParty__ZeroValue()
```

### canBuy

```solidity
modifier canBuy()
```

### constructor

```solidity
constructor(address _jellyToken, address _usdToken, uint88 _usdToJellyRatio, address _jellySwapVault, bytes32 _jellySwapPoolId, address _owner, address _pendingOwner) public
```

### buyWithUsd

```solidity
function buyWithUsd(uint256 _amount) external payable
```

Buys jelly tokens with USD pegged token

#### Parameters

| Name     | Type    | Description                              |
| -------- | ------- | ---------------------------------------- |
| \_amount | uint256 | amount of usd to be sold No return value |

### endBuyingPeriod

```solidity
function endBuyingPeriod() external
```

Ends buying period and burns remaining JellyTokens.

\_Only owner can call.

No return, reverts on error.\_

### setUSDToJellyRatio

```solidity
function setUSDToJellyRatio(uint88 _usdToJellyRatio) external
```

Sets native to jelly ratio.

_Only owner can call._

#### Parameters

| Name              | Type   | Description                                                     |
| ----------------- | ------ | --------------------------------------------------------------- |
| \_usdToJellyRatio | uint88 | - ratio of native to jelly tokens. No return, reverts on error. |

### \_convertERC20sToAssets

```solidity
function _convertERC20sToAssets(contract IERC20[] tokens) internal pure returns (contract IAsset[] assets)
```

## RewardVesting

### VestingPosition

```solidity
struct VestingPosition {
  uint256 vestedAmount;
  uint48 startTime;
}
```

### liquidityVestedPositions

```solidity
mapping(address => struct RewardVesting.VestingPosition) liquidityVestedPositions
```

### stakingVestedPositions

```solidity
mapping(address => struct RewardVesting.VestingPosition) stakingVestedPositions
```

### liquidityContract

```solidity
address liquidityContract
```

### stakingContract

```solidity
address stakingContract
```

### jellyToken

```solidity
contract IJellyToken jellyToken
```

### vestingPeriod

```solidity
uint48 vestingPeriod
```

### Vest\_\_InvalidCaller

```solidity
error Vest__InvalidCaller()
```

### Vest\_\_ZeroAddress

```solidity
error Vest__ZeroAddress()
```

### Vest\_\_InvalidVestingAmount

```solidity
error Vest__InvalidVestingAmount()
```

### Vest\_\_AlreadyVested

```solidity
error Vest__AlreadyVested()
```

### Vest\_\_NothingToClaim

```solidity
error Vest__NothingToClaim()
```

### VestedLiqidty

```solidity
event VestedLiqidty(uint256 amount, address beneficiary)
```

### VestingLiquidityClaimed

```solidity
event VestingLiquidityClaimed(uint256 amount, address beneficiary)
```

### VestedStaking

```solidity
event VestedStaking(uint256 amount, address beneficiary)
```

### VestingStakingClaimed

```solidity
event VestingStakingClaimed(uint256 amount, address beneficiary)
```

### constructor

```solidity
constructor(address _owner, address _pendingOwner, address _liquidityContract, address _stakingContract, address _jellyToken) public
```

### vestLiquidity

```solidity
function vestLiquidity(uint256 _amount, address _beneficiary) public
```

Vest liquidity

#### Parameters

| Name          | Type    | Description                                                       |
| ------------- | ------- | ----------------------------------------------------------------- |
| \_amount      | uint256 | - amount of tokens to deposit                                     |
| \_beneficiary | address | - address of beneficiary No return only Vesting contract can call |

### claimLiquidity

```solidity
function claimLiquidity() public
```

Claim vested liqidty

No return

### vestedLiquidityAmount

```solidity
function vestedLiquidityAmount(address _beneficiary) public view returns (uint256 amount)
```

Calculates vested tokens

#### Parameters

| Name          | Type    | Description                                             |
| ------------- | ------- | ------------------------------------------------------- |
| \_beneficiary | address | - address of beneficiary Return amount of tokens vested |

### vestStaking

```solidity
function vestStaking(uint256 _amount, address _beneficiary) public
```

Vest staking

#### Parameters

| Name          | Type    | Description                                                       |
| ------------- | ------- | ----------------------------------------------------------------- |
| \_amount      | uint256 | - amount of tokens to deposit                                     |
| \_beneficiary | address | - address of beneficiary No return only Vesting contract can call |

### claimStaking

```solidity
function claimStaking() public
```

Claim vested staking

No return

### vestedStakingAmount

```solidity
function vestedStakingAmount(address _beneficiary) public view returns (uint256 amount)
```

Calculates vested tokens

#### Parameters

| Name          | Type    | Description                                             |
| ------------- | ------- | ------------------------------------------------------- |
| \_beneficiary | address | - address of beneficiary Return amount of tokens vested |

## StakingRewardDistribution

Contract for distributing staking rewards

### merkleRoots

```solidity
mapping(uint256 => bytes32) merkleRoots
```

### claimed

```solidity
mapping(uint256 => mapping(contract IERC20 => mapping(address => bool))) claimed
```

### tokensDeposited

```solidity
mapping(uint256 => mapping(contract IERC20 => uint256)) tokensDeposited
```

### jellyToken

```solidity
contract IJellyToken jellyToken
```

### vestingContract

```solidity
address vestingContract
```

### epoch

```solidity
uint96 epoch
```

### Claimed

```solidity
event Claimed(address claimant, uint256 balance, contract IERC20 token, uint96 epoch)
```

### EpochAdded

```solidity
event EpochAdded(uint96 epoch, bytes32 merkleRoot, string ipfs)
```

### Deposited

```solidity
event Deposited(contract IERC20 token, uint256 amount, uint96 epoch)
```

### ContractChanged

```solidity
event ContractChanged(address vestingContract)
```

### Claim_LenMissmatch

```solidity
error Claim_LenMissmatch()
```

### Claim_ZeroAmount

```solidity
error Claim_ZeroAmount()
```

### Claim_FutureEpoch

```solidity
error Claim_FutureEpoch()
```

### Claim_AlreadyClaimed

```solidity
error Claim_AlreadyClaimed()
```

### Claim_WrongProof

```solidity
error Claim_WrongProof()
```

### constructor

```solidity
constructor(contract IJellyToken _jellyToken, address _owner, address _pendingOwner) public
```

### createEpoch

```solidity
function createEpoch(bytes32 _merkleRoot, string _ipfs) public returns (uint96 epochId)
```

Creates epoch for distribtuin

#### Parameters

| Name         | Type    | Description                                          |
| ------------ | ------- | ---------------------------------------------------- |
| \_merkleRoot | bytes32 | - root of merkle tree. No return only Owner can call |
| \_ipfs       | string  |                                                      |

### deposit

```solidity
function deposit(contract IERC20 _token, uint256 _amount) public returns (uint96)
```

Deposit funds into contract

\_not using this function to deposit funds will lock the tokens

No return only Owner can call\_

#### Parameters

| Name     | Type            | Description                   |
| -------- | --------------- | ----------------------------- |
| \_token  | contract IERC20 | - token to deposit            |
| \_amount | uint256         | - amount of tokens to deposit |

### claimWeek

```solidity
function claimWeek(uint96 _epochId, contract IERC20[] _tokens, uint256 _relativeVotingPower, bytes32[] _merkleProof, bool _isVesting) public
```

Claim tokens for epoch

#### Parameters

| Name                  | Type              | Description                                        |
| --------------------- | ----------------- | -------------------------------------------------- |
| \_epochId             | uint96            | - id of epoch to be claimed                        |
| \_tokens              | contract IERC20[] | - tokens to clam                                   |
| \_relativeVotingPower | uint256           | - relative voting power of user                    |
| \_merkleProof         | bytes32[]         | - merkle proof of claim No return reverts an error |
| \_isVesting           | bool              |                                                    |

### claimWeeks

```solidity
function claimWeeks(uint96[] _epochIds, contract IERC20[] _tokens, uint256[] _relativeVotingPowers, bytes32[][] _merkleProofs, bool _isVesting) public
```

Claims multiple epochs

#### Parameters

| Name                   | Type              | Description                                         |
| ---------------------- | ----------------- | --------------------------------------------------- |
| \_epochIds             | uint96[]          | - ids of epochs to be claimed                       |
| \_tokens               | contract IERC20[] | - tokens to clam                                    |
| \_relativeVotingPowers | uint256[]         | - relative voting power per epoch of user           |
| \_merkleProofs         | bytes32[][]       | - merkle proofs of claim No return reverts an error |
| \_isVesting            | bool              |                                                     |

### verifyClaim

```solidity
function verifyClaim(address _reciver, uint256 _epochId, uint256 _relativeVotingPower, bytes32[] _merkleProof) public view returns (bool valid)
```

Verifies a claim

#### Parameters

| Name                  | Type      | Description                                        |
| --------------------- | --------- | -------------------------------------------------- |
| \_reciver             | address   | - address of user to verify                        |
| \_epochId             | uint256   | - id of epoch to be verified                       |
| \_relativeVotingPower | uint256   | - relative voting power of user                    |
| \_merkleProof         | bytes32[] | - merkle proof of claim No return reverts an error |

### setVestingContract

```solidity
function setVestingContract(address _vestingContract) public
```

Changes the vesting contract

#### Parameters

| Name              | Type    | Description                                                 |
| ----------------- | ------- | ----------------------------------------------------------- |
| \_vestingContract | address | - address of vesting contract No return only Owner can call |

## TeamDistribution

### LIST_LEN

```solidity
uint32 LIST_LEN
```

### JELLY_AMOUNT

```solidity
uint256 JELLY_AMOUNT
```

### jellyToken

```solidity
contract IERC20 jellyToken
```

### chestContract

```solidity
address chestContract
```

### index

```solidity
uint32 index
```

### ChestSet

```solidity
event ChestSet(address chest)
```

### BatchDistributed

```solidity
event BatchDistributed(uint256 startIndex, uint256 batchLength)
```

### TeamDistribution\_\_InvalidBatchLength

```solidity
error TeamDistribution__InvalidBatchLength()
```

### TeamDistribution\_\_DistributionIndexOutOfBounds

```solidity
error TeamDistribution__DistributionIndexOutOfBounds()
```

### TeamDistribution\_\_ChestAlreadySet

```solidity
error TeamDistribution__ChestAlreadySet()
```

### Team

```solidity
struct Team {
  uint256 amount;
  address beneficiary;
  uint32 freezingPeriod;
  uint32 vestingDuration;
  uint8 nerfParameter;
}
```

### teamList

```solidity
struct TeamDistribution.Team[15] teamList
```

### constructor

```solidity
constructor(address _jellyTooken, address _owner, address _pendingOwner) public
```

### distribute

```solidity
function distribute(uint32 batchLength) external
```

Distributes tokens to team members in batches.

_Only the contract owner can call this function.
The `batchLength` must be greater than 0 and within the bounds of the team list._

#### Parameters

| Name        | Type   | Description                                         |
| ----------- | ------ | --------------------------------------------------- |
| batchLength | uint32 | The number of team members to distribute tokens to. |

### setChest

```solidity
function setChest(address _chestContract) external
```

Sets the chest contract address.

_Only the contract owner can call this function.
The chest contract address must not be already set._

#### Parameters

| Name            | Type    | Description                        |
| --------------- | ------- | ---------------------------------- |
| \_chestContract | address | The address of the chest contract. |

## GovernorCountingSimple

\_Extension of {Governor} for simple, 3 options, vote counting.

\_Available since v4.3.\_\_

### VoteType

```solidity
enum VoteType {
  Against,
  For,
  Abstain
}
```

### ProposalVote

```solidity
struct ProposalVote {
  uint256 againstVotes;
  uint256 forVotes;
  uint256 abstainVotes;
  mapping(address => bool) hasVoted;
}
```

### COUNTING_MODE

```solidity
function COUNTING_MODE() public pure virtual returns (string)
```

_See {IGovernor-COUNTING_MODE}._

### hasVoted

```solidity
function hasVoted(uint256 proposalId, address account) public view virtual returns (bool)
```

_See {IGovernor-hasVoted}._

### proposalVotes

```solidity
function proposalVotes(uint256 proposalId) public view virtual returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
```

_Accessor to the internal vote counts._

### \_quorumReached

```solidity
function _quorumReached(uint256 proposalId) internal view virtual returns (bool)
```

_See {Governor-\_quorumReached}._

### \_voteSucceeded

```solidity
function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool)
```

_See {Governor-\_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes._

### \_countVote

```solidity
function _countVote(uint256 proposalId, address account, uint8 support, uint256 weight, bytes) internal virtual
```

_See {Governor-\_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo)._

## GovernorSettings

\_Extension of {Governor} for settings updatable through governance.

\_Available since v4.4.\_\_

### VotingDelaySet

```solidity
event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay)
```

### VotingPeriodSet

```solidity
event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod)
```

### ProposalThresholdSet

```solidity
event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold)
```

### constructor

```solidity
constructor(uint256 initialVotingDelay, uint256 initialVotingPeriod, uint256 initialProposalThreshold) internal
```

_Initialize the governance parameters._

### votingDelay

```solidity
function votingDelay() public view virtual returns (uint256)
```

_See {IGovernor-votingDelay}._

### votingPeriod

```solidity
function votingPeriod() public view virtual returns (uint256)
```

_See {IGovernor-votingPeriod}._

### proposalThreshold

```solidity
function proposalThreshold() public view virtual returns (uint256)
```

_See {Governor-proposalThreshold}._

### \_setVotingDelay

```solidity
function _setVotingDelay(uint256 newVotingDelay) internal virtual
```

\_Internal setter for the voting delay.

Emits a {VotingDelaySet} event.\_

### \_setVotingPeriod

```solidity
function _setVotingPeriod(uint256 newVotingPeriod) internal virtual
```

\_Internal setter for the voting period.

Emits a {VotingPeriodSet} event.\_

### \_setProposalThreshold

```solidity
function _setProposalThreshold(uint256 newProposalThreshold) internal virtual
```

\_Internal setter for the proposal threshold.

Emits a {ProposalThresholdSet} event.\_

## GovernorTimelockControl

\_Extension of {Governor} that binds the execution process to an instance of {TimelockController}. This adds a
delay, enforced by the {TimelockController} to all successful proposal (in addition to the voting duration). The
{Governor} needs the proposer (and ideally the executor) roles for the {Governor} to work properly.

Using this model means the proposal will be operated by the {TimelockController} and not by the {Governor}. Thus,
the assets and permissions must be attached to the {TimelockController}. Any asset sent to the {Governor} will be
inaccessible.

WARNING: Setting up the TimelockController to have additional proposers besides the governor is very risky, as it
grants them powers that they must be trusted or known not to use: 1) {onlyGovernance} functions like {relay} are
available to them through the timelock, and 2) approved governance proposals can be blocked by them, effectively
executing a Denial of Service attack. This risk will be mitigated in a future release.

\_Available since v4.3.\_\_

### TimelockChange

```solidity
event TimelockChange(address oldTimelock, address newTimelock)
```

_Emitted when the timelock controller used for proposal execution is modified._

### constructor

```solidity
constructor(contract TimelockController timelockAddress) internal
```

_Set the timelock._

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### state

```solidity
function state(uint256 proposalId) public view virtual returns (enum IGovernor.ProposalState)
```

_Overridden version of the {Governor-state} function with added support for the `Queued` state._

### timelock

```solidity
function timelock() public view virtual returns (address)
```

_Public accessor to check the address of the timelock_

### proposalEta

```solidity
function proposalEta(uint256 proposalId) public view virtual returns (uint256)
```

_Public accessor to check the eta of a queued proposal_

### queue

```solidity
function queue(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public virtual returns (uint256)
```

_Function to queue a proposal to the timelock._

### \_execute

```solidity
function _execute(uint256, address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) internal virtual
```

_Overridden execute function that run the already queued proposal through the timelock._

### \_cancel

```solidity
function _cancel(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) internal virtual returns (uint256)
```

_Overridden version of the {Governor-\_cancel} function to cancel the timelocked proposal if it as already
been queued._

### \_executor

```solidity
function _executor() internal view virtual returns (address)
```

_Address through which the governor executes action. In this case, the timelock._

### updateTimelock

```solidity
function updateTimelock(contract TimelockController newTimelock) external virtual
```

\_Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
must be proposed, scheduled, and executed through governance proposals.

CAUTION: It is not recommended to change the timelock while there are other queued governance proposals.\_

## IJellyToken

### mint

```solidity
function mint(address to, uint256 amount) external
```

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

\_Sets `amount` as the allowance of `spender` over the caller's tokens.

Returns a boolean value indicating whether the operation succeeded.

IMPORTANT: Beware that changing an allowance with this method brings the risk
that someone may use both the old and the new allowance by unfortunate
transaction ordering. One possible solution to mitigate this race
condition is to first reduce the spender's allowance to 0 and set the
desired value afterwards:
https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

Emits an {Approval} event.\_

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

_Returns the amount of tokens owned by `account`._

### burn

```solidity
function burn(uint256 value) external
```

### transfer

```solidity
function transfer(address to, uint256 amount) external returns (bool)
```

\_Moves `amount` tokens from the caller's account to `to`.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event.\_

### decimals

```solidity
function decimals() external view returns (uint8)
```

## IStakingRewardDistribution

\_Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.

\_Available since v4.5.\_\_

### deposit

```solidity
function deposit(contract IERC20 _token, uint256 _amount) external returns (uint256)
```

Deposit funds into contract

\_not using this function to deposit funds will lock the tokens

No return only Owner can call\_

#### Parameters

| Name     | Type            | Description                   |
| -------- | --------------- | ----------------------------- |
| \_token  | contract IERC20 | - token to deposit            |
| \_amount | uint256         | - amount of tokens to deposit |

#### Return Values

| Name | Type    | Description                   |
| ---- | ------- | ----------------------------- |
| [0]  | uint256 | epochId - epoch id of deposit |

## ERC20Token

### constructor

```solidity
constructor(string name, string symbol) public
```

### mint

```solidity
function mint(uint256 amount) public
```

## OwnableMock

### constructor

```solidity
constructor(address newOwner, address pendingOwner) public
```

## VestingTest

### getVestingPosition

```solidity
function getVestingPosition(uint256 vestingIndex) public view returns (struct Vesting.VestingPosition)
```

### getVestingIndex

```solidity
function getVestingIndex() public view returns (uint256)
```

### createNewVestingPosition

```solidity
function createNewVestingPosition(uint256 amount, uint32 cliffDuration, uint32 vestingDuration, uint120 booster, uint8 nerfParameter) public returns (struct Vesting.VestingPosition)
```

### updateReleasedAmount

```solidity
function updateReleasedAmount(uint256 vestingIndex, uint256 amount) public
```

## Vesting

Vesting Contract for token vesting

token amount
^
| ********\_\_********
| /
| /
| /
| /
| /
| <----- cliff ----->
|
|
--------------------.------.-------------------> time
vesting duration

_Total vested amount is stored as an immutable storage variable to prevent manipulations when calculating current releasable amount._

### VestingPosition

```solidity
struct VestingPosition {
  uint256 totalVestedAmount;
  uint256 releasedAmount;
  uint48 cliffTimestamp;
  uint48 boosterTimestamp;
  uint32 vestingDuration;
  uint120 accumulatedBooster;
  uint8 nerfParameter;
}
```

### index

```solidity
uint256 index
```

### vestingPositions

```solidity
mapping(uint256 => struct Vesting.VestingPosition) vestingPositions
```

### NewVestingPosition

```solidity
event NewVestingPosition(struct Vesting.VestingPosition position, uint256 index)
```

### releasableAmount

```solidity
function releasableAmount(uint256 vestingIndex) public view returns (uint256)
```

Calculates the amount that has already vested but hasn't been released yet

#### Return Values

| Name | Type    | Description                                                     |
| ---- | ------- | --------------------------------------------------------------- |
| [0]  | uint256 | uint256 The amount that has vested but hasn't been released yet |

### \_releasableAmount

```solidity
function _releasableAmount(uint256 vestingIndex) internal view returns (uint256 amount)
```

### \_createVestingPosition

```solidity
function _createVestingPosition(uint256 amount, uint32 cliffDuration, uint32 vestingDuration, uint120 booster, uint8 nerfParameter) internal returns (struct Vesting.VestingPosition)
```

## WeightedPoolUserData

### JoinKind

```solidity
enum JoinKind {
  INIT,
  EXACT_TOKENS_IN_FOR_BPT_OUT,
  TOKEN_IN_FOR_EXACT_BPT_OUT,
  ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
}
```

### ExitKind

```solidity
enum ExitKind {
  EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
  EXACT_BPT_IN_FOR_TOKENS_OUT,
  BPT_IN_FOR_EXACT_TOKENS_OUT
}
```

### joinKind

```solidity
function joinKind(bytes self) internal pure returns (enum WeightedPoolUserData.JoinKind)
```

### exitKind

```solidity
function exitKind(bytes self) internal pure returns (enum WeightedPoolUserData.ExitKind)
```

### initialAmountsIn

```solidity
function initialAmountsIn(bytes self) internal pure returns (uint256[] amountsIn)
```

### exactTokensInForBptOut

```solidity
function exactTokensInForBptOut(bytes self) internal pure returns (uint256[] amountsIn, uint256 minBPTAmountOut)
```

### tokenInForExactBptOut

```solidity
function tokenInForExactBptOut(bytes self) internal pure returns (uint256 bptAmountOut, uint256 tokenIndex)
```

### allTokensInForExactBptOut

```solidity
function allTokensInForExactBptOut(bytes self) internal pure returns (uint256 bptAmountOut)
```

### exactBptInForTokenOut

```solidity
function exactBptInForTokenOut(bytes self) internal pure returns (uint256 bptAmountIn, uint256 tokenIndex)
```

### exactBptInForTokensOut

```solidity
function exactBptInForTokensOut(bytes self) internal pure returns (uint256 bptAmountIn)
```

### bptInForExactTokensOut

```solidity
function bptInForExactTokensOut(bytes self) internal pure returns (uint256[] amountsOut, uint256 maxBPTAmountIn)
```

## IAuthentication

### getActionId

```solidity
function getActionId(bytes4 selector) external view returns (bytes32)
```

_Returns the action identifier associated with the external function described by `selector`._

## ISignaturesValidator

_Interface for the SignatureValidator helper, used to support meta-transactions._

### getDomainSeparator

```solidity
function getDomainSeparator() external view returns (bytes32)
```

_Returns the EIP712 domain separator._

### getNextNonce

```solidity
function getNextNonce(address user) external view returns (uint256)
```

_Returns the next nonce used by an address to sign messages._

## ITemporarilyPausable

_Interface for the TemporarilyPausable helper._

### PausedStateChanged

```solidity
event PausedStateChanged(bool paused)
```

_Emitted every time the pause state changes by `_setPaused`._

### getPausedState

```solidity
function getPausedState() external view returns (bool paused, uint256 pauseWindowEndTime, uint256 bufferPeriodEndTime)
```

_Returns the current paused state._

## IWETH

_Interface for WETH9.
See https://github.com/gnosis/canonical-weth/blob/0dd1ea3e295eef916d0c6223ec63141137d22d67/contracts/WETH9.sol_

### deposit

```solidity
function deposit() external payable
```

### withdraw

```solidity
function withdraw(uint256 amount) external
```

## IERC20

_Interface of the ERC20 standard as defined in the EIP._

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

_Returns the amount of tokens in existence._

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

_Returns the amount of tokens owned by `account`._

### transfer

```solidity
function transfer(address recipient, uint256 amount) external returns (bool)
```

\_Moves `amount` tokens from the caller's account to `recipient`.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event.\_

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

\_Returns the remaining number of tokens that `spender` will be
allowed to spend on behalf of `owner` through {transferFrom}. This is
zero by default.

This value changes when {approve} or {transferFrom} are called.\_

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

\_Sets `amount` as the allowance of `spender` over the caller's tokens.

Returns a boolean value indicating whether the operation succeeded.

IMPORTANT: Beware that changing an allowance with this method brings the risk
that someone may use both the old and the new allowance by unfortunate
transaction ordering. One possible solution to mitigate this race
condition is to first reduce the spender's allowance to 0 and set the
desired value afterwards:
https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

Emits an {Approval} event.\_

### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)
```

\_Moves `amount` tokens from `sender` to `recipient` using the
allowance mechanism. `amount` is then deducted from the caller's
allowance.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event.\_

### Transfer

```solidity
event Transfer(address from, address to, uint256 value)
```

\_Emitted when `value` tokens are moved from one account (`from`) to
another (`to`).

Note that `value` may be zero.\_

### Approval

```solidity
event Approval(address owner, address spender, uint256 value)
```

_Emitted when the allowance of a `spender` for an `owner` is set by
a call to {approve}. `value` is the new allowance._

## IAsset

\_This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
types.

This concept is unrelated to a Pool's Asset Managers.\_

## IAuthorizer

### canPerform

```solidity
function canPerform(bytes32 actionId, address account, address where) external view returns (bool)
```

_Returns true if `account` can perform the action described by `actionId` in the contract `where`._

## IFlashLoanRecipient

### receiveFlashLoan

```solidity
function receiveFlashLoan(contract IERC20[] tokens, uint256[] amounts, uint256[] feeAmounts, bytes userData) external
```

\_When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.

At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
Vault, or else the entire flash loan will revert.

`userData` is the same value passed in the `IVault.flashLoan` call.\_

## IProtocolFeesCollector

### SwapFeePercentageChanged

```solidity
event SwapFeePercentageChanged(uint256 newSwapFeePercentage)
```

### FlashLoanFeePercentageChanged

```solidity
event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage)
```

### withdrawCollectedFees

```solidity
function withdrawCollectedFees(contract IERC20[] tokens, uint256[] amounts, address recipient) external
```

### setSwapFeePercentage

```solidity
function setSwapFeePercentage(uint256 newSwapFeePercentage) external
```

### setFlashLoanFeePercentage

```solidity
function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external
```

### getSwapFeePercentage

```solidity
function getSwapFeePercentage() external view returns (uint256)
```

### getFlashLoanFeePercentage

```solidity
function getFlashLoanFeePercentage() external view returns (uint256)
```

### getCollectedFeeAmounts

```solidity
function getCollectedFeeAmounts(contract IERC20[] tokens) external view returns (uint256[] feeAmounts)
```

### getAuthorizer

```solidity
function getAuthorizer() external view returns (contract IAuthorizer)
```

### vault

```solidity
function vault() external view returns (contract IVault)
```

## IVault

_Full external interface for the Vault core contract - no external or public methods exist in the contract that
don't override one of these declarations._

### getAuthorizer

```solidity
function getAuthorizer() external view returns (contract IAuthorizer)
```

_Returns the Vault's Authorizer._

### setAuthorizer

```solidity
function setAuthorizer(contract IAuthorizer newAuthorizer) external
```

\_Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.

Emits an `AuthorizerChanged` event.\_

### AuthorizerChanged

```solidity
event AuthorizerChanged(contract IAuthorizer newAuthorizer)
```

_Emitted when a new authorizer is set by `setAuthorizer`._

### hasApprovedRelayer

```solidity
function hasApprovedRelayer(address user, address relayer) external view returns (bool)
```

_Returns true if `user` has approved `relayer` to act as a relayer for them._

### setRelayerApproval

```solidity
function setRelayerApproval(address sender, address relayer, bool approved) external
```

\_Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.

Emits a `RelayerApprovalChanged` event.\_

### RelayerApprovalChanged

```solidity
event RelayerApprovalChanged(address relayer, address sender, bool approved)
```

_Emitted every time a relayer is approved or disapproved by `setRelayerApproval`._

### getInternalBalance

```solidity
function getInternalBalance(address user, contract IERC20[] tokens) external view returns (uint256[])
```

_Returns `user`'s Internal Balance for a set of tokens._

### manageUserBalance

```solidity
function manageUserBalance(struct IVault.UserBalanceOp[] ops) external payable
```

\_Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
it lets integrators reuse a user's Vault allowance.

For each operation, if the caller is not `sender`, it must be an authorized relayer for them.\_

### UserBalanceOp

```solidity
struct UserBalanceOp {
  enum IVault.UserBalanceOpKind kind;
  contract IAsset asset;
  uint256 amount;
  address sender;
  address payable recipient;
}
```

### UserBalanceOpKind

```solidity
enum UserBalanceOpKind {
  DEPOSIT_INTERNAL,
  WITHDRAW_INTERNAL,
  TRANSFER_INTERNAL,
  TRANSFER_EXTERNAL
}
```

### InternalBalanceChanged

```solidity
event InternalBalanceChanged(address user, contract IERC20 token, int256 delta)
```

\_Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
interacting with Pools using Internal Balance.

Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
address.\_

### ExternalBalanceTransfer

```solidity
event ExternalBalanceTransfer(contract IERC20 token, address sender, address recipient, uint256 amount)
```

_Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account._

### PoolSpecialization

```solidity
enum PoolSpecialization {
  GENERAL,
  MINIMAL_SWAP_INFO,
  TWO_TOKEN
}
```

### registerPool

```solidity
function registerPool(enum IVault.PoolSpecialization specialization) external returns (bytes32)
```

\_Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
changed.

The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
depending on the chosen specialization setting. This contract is known as the Pool's contract.

Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
multiple Pools may share the same contract.

Emits a `PoolRegistered` event.\_

### PoolRegistered

```solidity
event PoolRegistered(bytes32 poolId, address poolAddress, enum IVault.PoolSpecialization specialization)
```

_Emitted when a Pool is registered by calling `registerPool`._

### getPool

```solidity
function getPool(bytes32 poolId) external view returns (address, enum IVault.PoolSpecialization)
```

_Returns a Pool's contract address and specialization setting._

### registerTokens

```solidity
function registerTokens(bytes32 poolId, contract IERC20[] tokens, address[] assetManagers) external
```

\_Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.

Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
exit by receiving registered tokens, and can only swap registered tokens.

Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
ascending order.

The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
expected to be highly secured smart contracts with sound design principles, and the decision to register an
Asset Manager should not be made lightly.

Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
different Asset Manager.

Emits a `TokensRegistered` event.\_

### TokensRegistered

```solidity
event TokensRegistered(bytes32 poolId, contract IERC20[] tokens, address[] assetManagers)
```

_Emitted when a Pool registers tokens by calling `registerTokens`._

### deregisterTokens

```solidity
function deregisterTokens(bytes32 poolId, contract IERC20[] tokens) external
```

\_Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.

Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
must be deregistered in the same `deregisterTokens` call.

A deregistered token can be re-registered later on, possibly with a different Asset Manager.

Emits a `TokensDeregistered` event.\_

### TokensDeregistered

```solidity
event TokensDeregistered(bytes32 poolId, contract IERC20[] tokens)
```

_Emitted when a Pool deregisters tokens by calling `deregisterTokens`._

### getPoolTokenInfo

```solidity
function getPoolTokenInfo(bytes32 poolId, contract IERC20 token) external view returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager)
```

\_Returns detailed information for a Pool's registered token.

`cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
equals the sum of `cash` and `managed`.

Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
`managed` or `total` balance to be greater than 2^112 - 1.

`lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
change for this purpose, and will update `lastChangeBlock`.

`assetManager` is the Pool's token Asset Manager.\_

### getPoolTokens

```solidity
function getPoolTokens(bytes32 poolId) external view returns (contract IERC20[] tokens, uint256[] balances, uint256 lastChangeBlock)
```

\_Returns a Pool's registered tokens, the total balance for each, and the latest block when _any_ of
the tokens' `balances` changed.

The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.

If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
order as passed to `registerTokens`.

Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
instead.\_

### joinPool

```solidity
function joinPool(bytes32 poolId, address sender, address recipient, struct IVault.JoinPoolRequest request) external payable
```

\_Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
Pool shares.

If the caller is not `sender`, it must be an authorized relayer for them.

The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
these maximums.

If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
back to the caller (not the sender, which is important for relayers).

`assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
sorted _before_ replacing the WETH address with the ETH sentinel value (the zero address), which means the final
`assets` array might not be sorted. Pools with no registered tokens cannot be joined.

If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
withdrawn from Internal Balance: attempting to do so will trigger a revert.

This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
their own custom logic. This typically requires additional information from the user (such as the expected number
of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
directly to the Pool's contract, as is `recipient`.

Emits a `PoolBalanceChanged` event.\_

### JoinPoolRequest

```solidity
struct JoinPoolRequest {
  contract IAsset[] assets;
  uint256[] maxAmountsIn;
  bytes userData;
  bool fromInternalBalance;
}
```

### exitPool

```solidity
function exitPool(bytes32 poolId, address sender, address payable recipient, struct IVault.ExitPoolRequest request) external
```

\_Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
`getPoolTokenInfo`).

If the caller is not `sender`, it must be an authorized relayer for them.

The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
it just enforces these minimums.

If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.

`assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
be sorted _before_ replacing the WETH address with the ETH sentinel value (the zero address), which means the
final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.

If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
do so will trigger a revert.

`minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
`tokens` array. This array must match the Pool's registered tokens.

This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
their own custom logic. This typically requires additional information from the user (such as the expected number
of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
passed directly to the Pool's contract.

Emits a `PoolBalanceChanged` event.\_

### ExitPoolRequest

```solidity
struct ExitPoolRequest {
  contract IAsset[] assets;
  uint256[] minAmountsOut;
  bytes userData;
  bool toInternalBalance;
}
```

### PoolBalanceChanged

```solidity
event PoolBalanceChanged(bytes32 poolId, address liquidityProvider, contract IERC20[] tokens, int256[] deltas, uint256[] protocolFeeAmounts)
```

_Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively._

### PoolBalanceChangeKind

```solidity
enum PoolBalanceChangeKind {
  JOIN,
  EXIT
}
```

### SwapKind

```solidity
enum SwapKind {
  GIVEN_IN,
  GIVEN_OUT
}
```

### swap

```solidity
function swap(struct IVault.SingleSwap singleSwap, struct IVault.FundManagement funds, uint256 limit, uint256 deadline) external payable returns (uint256)
```

\_Performs a swap with a single Pool.

If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
taken from the Pool, which must be greater than or equal to `limit`.

If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
sent to the Pool, which must be less than or equal to `limit`.

Internal Balance usage and the recipient are determined by the `funds` struct.

Emits a `Swap` event.\_

### SingleSwap

```solidity
struct SingleSwap {
  bytes32 poolId;
  enum IVault.SwapKind kind;
  contract IAsset assetIn;
  contract IAsset assetOut;
  uint256 amount;
  bytes userData;
}
```

### batchSwap

```solidity
function batchSwap(enum IVault.SwapKind kind, struct IVault.BatchSwapStep[] swaps, contract IAsset[] assets, struct IVault.FundManagement funds, int256[] limits, uint256 deadline) external payable returns (int256[])
```

\_Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
the amount of tokens sent to or received from the Pool, depending on the `kind` value.

Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
the same index in the `assets` array.

Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
`amountOut` depending on the swap kind.

Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.

The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
or unwrapped from WETH by the Vault.

Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
the minimum or maximum amount of each token the vault is allowed to transfer.

`batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
equivalent `swap` call.

Emits `Swap` events.\_

### BatchSwapStep

```solidity
struct BatchSwapStep {
  bytes32 poolId;
  uint256 assetInIndex;
  uint256 assetOutIndex;
  uint256 amount;
  bytes userData;
}
```

### Swap

```solidity
event Swap(bytes32 poolId, contract IERC20 tokenIn, contract IERC20 tokenOut, uint256 amountIn, uint256 amountOut)
```

_Emitted for each individual swap performed by `swap` or `batchSwap`._

### FundManagement

```solidity
struct FundManagement {
  address sender;
  bool fromInternalBalance;
  address payable recipient;
  bool toInternalBalance;
}
```

### queryBatchSwap

```solidity
function queryBatchSwap(enum IVault.SwapKind kind, struct IVault.BatchSwapStep[] swaps, contract IAsset[] assets, struct IVault.FundManagement funds) external returns (int256[] assetDeltas)
```

\_Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.

Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
receives are the same that an equivalent `batchSwap` call would receive.

Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
approve them for the Vault, or even know a user's address.

Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
eth*call instead of eth_sendTransaction.*

### flashLoan

```solidity
function flashLoan(contract IFlashLoanRecipient recipient, contract IERC20[] tokens, uint256[] amounts, bytes userData) external
```

\_Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
and then reverting unless the tokens plus a proportional protocol fee have been returned.

The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
for each token contract. `tokens` must be sorted in ascending order.

The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
`receiveFlashLoan` call.

Emits `FlashLoan` events.\_

### FlashLoan

```solidity
event FlashLoan(contract IFlashLoanRecipient recipient, contract IERC20 token, uint256 amount, uint256 feeAmount)
```

_Emitted for each individual flash loan performed by `flashLoan`._

### managePoolBalance

```solidity
function managePoolBalance(struct IVault.PoolBalanceOp[] ops) external
```

\_Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.

Pool Balance management features batching, which means a single contract call can be used to perform multiple
operations of different kinds, with different Pools and tokens, at once.

For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.\_

### PoolBalanceOp

```solidity
struct PoolBalanceOp {
  enum IVault.PoolBalanceOpKind kind;
  bytes32 poolId;
  contract IERC20 token;
  uint256 amount;
}
```

### PoolBalanceOpKind

```solidity
enum PoolBalanceOpKind {
  WITHDRAW,
  DEPOSIT,
  UPDATE
}
```

### PoolBalanceManaged

```solidity
event PoolBalanceManaged(bytes32 poolId, address assetManager, contract IERC20 token, int256 cashDelta, int256 managedDelta)
```

_Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`._

### getProtocolFeesCollector

```solidity
function getProtocolFeesCollector() external view returns (contract IProtocolFeesCollector)
```

_Returns the current protocol fee module._

### setPaused

```solidity
function setPaused(bool paused) external
```

\_Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
error in some part of the system.

The Vault can only be paused during an initial time period, after which pausing is forever disabled.

While the contract is paused, the following features are disabled:

- depositing and transferring internal balance
- transferring external balance (using the Vault's allowance)
- swaps
- joining Pools
- Asset Manager interactions

Internal Balance can still be withdrawn, and Pools exited.\_

### WETH

```solidity
function WETH() external view returns (contract IWETH)
```

_Returns the Vault's WETH instance._

## AccessControl

\_Contract module that allows children to implement role-based access
control mechanisms. This is a lightweight version that doesn't allow enumerating role
members except through off-chain means by accessing the contract event logs. Some
applications may benefit from on-chain enumerability, for those cases see
{AccessControlEnumerable}.

Roles are referred to by their `bytes32` identifier. These should be exposed
in the external API and be unique. The best way to achieve this is by
using `public constant` hash digests:

```solidity
bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
```

Roles can be used to represent a set of permissions. To restrict access to a
function call, use {hasRole}:

```solidity
function foo() public {
    require(hasRole(MY_ROLE, msg.sender));
    ...
}
```

Roles can be granted and revoked dynamically via the {grantRole} and
{revokeRole} functions. Each role has an associated admin role, and only
accounts that have a role's admin role can call {grantRole} and {revokeRole}.

By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
that only accounts with this role will be able to grant or revoke other
roles. More complex role relationships can be created by using
{\_setRoleAdmin}.

WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
grant and revoke this role. Extra precautions should be taken to secure
accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
to enforce additional security measures for this role.\_

### RoleData

```solidity
struct RoleData {
  mapping(address => bool) members;
  bytes32 adminRole;
}
```

### DEFAULT_ADMIN_ROLE

```solidity
bytes32 DEFAULT_ADMIN_ROLE
```

### onlyRole

```solidity
modifier onlyRole(bytes32 role)
```

\_Modifier that checks that an account has a specific role. Reverts
with a standardized message including the required role.

The format of the revert reason is given by the following regular expression:

/^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/

\_Available since v4.1.\_\_

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### hasRole

```solidity
function hasRole(bytes32 role, address account) public view virtual returns (bool)
```

_Returns `true` if `account` has been granted `role`._

### \_checkRole

```solidity
function _checkRole(bytes32 role) internal view virtual
```

\_Revert with a standard message if `_msgSender()` is missing `role`.
Overriding this function changes the behavior of the {onlyRole} modifier.

Format of the revert message is described in {\_checkRole}.

\_Available since v4.6.\_\_

### \_checkRole

```solidity
function _checkRole(bytes32 role, address account) internal view virtual
```

\_Revert with a standard message if `account` is missing `role`.

The format of the revert reason is given by the following regular expression:

/^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/\_

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) public view virtual returns (bytes32)
```

\_Returns the admin role that controls `role`. See {grantRole} and
{revokeRole}.

To change a role's admin, use {_setRoleAdmin}._

### grantRole

```solidity
function grantRole(bytes32 role, address account) public virtual
```

\_Grants `role` to `account`.

If `account` had not been already granted `role`, emits a {RoleGranted}
event.

Requirements:

- the caller must have `role`'s admin role.

May emit a {RoleGranted} event.\_

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) public virtual
```

\_Revokes `role` from `account`.

If `account` had been granted `role`, emits a {RoleRevoked} event.

Requirements:

- the caller must have `role`'s admin role.

May emit a {RoleRevoked} event.\_

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) public virtual
```

\_Revokes `role` from the calling account.

Roles are often managed via {grantRole} and {revokeRole}: this function's
purpose is to provide a mechanism for accounts to lose their privileges
if they are compromised (such as when a trusted device is misplaced).

If the calling account had been revoked `role`, emits a {RoleRevoked}
event.

Requirements:

- the caller must be `account`.

May emit a {RoleRevoked} event.\_

### \_setupRole

```solidity
function _setupRole(bytes32 role, address account) internal virtual
```

\_Grants `role` to `account`.

If `account` had not been already granted `role`, emits a {RoleGranted}
event. Note that unlike {grantRole}, this function doesn't perform any
checks on the calling account.

May emit a {RoleGranted} event.

# [WARNING]

This function should only be called from the constructor when setting
up the initial roles for the system.

Using this function in any other way is effectively circumventing the admin
system imposed by {AccessControl}.
====

NOTE: This function is deprecated in favor of {_grantRole}._

### \_setRoleAdmin

```solidity
function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual
```

\_Sets `adminRole` as `role`'s admin role.

Emits a {RoleAdminChanged} event.\_

### \_grantRole

```solidity
function _grantRole(bytes32 role, address account) internal virtual
```

\_Grants `role` to `account`.

Internal function without access restriction.

May emit a {RoleGranted} event.\_

### \_revokeRole

```solidity
function _revokeRole(bytes32 role, address account) internal virtual
```

\_Revokes `role` from `account`.

Internal function without access restriction.

May emit a {RoleRevoked} event.\_

## IAccessControl

_External interface of AccessControl declared to support ERC165 detection._

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 role, bytes32 previousAdminRole, bytes32 newAdminRole)
```

\_Emitted when `newAdminRole` is set as `role`'s admin role, replacing `previousAdminRole`

`DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
{RoleAdminChanged} not being emitted signaling this.

\_Available since v3.1.\_\_

### RoleGranted

```solidity
event RoleGranted(bytes32 role, address account, address sender)
```

\_Emitted when `account` is granted `role`.

`sender` is the account that originated the contract call, an admin role
bearer except when using {AccessControl-_setupRole}._

### RoleRevoked

```solidity
event RoleRevoked(bytes32 role, address account, address sender)
```

\_Emitted when `account` is revoked `role`.

`sender` is the account that originated the contract call:

- if using `revokeRole`, it is the admin role bearer
- if using `renounceRole`, it is the role bearer (i.e. `account`)\_

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```

_Returns `true` if `account` has been granted `role`._

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```

\_Returns the admin role that controls `role`. See {grantRole} and
{revokeRole}.

To change a role's admin, use {AccessControl-_setRoleAdmin}._

### grantRole

```solidity
function grantRole(bytes32 role, address account) external
```

\_Grants `role` to `account`.

If `account` had not been already granted `role`, emits a {RoleGranted}
event.

Requirements:

- the caller must have `role`'s admin role.\_

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external
```

\_Revokes `role` from `account`.

If `account` had been granted `role`, emits a {RoleRevoked} event.

Requirements:

- the caller must have `role`'s admin role.\_

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external
```

\_Revokes `role` from the calling account.

Roles are often managed via {grantRole} and {revokeRole}: this function's
purpose is to provide a mechanism for accounts to lose their privileges
if they are compromised (such as when a trusted device is misplaced).

If the calling account had been granted `role`, emits a {RoleRevoked}
event.

Requirements:

- the caller must be `account`.\_

## IGovernor

\_Interface of the {Governor} core.

\_Available since v4.3.\_\_

### ProposalState

```solidity
enum ProposalState {
  Pending,
  Active,
  Canceled,
  Defeated,
  Succeeded,
  Queued,
  Expired,
  Executed
}
```

### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 voteStart, uint256 voteEnd, string description)
```

_Emitted when a proposal is created._

### ProposalCanceled

```solidity
event ProposalCanceled(uint256 proposalId)
```

_Emitted when a proposal is canceled._

### ProposalExecuted

```solidity
event ProposalExecuted(uint256 proposalId)
```

_Emitted when a proposal is executed._

### VoteCast

```solidity
event VoteCast(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason)
```

\_Emitted when a vote is cast without params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.\_

### VoteCastWithParams

```solidity
event VoteCastWithParams(address voter, uint256 proposalId, uint8 support, uint256 weight, string reason, bytes params)
```

\_Emitted when a vote is cast with params.

Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
`params` are additional encoded parameters. Their interpepretation also depends on the voting module used.\_

### name

```solidity
function name() public view virtual returns (string)
```

module:core

_Name of the governor instance (used in building the ERC712 domain separator)._

### version

```solidity
function version() public view virtual returns (string)
```

module:core

_Version of the governor instance (used in building the ERC712 domain separator). Default: "1"_

### clock

```solidity
function clock() public view virtual returns (uint48)
```

module:core

_See {IERC6372}_

### CLOCK_MODE

```solidity
function CLOCK_MODE() public view virtual returns (string)
```

module:core

_See EIP-6372._

### COUNTING_MODE

```solidity
function COUNTING_MODE() public view virtual returns (string)
```

module:voting

\_A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.

There are 2 standard keys: `support` and `quorum`.

- `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
- `quorum=bravo` means that only For votes are counted towards quorum.
- `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.

If a counting module makes use of encoded `params`, it should include this under a `params` key with a unique
name that describes the behavior. For example:

- `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
- `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.

NOTE: The string can be decoded by the standard
https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
JavaScript class.\_

### hashProposal

```solidity
function hashProposal(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public pure virtual returns (uint256)
```

module:core

_Hashing function used to (re)build the proposal id from the proposal details.._

### state

```solidity
function state(uint256 proposalId) public view virtual returns (enum IGovernor.ProposalState)
```

module:core

_Current state of a proposal, following Compound's convention_

### proposalSnapshot

```solidity
function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256)
```

module:core

_Timepoint used to retrieve user's votes and quorum. If using block number (as per Compound's Comp), the
snapshot is performed at the end of this block. Hence, voting for this proposal starts at the beginning of the
following block._

### proposalDeadline

```solidity
function proposalDeadline(uint256 proposalId) public view virtual returns (uint256)
```

module:core

_Timepoint at which votes close. If using block number, votes close at the end of this block, so it is
possible to cast a vote during this block._

### proposalProposer

```solidity
function proposalProposer(uint256 proposalId) public view virtual returns (address)
```

module:core

_The account that created a proposal._

### votingDelay

```solidity
function votingDelay() public view virtual returns (uint256)
```

module:user-config

\_Delay, between the proposal is created and the vote starts. The unit this duration is expressed in depends
on the clock (see EIP-6372) this contract uses.

This can be increased to leave time for users to buy voting power, or delegate it, before the voting of a
proposal starts.\_

### votingPeriod

```solidity
function votingPeriod() public view virtual returns (uint256)
```

module:user-config

\_Delay between the vote start and vote end. The unit this duration is expressed in depends on the clock
(see EIP-6372) this contract uses.

NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
duration compared to the voting delay.\_

### quorum

```solidity
function quorum(uint256 timepoint) public view virtual returns (uint256)
```

module:user-config

\_Minimum number of cast voted required for a proposal to be successful.

NOTE: The `timepoint` parameter corresponds to the snapshot used for counting vote. This allows to scale the
quorum depending on values such as the totalSupply of a token at this timepoint (see {ERC20Votes}).\_

### getVotes

```solidity
function getVotes(address account, uint256 timepoint) public view virtual returns (uint256)
```

module:reputation

\_Voting power of an `account` at a specific `timepoint`.

Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
multiple), {ERC20Votes} tokens.\_

### getVotesWithParams

```solidity
function getVotesWithParams(address account, uint256 timepoint, bytes params) public view virtual returns (uint256)
```

module:reputation

_Voting power of an `account` at a specific `timepoint` given additional encoded parameters._

### hasVoted

```solidity
function hasVoted(uint256 proposalId, address account) public view virtual returns (bool)
```

module:voting

_Returns whether `account` has cast a vote on `proposalId`._

### propose

```solidity
function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) public virtual returns (uint256 proposalId)
```

\_Create a new proposal. Vote start after a delay specified by {IGovernor-votingDelay} and lasts for a
duration specified by {IGovernor-votingPeriod}.

Emits a {ProposalCreated} event.\_

### execute

```solidity
function execute(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public payable virtual returns (uint256 proposalId)
```

\_Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
deadline to be reached.

Emits a {ProposalExecuted} event.

Note: some module can modify the requirements for execution, for example by adding an additional timelock.\_

### cancel

```solidity
function cancel(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public virtual returns (uint256 proposalId)
```

\_Cancel a proposal. A proposal is cancellable by the proposer, but only while it is Pending state, i.e.
before the vote starts.

Emits a {ProposalCanceled} event.\_

### castVote

```solidity
function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance)
```

\_Cast a vote

Emits a {VoteCast} event.\_

### castVoteWithReason

```solidity
function castVoteWithReason(uint256 proposalId, uint8 support, string reason) public virtual returns (uint256 balance)
```

\_Cast a vote with a reason

Emits a {VoteCast} event.\_

### castVoteWithReasonAndParams

```solidity
function castVoteWithReasonAndParams(uint256 proposalId, uint8 support, string reason, bytes params) public virtual returns (uint256 balance)
```

\_Cast a vote with a reason and additional encoded parameters

Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.\_

### castVoteBySig

```solidity
function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256 balance)
```

\_Cast a vote using the user's cryptographic signature.

Emits a {VoteCast} event.\_

### castVoteWithReasonAndParamsBySig

```solidity
function castVoteWithReasonAndParamsBySig(uint256 proposalId, uint8 support, string reason, bytes params, uint8 v, bytes32 r, bytes32 s) public virtual returns (uint256 balance)
```

\_Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.

Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.\_

## TimelockController

\_Contract module which acts as a timelocked controller. When set as the
owner of an `Ownable` smart contract, it enforces a timelock on all
`onlyOwner` maintenance operations. This gives time for users of the
controlled contract to exit before a potentially dangerous maintenance
operation is applied.

By default, this contract is self administered, meaning administration tasks
have to go through the timelock process. The proposer (resp executor) role
is in charge of proposing (resp executing) operations. A common use case is
to position this {TimelockController} as the owner of a smart contract, with
a multisig or a DAO as the sole proposer.

\_Available since v3.3.\_\_

### TIMELOCK_ADMIN_ROLE

```solidity
bytes32 TIMELOCK_ADMIN_ROLE
```

### PROPOSER_ROLE

```solidity
bytes32 PROPOSER_ROLE
```

### EXECUTOR_ROLE

```solidity
bytes32 EXECUTOR_ROLE
```

### CANCELLER_ROLE

```solidity
bytes32 CANCELLER_ROLE
```

### \_DONE_TIMESTAMP

```solidity
uint256 _DONE_TIMESTAMP
```

### CallScheduled

```solidity
event CallScheduled(bytes32 id, uint256 index, address target, uint256 value, bytes data, bytes32 predecessor, uint256 delay)
```

_Emitted when a call is scheduled as part of operation `id`._

### CallExecuted

```solidity
event CallExecuted(bytes32 id, uint256 index, address target, uint256 value, bytes data)
```

_Emitted when a call is performed as part of operation `id`._

### CallSalt

```solidity
event CallSalt(bytes32 id, bytes32 salt)
```

_Emitted when new proposal is scheduled with non-zero salt._

### Cancelled

```solidity
event Cancelled(bytes32 id)
```

_Emitted when operation `id` is cancelled._

### MinDelayChange

```solidity
event MinDelayChange(uint256 oldDuration, uint256 newDuration)
```

_Emitted when the minimum delay for future operations is modified._

### constructor

```solidity
constructor(uint256 minDelay, address[] proposers, address[] executors, address admin) public
```

\_Initializes the contract with the following parameters:

- `minDelay`: initial minimum delay for operations
- `proposers`: accounts to be granted proposer and canceller roles
- `executors`: accounts to be granted executor role
- `admin`: optional account to be granted admin role; disable with zero address

IMPORTANT: The optional admin can aid with initial configuration of roles after deployment
without being subject to delay, but this role should be subsequently renounced in favor of
administration through timelocked proposals. Previous versions of this contract would assign
this admin to the deployer automatically and should be renounced as well.\_

### onlyRoleOrOpenRole

```solidity
modifier onlyRoleOrOpenRole(bytes32 role)
```

_Modifier to make a function callable only by a certain role. In
addition to checking the sender's role, `address(0)` 's role is also
considered. Granting a role to `address(0)` is equivalent to enabling
this role for everyone._

### receive

```solidity
receive() external payable
```

_Contract might receive/hold ETH as part of the maintenance process._

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### isOperation

```solidity
function isOperation(bytes32 id) public view virtual returns (bool)
```

_Returns whether an id correspond to a registered operation. This
includes both Pending, Ready and Done operations._

### isOperationPending

```solidity
function isOperationPending(bytes32 id) public view virtual returns (bool)
```

_Returns whether an operation is pending or not. Note that a "pending" operation may also be "ready"._

### isOperationReady

```solidity
function isOperationReady(bytes32 id) public view virtual returns (bool)
```

_Returns whether an operation is ready for execution. Note that a "ready" operation is also "pending"._

### isOperationDone

```solidity
function isOperationDone(bytes32 id) public view virtual returns (bool)
```

_Returns whether an operation is done or not._

### getTimestamp

```solidity
function getTimestamp(bytes32 id) public view virtual returns (uint256)
```

_Returns the timestamp at which an operation becomes ready (0 for
unset operations, 1 for done operations)._

### getMinDelay

```solidity
function getMinDelay() public view virtual returns (uint256)
```

\_Returns the minimum delay for an operation to become valid.

This value can be changed by executing an operation that calls `updateDelay`.\_

### hashOperation

```solidity
function hashOperation(address target, uint256 value, bytes data, bytes32 predecessor, bytes32 salt) public pure virtual returns (bytes32)
```

_Returns the identifier of an operation containing a single
transaction._

### hashOperationBatch

```solidity
function hashOperationBatch(address[] targets, uint256[] values, bytes[] payloads, bytes32 predecessor, bytes32 salt) public pure virtual returns (bytes32)
```

_Returns the identifier of an operation containing a batch of
transactions._

### schedule

```solidity
function schedule(address target, uint256 value, bytes data, bytes32 predecessor, bytes32 salt, uint256 delay) public virtual
```

\_Schedule an operation containing a single transaction.

Emits {CallSalt} if salt is nonzero, and {CallScheduled}.

Requirements:

- the caller must have the 'proposer' role.\_

### scheduleBatch

```solidity
function scheduleBatch(address[] targets, uint256[] values, bytes[] payloads, bytes32 predecessor, bytes32 salt, uint256 delay) public virtual
```

\_Schedule an operation containing a batch of transactions.

Emits {CallSalt} if salt is nonzero, and one {CallScheduled} event per transaction in the batch.

Requirements:

- the caller must have the 'proposer' role.\_

### cancel

```solidity
function cancel(bytes32 id) public virtual
```

\_Cancel an operation.

Requirements:

- the caller must have the 'canceller' role.\_

### execute

```solidity
function execute(address target, uint256 value, bytes payload, bytes32 predecessor, bytes32 salt) public payable virtual
```

\_Execute an (ready) operation containing a single transaction.

Emits a {CallExecuted} event.

Requirements:

- the caller must have the 'executor' role.\_

### executeBatch

```solidity
function executeBatch(address[] targets, uint256[] values, bytes[] payloads, bytes32 predecessor, bytes32 salt) public payable virtual
```

\_Execute an (ready) operation containing a batch of transactions.

Emits one {CallExecuted} event per transaction in the batch.

Requirements:

- the caller must have the 'executor' role.\_

### \_execute

```solidity
function _execute(address target, uint256 value, bytes data) internal virtual
```

_Execute an operation's call._

### updateDelay

```solidity
function updateDelay(uint256 newDelay) external virtual
```

\_Changes the minimum timelock duration for future operations.

Emits a {MinDelayChange} event.

Requirements:

- the caller must be the timelock itself. This can only be achieved by scheduling and later executing
  an operation where the timelock is the target and the data is the ABI-encoded call to this function.\_

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC721Receiver-onERC721Received}._

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155Received}._

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) public virtual returns (bytes4)
```

_See {IERC1155Receiver-onERC1155BatchReceived}._

## IGovernorTimelock

\_Extension of the {IGovernor} for timelock supporting modules.

\_Available since v4.3.\_\_

### ProposalQueued

```solidity
event ProposalQueued(uint256 proposalId, uint256 eta)
```

### timelock

```solidity
function timelock() public view virtual returns (address)
```

### proposalEta

```solidity
function proposalEta(uint256 proposalId) public view virtual returns (uint256)
```

### queue

```solidity
function queue(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) public virtual returns (uint256 proposalId)
```

## IERC5267

### EIP712DomainChanged

```solidity
event EIP712DomainChanged()
```

_MAY be emitted to signal that the domain could have changed._

### eip712Domain

```solidity
function eip712Domain() external view returns (bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
```

_returns the fields and values that describe the domain separator used by this contract for EIP-712
signature._

## IERC6372

### clock

```solidity
function clock() external view returns (uint48)
```

_Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting)._

### CLOCK_MODE

```solidity
function CLOCK_MODE() external view returns (string)
```

_Description of the clock_

## ReentrancyGuard

\_Contract module that helps prevent reentrant calls to a function.

Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
available, which can be applied to functions to make sure there are no nested
(reentrant) calls to them.

Note that because there is a single `nonReentrant` guard, functions marked as
`nonReentrant` may not call one another. This can be worked around by making
those functions `private`, and then adding `external` `nonReentrant` entry
points to them.

TIP: If you would like to learn more about reentrancy and alternative ways
to protect against it, check out our blog post
https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].\_

### constructor

```solidity
constructor() internal
```

### nonReentrant

```solidity
modifier nonReentrant()
```

_Prevents a contract from calling itself, directly or indirectly.
Calling a `nonReentrant` function from another `nonReentrant`
function is not supported. It is possible to prevent this from happening
by making the `nonReentrant` function external, and making it call a
`private` function that does the actual work._

### \_reentrancyGuardEntered

```solidity
function _reentrancyGuardEntered() internal view returns (bool)
```

_Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
`nonReentrant` function in the call stack._

## IERC1155Receiver

**Available since v3.1.**

### onERC1155Received

```solidity
function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes data) external returns (bytes4)
```

\_Handles the receipt of a single ERC1155 token type. This function is
called at the end of a `safeTransferFrom` after the balance has been updated.

NOTE: To accept the transfer, this must return
`bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
(i.e. 0xf23a6e61, or its own function selector).\_

#### Parameters

| Name     | Type    | Description                                                |
| -------- | ------- | ---------------------------------------------------------- |
| operator | address | The address which initiated the transfer (i.e. msg.sender) |
| from     | address | The address which previously owned the token               |
| id       | uint256 | The ID of the token being transferred                      |
| value    | uint256 | The amount of tokens being transferred                     |
| data     | bytes   | Additional data with no specified format                   |

#### Return Values

| Name | Type   | Description                                                                                            |
| ---- | ------ | ------------------------------------------------------------------------------------------------------ |
| [0]  | bytes4 | `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed |

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address operator, address from, uint256[] ids, uint256[] values, bytes data) external returns (bytes4)
```

\_Handles the receipt of a multiple ERC1155 token types. This function
is called at the end of a `safeBatchTransferFrom` after the balances have
been updated.

NOTE: To accept the transfer(s), this must return
`bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
(i.e. 0xbc197c81, or its own function selector).\_

#### Parameters

| Name     | Type      | Description                                                                                         |
| -------- | --------- | --------------------------------------------------------------------------------------------------- |
| operator | address   | The address which initiated the batch transfer (i.e. msg.sender)                                    |
| from     | address   | The address which previously owned the token                                                        |
| ids      | uint256[] | An array containing ids of each token being transferred (order and length must match values array)  |
| values   | uint256[] | An array containing amounts of each token being transferred (order and length must match ids array) |
| data     | bytes     | Additional data with no specified format                                                            |

#### Return Values

| Name | Type   | Description                                                                                                     |
| ---- | ------ | --------------------------------------------------------------------------------------------------------------- |
| [0]  | bytes4 | `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed |

## ERC20

\_Implementation of the {IERC20} interface.

This implementation is agnostic to the way tokens are created. This means
that a supply mechanism has to be added in a derived contract using {\_mint}.
For a generic mechanism see {ERC20PresetMinterPauser}.

TIP: For a detailed writeup see our guide
https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
to implement supply mechanisms].

The default value of {decimals} is 18. To change this, you should override
this function so it returns a different value.

We have followed general OpenZeppelin Contracts guidelines: functions revert
instead returning `false` on failure. This behavior is nonetheless
conventional and does not conflict with the expectations of ERC20
applications.

Additionally, an {Approval} event is emitted on calls to {transferFrom}.
This allows applications to reconstruct the allowance for all accounts just
by listening to said events. Other implementations of the EIP may not emit
these events, as it isn't required by the specification.

Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
functions have been added to mitigate the well-known issues around setting
allowances. See {IERC20-approve}.\_

### constructor

```solidity
constructor(string name_, string symbol_) public
```

\_Sets the values for {name} and {symbol}.

All two of these values are immutable: they can only be set once during
construction.\_

### name

```solidity
function name() public view virtual returns (string)
```

_Returns the name of the token._

### symbol

```solidity
function symbol() public view virtual returns (string)
```

_Returns the symbol of the token, usually a shorter version of the
name._

### decimals

```solidity
function decimals() public view virtual returns (uint8)
```

\_Returns the number of decimals used to get its user representation.
For example, if `decimals` equals `2`, a balance of `505` tokens should
be displayed to a user as `5.05` (`505 / 10 ** 2`).

Tokens usually opt for a value of 18, imitating the relationship between
Ether and Wei. This is the default value returned by this function, unless
it's overridden.

NOTE: This information is only used for _display_ purposes: it in
no way affects any of the arithmetic of the contract, including
{IERC20-balanceOf} and {IERC20-transfer}.\_

### totalSupply

```solidity
function totalSupply() public view virtual returns (uint256)
```

_See {IERC20-totalSupply}._

### balanceOf

```solidity
function balanceOf(address account) public view virtual returns (uint256)
```

_See {IERC20-balanceOf}._

### transfer

```solidity
function transfer(address to, uint256 amount) public virtual returns (bool)
```

\_See {IERC20-transfer}.

Requirements:

- `to` cannot be the zero address.
- the caller must have a balance of at least `amount`.\_

### allowance

```solidity
function allowance(address owner, address spender) public view virtual returns (uint256)
```

_See {IERC20-allowance}._

### approve

```solidity
function approve(address spender, uint256 amount) public virtual returns (bool)
```

\_See {IERC20-approve}.

NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
`transferFrom`. This is semantically equivalent to an infinite approval.

Requirements:

- `spender` cannot be the zero address.\_

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) public virtual returns (bool)
```

\_See {IERC20-transferFrom}.

Emits an {Approval} event indicating the updated allowance. This is not
required by the EIP. See the note at the beginning of {ERC20}.

NOTE: Does not update the allowance if the current allowance
is the maximum `uint256`.

Requirements:

- `from` and `to` cannot be the zero address.
- `from` must have a balance of at least `amount`.
- the caller must have allowance for `from`'s tokens of at least
  `amount`.\_

### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
```

\_Atomically increases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

- `spender` cannot be the zero address.\_

### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
```

\_Atomically decreases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

- `spender` cannot be the zero address.
- `spender` must have allowance for the caller of at least
  `subtractedValue`.\_

### \_transfer

```solidity
function _transfer(address from, address to, uint256 amount) internal virtual
```

\_Moves `amount` of tokens from `from` to `to`.

This internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.

Emits a {Transfer} event.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `from` must have a balance of at least `amount`.\_

### \_mint

```solidity
function _mint(address account, uint256 amount) internal virtual
```

\_Creates `amount` tokens and assigns them to `account`, increasing
the total supply.

Emits a {Transfer} event with `from` set to the zero address.

Requirements:

- `account` cannot be the zero address.\_

### \_burn

```solidity
function _burn(address account, uint256 amount) internal virtual
```

\_Destroys `amount` tokens from `account`, reducing the
total supply.

Emits a {Transfer} event with `to` set to the zero address.

Requirements:

- `account` cannot be the zero address.
- `account` must have at least `amount` tokens.\_

### \_approve

```solidity
function _approve(address owner, address spender, uint256 amount) internal virtual
```

\_Sets `amount` as the allowance of `spender` over the `owner` s tokens.

This internal function is equivalent to `approve`, and can be used to
e.g. set automatic allowances for certain subsystems, etc.

Emits an {Approval} event.

Requirements:

- `owner` cannot be the zero address.
- `spender` cannot be the zero address.\_

### \_spendAllowance

```solidity
function _spendAllowance(address owner, address spender, uint256 amount) internal virtual
```

\_Updates `owner` s allowance for `spender` based on spent `amount`.

Does not update the allowance amount in case of infinite allowance.
Revert if not enough allowance is available.

Might emit an {Approval} event.\_

### \_beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual
```

\_Hook that is called before any transfer of tokens. This includes
minting and burning.

Calling conditions:

- when `from` and `to` are both non-zero, `amount` of `from`'s tokens
  will be transferred to `to`.
- when `from` is zero, `amount` tokens will be minted for `to`.
- when `to` is zero, `amount` of `from`'s tokens will be burned.
- `from` and `to` are never both zero.

To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].\_

### \_afterTokenTransfer

```solidity
function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual
```

\_Hook that is called after any transfer of tokens. This includes
minting and burning.

Calling conditions:

- when `from` and `to` are both non-zero, `amount` of `from`'s tokens
  has been transferred to `to`.
- when `from` is zero, `amount` tokens have been minted for `to`.
- when `to` is zero, `amount` of `from`'s tokens have been burned.
- `from` and `to` are never both zero.

To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].\_

## ERC20Permit

\_Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].

Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
need to send a transaction, and thus is not required to hold Ether at all.

\_Available since v3.4.\_\_

### constructor

```solidity
constructor(string name) internal
```

\_Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.

It's a good idea to use the same `name` that is defined as the ERC20 token name.\_

### permit

```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual
```

_See {IERC20Permit-permit}._

### nonces

```solidity
function nonces(address owner) public view virtual returns (uint256)
```

_See {IERC20Permit-nonces}._

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() external view returns (bytes32)
```

_See {IERC20Permit-DOMAIN_SEPARATOR}._

### \_useNonce

```solidity
function _useNonce(address owner) internal virtual returns (uint256 current)
```

\_"Consume a nonce": return the current value and increment.

\_Available since v4.1.\_\_

## IERC20Metadata

\_Interface for the optional metadata functions from the ERC20 standard.

\_Available since v4.1.\_\_

### name

```solidity
function name() external view returns (string)
```

_Returns the name of the token._

### symbol

```solidity
function symbol() external view returns (string)
```

_Returns the symbol of the token._

### decimals

```solidity
function decimals() external view returns (uint8)
```

_Returns the decimals places of the token._

## IERC20Permit

\_Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].

Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
need to send a transaction, and thus is not required to hold Ether at all.\_

### permit

```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
```

\_Sets `value` as the allowance of `spender` over `owner`'s tokens,
given `owner`'s signed approval.

IMPORTANT: The same issues {IERC20-approve} has related to transaction
ordering also apply here.

Emits an {Approval} event.

Requirements:

- `spender` cannot be the zero address.
- `deadline` must be a timestamp in the future.
- `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
  over the EIP712-formatted function arguments.
- the signature must use `owner`'s current nonce (see {nonces}).

For more information on the signature format, see the
https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
section].\_

### nonces

```solidity
function nonces(address owner) external view returns (uint256)
```

\_Returns the current nonce for `owner`. This value must be
included whenever a signature is generated for {permit}.

Every successful call to {permit} increases `owner`'s nonce by one. This
prevents a signature from being used multiple times.\_

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() external view returns (bytes32)
```

_Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}._

## SafeERC20

_Wrappers around ERC20 operations that throw on failure (when the token
contract returns false). Tokens that return no value (and instead revert or
throw on failure) are also supported, non-reverting calls are assumed to be
successful.
To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
which allows you to call the safe operations as `token.safeTransfer(...)`, etc._

### safeTransfer

```solidity
function safeTransfer(contract IERC20 token, address to, uint256 value) internal
```

_Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
non-reverting calls are assumed to be successful._

### safeTransferFrom

```solidity
function safeTransferFrom(contract IERC20 token, address from, address to, uint256 value) internal
```

_Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
calling contract. If `token` returns no value, non-reverting calls are assumed to be successful._

### safeApprove

```solidity
function safeApprove(contract IERC20 token, address spender, uint256 value) internal
```

\_Deprecated. This function has issues similar to the ones found in
{IERC20-approve}, and its usage is discouraged.

Whenever possible, use {safeIncreaseAllowance} and
{safeDecreaseAllowance} instead.\_

### safeIncreaseAllowance

```solidity
function safeIncreaseAllowance(contract IERC20 token, address spender, uint256 value) internal
```

_Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
non-reverting calls are assumed to be successful._

### safeDecreaseAllowance

```solidity
function safeDecreaseAllowance(contract IERC20 token, address spender, uint256 value) internal
```

_Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
non-reverting calls are assumed to be successful._

### forceApprove

```solidity
function forceApprove(contract IERC20 token, address spender, uint256 value) internal
```

_Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
0 before setting it to a non-zero value._

### safePermit

```solidity
function safePermit(contract IERC20Permit token, address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) internal
```

_Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
Revert on invalid signature._

## ERC721

_Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
the Metadata extension, but not including the Enumerable extension, which is available separately as
{ERC721Enumerable}._

### constructor

```solidity
constructor(string name_, string symbol_) public
```

_Initializes the contract by setting a `name` and a `symbol` to the token collection._

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### balanceOf

```solidity
function balanceOf(address owner) public view virtual returns (uint256)
```

_See {IERC721-balanceOf}._

### ownerOf

```solidity
function ownerOf(uint256 tokenId) public view virtual returns (address)
```

_See {IERC721-ownerOf}._

### name

```solidity
function name() public view virtual returns (string)
```

_See {IERC721Metadata-name}._

### symbol

```solidity
function symbol() public view virtual returns (string)
```

_See {IERC721Metadata-symbol}._

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view virtual returns (string)
```

_See {IERC721Metadata-tokenURI}._

### \_baseURI

```solidity
function _baseURI() internal view virtual returns (string)
```

_Base URI for computing {tokenURI}. If set, the resulting URI for each
token will be the concatenation of the `baseURI` and the `tokenId`. Empty
by default, can be overridden in child contracts._

### approve

```solidity
function approve(address to, uint256 tokenId) public virtual
```

_See {IERC721-approve}._

### getApproved

```solidity
function getApproved(uint256 tokenId) public view virtual returns (address)
```

_See {IERC721-getApproved}._

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) public virtual
```

_See {IERC721-setApprovalForAll}._

### isApprovedForAll

```solidity
function isApprovedForAll(address owner, address operator) public view virtual returns (bool)
```

_See {IERC721-isApprovedForAll}._

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 tokenId) public virtual
```

_See {IERC721-transferFrom}._

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) public virtual
```

_See {IERC721-safeTransferFrom}._

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public virtual
```

_See {IERC721-safeTransferFrom}._

### \_safeTransfer

```solidity
function _safeTransfer(address from, address to, uint256 tokenId, bytes data) internal virtual
```

\_Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
are aware of the ERC721 protocol to prevent tokens from being forever locked.

`data` is additional data, it has no specified format and it is sent in call to `to`.

This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
implement alternative mechanisms to perform token transfer, such as signature-based.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must exist and be owned by `from`.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event.\_

### \_ownerOf

```solidity
function _ownerOf(uint256 tokenId) internal view virtual returns (address)
```

_Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist_

### \_exists

```solidity
function _exists(uint256 tokenId) internal view virtual returns (bool)
```

\_Returns whether `tokenId` exists.

Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.

Tokens start existing when they are minted (`_mint`),
and stop existing when they are burned (`_burn`).\_

### \_isApprovedOrOwner

```solidity
function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool)
```

\_Returns whether `spender` is allowed to manage `tokenId`.

Requirements:

- `tokenId` must exist.\_

### \_safeMint

```solidity
function _safeMint(address to, uint256 tokenId) internal virtual
```

\_Safely mints `tokenId` and transfers it to `to`.

Requirements:

- `tokenId` must not exist.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event.\_

### \_safeMint

```solidity
function _safeMint(address to, uint256 tokenId, bytes data) internal virtual
```

_Same as {xref-ERC721-\_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
forwarded in {IERC721Receiver-onERC721Received} to contract recipients._

### \_mint

```solidity
function _mint(address to, uint256 tokenId) internal virtual
```

\_Mints `tokenId` and transfers it to `to`.

WARNING: Usage of this method is discouraged, use {\_safeMint} whenever possible

Requirements:

- `tokenId` must not exist.
- `to` cannot be the zero address.

Emits a {Transfer} event.\_

### \_burn

```solidity
function _burn(uint256 tokenId) internal virtual
```

\_Destroys `tokenId`.
The approval is cleared when the token is burned.
This is an internal function that does not check if the sender is authorized to operate on the token.

Requirements:

- `tokenId` must exist.

Emits a {Transfer} event.\_

### \_transfer

```solidity
function _transfer(address from, address to, uint256 tokenId) internal virtual
```

\_Transfers `tokenId` from `from` to `to`.
As opposed to {transferFrom}, this imposes no restrictions on msg.sender.

Requirements:

- `to` cannot be the zero address.
- `tokenId` token must be owned by `from`.

Emits a {Transfer} event.\_

### \_approve

```solidity
function _approve(address to, uint256 tokenId) internal virtual
```

\_Approve `to` to operate on `tokenId`

Emits an {Approval} event.\_

### \_setApprovalForAll

```solidity
function _setApprovalForAll(address owner, address operator, bool approved) internal virtual
```

\_Approve `operator` to operate on all of `owner` tokens

Emits an {ApprovalForAll} event.\_

### \_requireMinted

```solidity
function _requireMinted(uint256 tokenId) internal view virtual
```

_Reverts if the `tokenId` has not been minted yet._

### \_beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual
```

\_Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.

Calling conditions:

- When `from` and `to` are both non-zero, `from`'s tokens will be transferred to `to`.
- When `from` is zero, the tokens will be minted for `to`.
- When `to` is zero, `from`'s tokens will be burned.
- `from` and `to` are never both zero.
- `batchSize` is non-zero.

To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].\_

### \_afterTokenTransfer

```solidity
function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual
```

\_Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.

Calling conditions:

- When `from` and `to` are both non-zero, `from`'s tokens were transferred to `to`.
- When `from` is zero, the tokens were minted for `to`.
- When `to` is zero, `from`'s tokens were burned.
- `from` and `to` are never both zero.
- `batchSize` is non-zero.

To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].\_

### \_\_unsafe_increaseBalance

```solidity
function __unsafe_increaseBalance(address account, uint256 amount) internal
```

\_Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.

WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
that `ownerOf(tokenId)` is `a`.\_

## IERC721

_Required interface of an ERC721 compliant contract._

### Transfer

```solidity
event Transfer(address from, address to, uint256 tokenId)
```

_Emitted when `tokenId` token is transferred from `from` to `to`._

### Approval

```solidity
event Approval(address owner, address approved, uint256 tokenId)
```

_Emitted when `owner` enables `approved` to manage the `tokenId` token._

### ApprovalForAll

```solidity
event ApprovalForAll(address owner, address operator, bool approved)
```

_Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets._

### balanceOf

```solidity
function balanceOf(address owner) external view returns (uint256 balance)
```

_Returns the number of tokens in `owner`'s account._

### ownerOf

```solidity
function ownerOf(uint256 tokenId) external view returns (address owner)
```

\_Returns the owner of the `tokenId` token.

Requirements:

- `tokenId` must exist.\_

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external
```

\_Safely transfers `tokenId` token from `from` to `to`.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must exist and be owned by `from`.
- If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event.\_

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) external
```

\_Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
are aware of the ERC721 protocol to prevent tokens from being forever locked.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must exist and be owned by `from`.
- If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
- If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

Emits a {Transfer} event.\_

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 tokenId) external
```

\_Transfers `tokenId` token from `from` to `to`.

WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
understand this adds an external call which potentially creates a reentrancy vulnerability.

Requirements:

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must be owned by `from`.
- If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.

Emits a {Transfer} event.\_

### approve

```solidity
function approve(address to, uint256 tokenId) external
```

\_Gives permission to `to` to transfer `tokenId` token to another account.
The approval is cleared when the token is transferred.

Only a single account can be approved at a time, so approving the zero address clears previous approvals.

Requirements:

- The caller must own the token or be an approved operator.
- `tokenId` must exist.

Emits an {Approval} event.\_

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external
```

\_Approve or remove `operator` as an operator for the caller.
Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.

Requirements:

- The `operator` cannot be the caller.

Emits an {ApprovalForAll} event.\_

### getApproved

```solidity
function getApproved(uint256 tokenId) external view returns (address operator)
```

\_Returns the account approved for `tokenId` token.

Requirements:

- `tokenId` must exist.\_

### isApprovedForAll

```solidity
function isApprovedForAll(address owner, address operator) external view returns (bool)
```

\_Returns if the `operator` is allowed to manage all of the assets of `owner`.

See {setApprovalForAll}\_

## IERC721Receiver

_Interface for any contract that wants to support safeTransfers
from ERC721 asset contracts._

### onERC721Received

```solidity
function onERC721Received(address operator, address from, uint256 tokenId, bytes data) external returns (bytes4)
```

\_Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
by `operator` from `from`, this function is called.

It must return its Solidity selector to confirm the token transfer.
If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.

The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.\_

## IERC721Metadata

_See https://eips.ethereum.org/EIPS/eip-721_

### name

```solidity
function name() external view returns (string)
```

_Returns the token collection name._

### symbol

```solidity
function symbol() external view returns (string)
```

_Returns the token collection symbol._

### tokenURI

```solidity
function tokenURI(uint256 tokenId) external view returns (string)
```

_Returns the Uniform Resource Identifier (URI) for `tokenId` token._

## Address

_Collection of functions related to the address type_

### isContract

```solidity
function isContract(address account) internal view returns (bool)
```

\_Returns true if `account` is a contract.

# [IMPORTANT]

It is unsafe to assume that an address for which this function returns
false is an externally-owned account (EOA) and not a contract.

Among others, `isContract` will return false for the following
types of addresses:

- an externally-owned account
- a contract in construction
- an address where a contract will be created
- an address where a contract lived, but was destroyed

Furthermore, `isContract` will also return true if the target contract within
the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
which only has an effect at the end of a transaction.
====

# [IMPORTANT]

You shouldn't rely on `isContract` to protect against flash loan attacks!

Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
constructor.
====\_

### sendValue

```solidity
function sendValue(address payable recipient, uint256 amount) internal
```

\_Replacement for Solidity's `transfer`: sends `amount` wei to
`recipient`, forwarding all available gas and reverting on errors.

https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
of certain opcodes, possibly making contracts go over the 2300 gas limit
imposed by `transfer`, making them unable to receive funds via
`transfer`. {sendValue} removes this limitation.

https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].

IMPORTANT: because control is transferred to `recipient`, care must be
taken to not create reentrancy vulnerabilities. Consider using
{ReentrancyGuard} or the
https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].\_

### functionCall

```solidity
function functionCall(address target, bytes data) internal returns (bytes)
```

\_Performs a Solidity function call using a low level `call`. A
plain `call` is an unsafe replacement for a function call: use this
function instead.

If `target` reverts with a revert reason, it is bubbled up by this
function (like regular Solidity function calls).

Returns the raw returned data. To convert to the expected return value,
use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].

Requirements:

- `target` must be a contract.
- calling `target` with `data` must not revert.

\_Available since v3.1.\_\_

### functionCall

```solidity
function functionCall(address target, bytes data, string errorMessage) internal returns (bytes)
```

\_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
`errorMessage` as a fallback revert reason when `target` reverts.

\_Available since v3.1.\_\_

### functionCallWithValue

```solidity
function functionCallWithValue(address target, bytes data, uint256 value) internal returns (bytes)
```

\_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but also transferring `value` wei to `target`.

Requirements:

- the calling contract must have an ETH balance of at least `value`.
- the called Solidity function must be `payable`.

\_Available since v3.1.\_\_

### functionCallWithValue

```solidity
function functionCallWithValue(address target, bytes data, uint256 value, string errorMessage) internal returns (bytes)
```

\_Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
with `errorMessage` as a fallback revert reason when `target` reverts.

\_Available since v3.1.\_\_

### functionStaticCall

```solidity
function functionStaticCall(address target, bytes data) internal view returns (bytes)
```

\_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a static call.

\_Available since v3.3.\_\_

### functionStaticCall

```solidity
function functionStaticCall(address target, bytes data, string errorMessage) internal view returns (bytes)
```

\_Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
but performing a static call.

\_Available since v3.3.\_\_

### functionDelegateCall

```solidity
function functionDelegateCall(address target, bytes data) internal returns (bytes)
```

\_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a delegate call.

\_Available since v3.4.\_\_

### functionDelegateCall

```solidity
function functionDelegateCall(address target, bytes data, string errorMessage) internal returns (bytes)
```

\_Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
but performing a delegate call.

\_Available since v3.4.\_\_

### verifyCallResultFromTarget

```solidity
function verifyCallResultFromTarget(address target, bool success, bytes returndata, string errorMessage) internal view returns (bytes)
```

\_Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.

\_Available since v4.8.\_\_

### verifyCallResult

```solidity
function verifyCallResult(bool success, bytes returndata, string errorMessage) internal pure returns (bytes)
```

\_Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
revert reason or using the provided one.

\_Available since v4.3.\_\_

## Base64

\_Provides a set of functions to operate with Base64 strings.

\_Available since v4.5.\_\_

### \_TABLE

```solidity
string _TABLE
```

_Base64 Encoding/Decoding Table_

### encode

```solidity
function encode(bytes data) internal pure returns (string)
```

_Converts a `bytes` to its Bytes64 `string` representation._

## Checkpoints

\_This library defines the `History` struct, for checkpointing values as they change at different points in
time, and later looking up past values by block number. See {Votes} as an example.

To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
checkpoint for the current transaction block using the {push} function.

\_Available since v4.5.\_\_

### History

```solidity
struct History {
  struct Checkpoints.Checkpoint[] _checkpoints;
}
```

### Checkpoint

```solidity
struct Checkpoint {
  uint32 _blockNumber;
  uint224 _value;
}
```

### getAtBlock

```solidity
function getAtBlock(struct Checkpoints.History self, uint256 blockNumber) internal view returns (uint256)
```

_Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
before it is returned, or zero otherwise. Because the number returned corresponds to that at the end of the
block, the requested block number must be in the past, excluding the current block._

### getAtProbablyRecentBlock

```solidity
function getAtProbablyRecentBlock(struct Checkpoints.History self, uint256 blockNumber) internal view returns (uint256)
```

_Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
checkpoints._

### push

```solidity
function push(struct Checkpoints.History self, uint256 value) internal returns (uint256, uint256)
```

\_Pushes a value onto a History so that it is stored as the checkpoint for the current block.

Returns previous value and new value.\_

### push

```solidity
function push(struct Checkpoints.History self, function (uint256,uint256) view returns (uint256) op, uint256 delta) internal returns (uint256, uint256)
```

\_Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
be set to `op(latest, delta)`.

Returns previous value and new value.\_

### latest

```solidity
function latest(struct Checkpoints.History self) internal view returns (uint224)
```

_Returns the value in the most recent checkpoint, or zero if there are no checkpoints._

### latestCheckpoint

```solidity
function latestCheckpoint(struct Checkpoints.History self) internal view returns (bool exists, uint32 _blockNumber, uint224 _value)
```

_Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
in the most recent checkpoint._

### length

```solidity
function length(struct Checkpoints.History self) internal view returns (uint256)
```

_Returns the number of checkpoint._

### Trace224

```solidity
struct Trace224 {
  struct Checkpoints.Checkpoint224[] _checkpoints;
}
```

### Checkpoint224

```solidity
struct Checkpoint224 {
  uint32 _key;
  uint224 _value;
}
```

### push

```solidity
function push(struct Checkpoints.Trace224 self, uint32 key, uint224 value) internal returns (uint224, uint224)
```

\_Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.

Returns previous value and new value.\_

### lowerLookup

```solidity
function lowerLookup(struct Checkpoints.Trace224 self, uint32 key) internal view returns (uint224)
```

_Returns the value in the first (oldest) checkpoint with key greater or equal than the search key, or zero if there is none._

### upperLookup

```solidity
function upperLookup(struct Checkpoints.Trace224 self, uint32 key) internal view returns (uint224)
```

_Returns the value in the last (most recent) checkpoint with key lower or equal than the search key, or zero if there is none._

### upperLookupRecent

```solidity
function upperLookupRecent(struct Checkpoints.Trace224 self, uint32 key) internal view returns (uint224)
```

\_Returns the value in the last (most recent) checkpoint with key lower or equal than the search key, or zero if there is none.

NOTE: This is a variant of {upperLookup} that is optimised to find "recent" checkpoint (checkpoints with high keys).\_

### latest

```solidity
function latest(struct Checkpoints.Trace224 self) internal view returns (uint224)
```

_Returns the value in the most recent checkpoint, or zero if there are no checkpoints._

### latestCheckpoint

```solidity
function latestCheckpoint(struct Checkpoints.Trace224 self) internal view returns (bool exists, uint32 _key, uint224 _value)
```

_Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
in the most recent checkpoint._

### length

```solidity
function length(struct Checkpoints.Trace224 self) internal view returns (uint256)
```

_Returns the number of checkpoint._

### Trace160

```solidity
struct Trace160 {
  struct Checkpoints.Checkpoint160[] _checkpoints;
}
```

### Checkpoint160

```solidity
struct Checkpoint160 {
  uint96 _key;
  uint160 _value;
}
```

### push

```solidity
function push(struct Checkpoints.Trace160 self, uint96 key, uint160 value) internal returns (uint160, uint160)
```

\_Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.

Returns previous value and new value.\_

### lowerLookup

```solidity
function lowerLookup(struct Checkpoints.Trace160 self, uint96 key) internal view returns (uint160)
```

_Returns the value in the first (oldest) checkpoint with key greater or equal than the search key, or zero if there is none._

### upperLookup

```solidity
function upperLookup(struct Checkpoints.Trace160 self, uint96 key) internal view returns (uint160)
```

_Returns the value in the last (most recent) checkpoint with key lower or equal than the search key, or zero if there is none._

### upperLookupRecent

```solidity
function upperLookupRecent(struct Checkpoints.Trace160 self, uint96 key) internal view returns (uint160)
```

\_Returns the value in the last (most recent) checkpoint with key lower or equal than the search key, or zero if there is none.

NOTE: This is a variant of {upperLookup} that is optimised to find "recent" checkpoint (checkpoints with high keys).\_

### latest

```solidity
function latest(struct Checkpoints.Trace160 self) internal view returns (uint160)
```

_Returns the value in the most recent checkpoint, or zero if there are no checkpoints._

### latestCheckpoint

```solidity
function latestCheckpoint(struct Checkpoints.Trace160 self) internal view returns (bool exists, uint96 _key, uint160 _value)
```

_Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
in the most recent checkpoint._

### length

```solidity
function length(struct Checkpoints.Trace160 self) internal view returns (uint256)
```

_Returns the number of checkpoint._

## Context

\_Provides information about the current execution context, including the
sender of the transaction and its data. While these are generally available
via msg.sender and msg.data, they should not be accessed in such a direct
manner, since when dealing with meta-transactions the account sending and
paying for execution may not be the actual sender (as far as an application
is concerned).

This contract is only required for intermediate, library-like contracts.\_

### \_msgSender

```solidity
function _msgSender() internal view virtual returns (address)
```

### \_msgData

```solidity
function _msgData() internal view virtual returns (bytes)
```

## Counters

\_Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
of elements in a mapping, issuing ERC721 ids, or counting request ids.

Include with `using Counters for Counters.Counter;`\_

### Counter

```solidity
struct Counter {
  uint256 _value;
}
```

### current

```solidity
function current(struct Counters.Counter counter) internal view returns (uint256)
```

### increment

```solidity
function increment(struct Counters.Counter counter) internal
```

### decrement

```solidity
function decrement(struct Counters.Counter counter) internal
```

### reset

```solidity
function reset(struct Counters.Counter counter) internal
```

## Create2

\_Helper to make usage of the `CREATE2` EVM opcode easier and safer.
`CREATE2` can be used to compute in advance the address where a smart
contract will be deployed, which allows for interesting new mechanisms known
as 'counterfactual interactions'.

See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
information.\_

### deploy

```solidity
function deploy(uint256 amount, bytes32 salt, bytes bytecode) internal returns (address addr)
```

\_Deploys a contract using `CREATE2`. The address where the contract
will be deployed can be known in advance via {computeAddress}.

The bytecode for a contract can be obtained from Solidity with
`type(contractName).creationCode`.

Requirements:

- `bytecode` must not be empty.
- `salt` must have not been used for `bytecode` already.
- the factory must have a balance of at least `amount`.
- if `amount` is non-zero, `bytecode` must have a `payable` constructor.\_

### computeAddress

```solidity
function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address)
```

_Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
`bytecodeHash` or `salt` will result in a new destination address._

### computeAddress

```solidity
function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr)
```

_Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
`deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}._

## ShortString

## ShortStrings

\_This library provides functions to convert short memory strings
into a `ShortString` type that can be used as an immutable variable.

Strings of arbitrary length can be optimized using this library if
they are short enough (up to 31 bytes) by packing them with their
length (1 byte) in a single EVM word (32 bytes). Additionally, a
fallback mechanism can be used for every other case.

Usage example:

````solidity
contract Named {
    using ShortStrings for *;

    ShortString private immutable _name;
    string private _nameFallback;

    constructor(string memory contractName) {
        _name = contractName.toShortStringWithFallback(_nameFallback);
    }

    function name() external view returns (string memory) {
        return _name.toStringWithFallback(_nameFallback);
    }
}
```_

### StringTooLong

```solidity
error StringTooLong(string str)
````

### InvalidShortString

```solidity
error InvalidShortString()
```

### toShortString

```solidity
function toShortString(string str) internal pure returns (ShortString)
```

\_Encode a string of at most 31 chars into a `ShortString`.

This will trigger a `StringTooLong` error is the input string is too long.\_

### toString

```solidity
function toString(ShortString sstr) internal pure returns (string)
```

_Decode a `ShortString` back to a "normal" string._

### byteLength

```solidity
function byteLength(ShortString sstr) internal pure returns (uint256)
```

_Return the length of a `ShortString`._

### toShortStringWithFallback

```solidity
function toShortStringWithFallback(string value, string store) internal returns (ShortString)
```

_Encode a string into a `ShortString`, or write it to storage if it is too long._

### toStringWithFallback

```solidity
function toStringWithFallback(ShortString value, string store) internal pure returns (string)
```

_Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}._

### byteLengthWithFallback

```solidity
function byteLengthWithFallback(ShortString value, string store) internal view returns (uint256)
```

\_Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.

WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
actual characters as the UTF-8 encoding of a single character can span over multiple bytes.\_

## StorageSlot

\_Library for reading and writing primitive types to specific storage slots.

Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
This library helps with reading and writing to such slots without the need for inline assembly.

The functions in this library return Slot structs that contain a `value` member that can be used to read or write.

Example usage to set ERC1967 implementation slot:

```solidity
contract ERC1967 {
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address newImplementation) internal {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }
}
```

_Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
\_Available since v4.9 for `string`, `bytes`.\_\_

### AddressSlot

```solidity
struct AddressSlot {
  address value;
}
```

### BooleanSlot

```solidity
struct BooleanSlot {
  bool value;
}
```

### Bytes32Slot

```solidity
struct Bytes32Slot {
  bytes32 value;
}
```

### Uint256Slot

```solidity
struct Uint256Slot {
  uint256 value;
}
```

### StringSlot

```solidity
struct StringSlot {
  string value;
}
```

### BytesSlot

```solidity
struct BytesSlot {
  bytes value;
}
```

### getAddressSlot

```solidity
function getAddressSlot(bytes32 slot) internal pure returns (struct StorageSlot.AddressSlot r)
```

_Returns an `AddressSlot` with member `value` located at `slot`._

### getBooleanSlot

```solidity
function getBooleanSlot(bytes32 slot) internal pure returns (struct StorageSlot.BooleanSlot r)
```

_Returns an `BooleanSlot` with member `value` located at `slot`._

### getBytes32Slot

```solidity
function getBytes32Slot(bytes32 slot) internal pure returns (struct StorageSlot.Bytes32Slot r)
```

_Returns an `Bytes32Slot` with member `value` located at `slot`._

### getUint256Slot

```solidity
function getUint256Slot(bytes32 slot) internal pure returns (struct StorageSlot.Uint256Slot r)
```

_Returns an `Uint256Slot` with member `value` located at `slot`._

### getStringSlot

```solidity
function getStringSlot(bytes32 slot) internal pure returns (struct StorageSlot.StringSlot r)
```

_Returns an `StringSlot` with member `value` located at `slot`._

### getStringSlot

```solidity
function getStringSlot(string store) internal pure returns (struct StorageSlot.StringSlot r)
```

_Returns an `StringSlot` representation of the string storage pointer `store`._

### getBytesSlot

```solidity
function getBytesSlot(bytes32 slot) internal pure returns (struct StorageSlot.BytesSlot r)
```

_Returns an `BytesSlot` with member `value` located at `slot`._

### getBytesSlot

```solidity
function getBytesSlot(bytes store) internal pure returns (struct StorageSlot.BytesSlot r)
```

_Returns an `BytesSlot` representation of the bytes storage pointer `store`._

## Strings

_String operations._

### toString

```solidity
function toString(uint256 value) internal pure returns (string)
```

_Converts a `uint256` to its ASCII `string` decimal representation._

### toString

```solidity
function toString(int256 value) internal pure returns (string)
```

_Converts a `int256` to its ASCII `string` decimal representation._

### toHexString

```solidity
function toHexString(uint256 value) internal pure returns (string)
```

_Converts a `uint256` to its ASCII `string` hexadecimal representation._

### toHexString

```solidity
function toHexString(uint256 value, uint256 length) internal pure returns (string)
```

_Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length._

### toHexString

```solidity
function toHexString(address addr) internal pure returns (string)
```

_Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation._

### equal

```solidity
function equal(string a, string b) internal pure returns (bool)
```

_Returns true if the two strings are equal._

## ECDSA

\_Elliptic Curve Digital Signature Algorithm (ECDSA) operations.

These functions can be used to verify that a message was signed by the holder
of the private keys of a given address.\_

### RecoverError

```solidity
enum RecoverError {
  NoError,
  InvalidSignature,
  InvalidSignatureLength,
  InvalidSignatureS,
  InvalidSignatureV
}
```

### tryRecover

```solidity
function tryRecover(bytes32 hash, bytes signature) internal pure returns (address, enum ECDSA.RecoverError)
```

\_Returns the address that signed a hashed message (`hash`) with
`signature` or error string. This address can then be used for verification purposes.

The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
this function rejects them by requiring the `s` value to be in the lower
half order, and the `v` value to be either 27 or 28.

IMPORTANT: `hash` _must_ be the result of a hash operation for the
verification to be secure: it is possible to craft signatures that
recover to arbitrary addresses for non-hashed data. A safe way to ensure
this is by receiving a hash of the original message (which may otherwise
be too long), and then calling {toEthSignedMessageHash} on it.

Documentation for signature generation:

- with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
- with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]

\_Available since v4.3.\_\_

### recover

```solidity
function recover(bytes32 hash, bytes signature) internal pure returns (address)
```

\_Returns the address that signed a hashed message (`hash`) with
`signature`. This address can then be used for verification purposes.

The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
this function rejects them by requiring the `s` value to be in the lower
half order, and the `v` value to be either 27 or 28.

IMPORTANT: `hash` _must_ be the result of a hash operation for the
verification to be secure: it is possible to craft signatures that
recover to arbitrary addresses for non-hashed data. A safe way to ensure
this is by receiving a hash of the original message (which may otherwise
be too long), and then calling {toEthSignedMessageHash} on it.\_

### tryRecover

```solidity
function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, enum ECDSA.RecoverError)
```

\_Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.

See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]

\_Available since v4.3.\_\_

### recover

```solidity
function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address)
```

\_Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.

\_Available since v4.2.\_\_

### tryRecover

```solidity
function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, enum ECDSA.RecoverError)
```

\_Overload of {ECDSA-tryRecover} that receives the `v`,
`r` and `s` signature fields separately.

\_Available since v4.3.\_\_

### recover

```solidity
function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address)
```

_Overload of {ECDSA-recover} that receives the `v`,
`r` and `s` signature fields separately._

### toEthSignedMessageHash

```solidity
function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message)
```

\_Returns an Ethereum Signed Message, created from a `hash`. This
produces hash corresponding to the one signed with the
https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
JSON-RPC method as part of EIP-191.

See {recover}.\_

### toEthSignedMessageHash

```solidity
function toEthSignedMessageHash(bytes s) internal pure returns (bytes32)
```

\_Returns an Ethereum Signed Message, created from `s`. This
produces hash corresponding to the one signed with the
https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
JSON-RPC method as part of EIP-191.

See {recover}.\_

### toTypedDataHash

```solidity
function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data)
```

\_Returns an Ethereum Signed Typed Data, created from a
`domainSeparator` and a `structHash`. This produces hash corresponding
to the one signed with the
https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
JSON-RPC method as part of EIP-712.

See {recover}.\_

### toDataWithIntendedValidatorHash

```solidity
function toDataWithIntendedValidatorHash(address validator, bytes data) internal pure returns (bytes32)
```

\_Returns an Ethereum Signed Data with intended validator, created from a
`validator` and `data` according to the version 0 of EIP-191.

See {recover}.\_

## EIP712

\_https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.

The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
they need in their contracts using a combination of `abi.encode` and `keccak256`.

This contract implements the EIP 712 domain separator ({\_domainSeparatorV4}) that is used as part of the encoding
scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
({\_hashTypedDataV4}).

The implementation of the domain separator was designed to be as efficient as possible while still properly updating
the chain id to protect against replay attacks on an eventual fork of the chain.

NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].

NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
separator from the immutable values, which is cheaper than accessing a cached version in cold storage.

\_Available since v3.4.\_\_

### constructor

```solidity
constructor(string name, string version) internal
```

\_Initializes the domain separator and parameter caches.

The meaning of `name` and `version` is specified in
https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:

- `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
- `version`: the current major version of the signing domain.

NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
contract upgrade].\_

### \_domainSeparatorV4

```solidity
function _domainSeparatorV4() internal view returns (bytes32)
```

_Returns the domain separator for the current chain._

### \_hashTypedDataV4

```solidity
function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32)
```

\_Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
function returns the hash of the fully encoded EIP712 message for this domain.

This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:

````solidity
bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
    keccak256("Mail(address to,string contents)"),
    mailTo,
    keccak256(bytes(mailContents))
)));
address signer = ECDSA.recover(digest, signature);
```_

### eip712Domain

```solidity
function eip712Domain() public view virtual returns (bytes1 fields, string name, string version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] extensions)
````

\_See {EIP-5267}.

\_Available since v4.9.\_\_

## MerkleProof

\_These functions deal with verification of Merkle Tree proofs.

The tree and the proofs can be generated using our
https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
You will find a quickstart guide in the readme.

WARNING: You should avoid using leaf values that are 64 bytes long prior to
hashing, or use a hash function other than keccak256 for hashing leaves.
This is because the concatenation of a sorted pair of internal nodes in
the merkle tree could be reinterpreted as a leaf value.
OpenZeppelin's JavaScript library generates merkle trees that are safe
against this attack out of the box.\_

### verify

```solidity
function verify(bytes32[] proof, bytes32 root, bytes32 leaf) internal pure returns (bool)
```

_Returns true if a `leaf` can be proved to be a part of a Merkle tree
defined by `root`. For this, a `proof` must be provided, containing
sibling hashes on the branch from the leaf to the root of the tree. Each
pair of leaves and each pair of pre-images are assumed to be sorted._

### verifyCalldata

```solidity
function verifyCalldata(bytes32[] proof, bytes32 root, bytes32 leaf) internal pure returns (bool)
```

\_Calldata version of {verify}

\_Available since v4.7.\_\_

### processProof

```solidity
function processProof(bytes32[] proof, bytes32 leaf) internal pure returns (bytes32)
```

\_Returns the rebuilt hash obtained by traversing a Merkle tree up
from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
hash matches the root of the tree. When processing the proof, the pairs
of leafs & pre-images are assumed to be sorted.

\_Available since v4.4.\_\_

### processProofCalldata

```solidity
function processProofCalldata(bytes32[] proof, bytes32 leaf) internal pure returns (bytes32)
```

\_Calldata version of {processProof}

\_Available since v4.7.\_\_

### multiProofVerify

```solidity
function multiProofVerify(bytes32[] proof, bool[] proofFlags, bytes32 root, bytes32[] leaves) internal pure returns (bool)
```

\_Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
`root`, according to `proof` and `proofFlags` as described in {processMultiProof}.

CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.

\_Available since v4.7.\_\_

### multiProofVerifyCalldata

```solidity
function multiProofVerifyCalldata(bytes32[] proof, bool[] proofFlags, bytes32 root, bytes32[] leaves) internal pure returns (bool)
```

\_Calldata version of {multiProofVerify}

CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.

\_Available since v4.7.\_\_

### processMultiProof

```solidity
function processMultiProof(bytes32[] proof, bool[] proofFlags, bytes32[] leaves) internal pure returns (bytes32 merkleRoot)
```

\_Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
respectively.

CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).

\_Available since v4.7.\_\_

### processMultiProofCalldata

```solidity
function processMultiProofCalldata(bytes32[] proof, bool[] proofFlags, bytes32[] leaves) internal pure returns (bytes32 merkleRoot)
```

\_Calldata version of {processMultiProof}.

CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.

\_Available since v4.7.\_\_

## ERC165

\_Implementation of the {IERC165} interface.

Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
for the additional interface id that will be supported. For example:

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
}
```

Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.\_

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

## IERC165

\_Interface of the ERC165 standard, as defined in the
https://eips.ethereum.org/EIPS/eip-165[EIP].

Implementers can declare support of contract interfaces, which can then be
queried by others ({ERC165Checker}).

For an implementation, see {ERC165}.\_

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

\_Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
to learn more about how these ids are created.

This function call must use less than 30 000 gas.\_

## Math

_Standard math utilities missing in the Solidity language._

### Rounding

```solidity
enum Rounding {
  Down,
  Up,
  Zero
}
```

### max

```solidity
function max(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the largest of two numbers._

### min

```solidity
function min(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the smallest of two numbers._

### average

```solidity
function average(uint256 a, uint256 b) internal pure returns (uint256)
```

_Returns the average of two numbers. The result is rounded towards
zero._

### ceilDiv

```solidity
function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256)
```

\_Returns the ceiling of the division of two numbers.

This differs from standard division with `/` in that it rounds up instead
of rounding down.\_

### mulDiv

```solidity
function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result)
```

Calculates floor(x \* y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0

_Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
with further edits by Uniswap Labs also under MIT license._

### mulDiv

```solidity
function mulDiv(uint256 x, uint256 y, uint256 denominator, enum Math.Rounding rounding) internal pure returns (uint256)
```

Calculates x \* y / denominator with full precision, following the selected rounding direction.

### sqrt

```solidity
function sqrt(uint256 a) internal pure returns (uint256)
```

\_Returns the square root of a number. If the number is not a perfect square, the value is rounded down.

Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).\_

### sqrt

```solidity
function sqrt(uint256 a, enum Math.Rounding rounding) internal pure returns (uint256)
```

Calculates sqrt(a), following the selected rounding direction.

### log2

```solidity
function log2(uint256 value) internal pure returns (uint256)
```

_Return the log in base 2, rounded down, of a positive value.
Returns 0 if given 0._

### log2

```solidity
function log2(uint256 value, enum Math.Rounding rounding) internal pure returns (uint256)
```

_Return the log in base 2, following the selected rounding direction, of a positive value.
Returns 0 if given 0._

### log10

```solidity
function log10(uint256 value) internal pure returns (uint256)
```

_Return the log in base 10, rounded down, of a positive value.
Returns 0 if given 0._

### log10

```solidity
function log10(uint256 value, enum Math.Rounding rounding) internal pure returns (uint256)
```

_Return the log in base 10, following the selected rounding direction, of a positive value.
Returns 0 if given 0._

### log256

```solidity
function log256(uint256 value) internal pure returns (uint256)
```

\_Return the log in base 256, rounded down, of a positive value.
Returns 0 if given 0.

Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.\_

### log256

```solidity
function log256(uint256 value, enum Math.Rounding rounding) internal pure returns (uint256)
```

_Return the log in base 256, following the selected rounding direction, of a positive value.
Returns 0 if given 0._

## SafeCast

\_Wrappers over Solidity's uintXX/intXX casting operators with added overflow
checks.

Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
easily result in undesired exploitation or bugs, since developers usually
assume that overflows raise errors. `SafeCast` restores this intuition by
reverting the transaction when such an operation overflows.

Using this library instead of the unchecked operations eliminates an entire
class of bugs, so it's recommended to use it always.

Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
all math on `uint256` and `int256` and then downcasting.\_

### toUint248

```solidity
function toUint248(uint256 value) internal pure returns (uint248)
```

\_Returns the downcasted uint248 from uint256, reverting on
overflow (when the input is greater than largest uint248).

Counterpart to Solidity's `uint248` operator.

Requirements:

- input must fit into 248 bits

\_Available since v4.7.\_\_

### toUint240

```solidity
function toUint240(uint256 value) internal pure returns (uint240)
```

\_Returns the downcasted uint240 from uint256, reverting on
overflow (when the input is greater than largest uint240).

Counterpart to Solidity's `uint240` operator.

Requirements:

- input must fit into 240 bits

\_Available since v4.7.\_\_

### toUint232

```solidity
function toUint232(uint256 value) internal pure returns (uint232)
```

\_Returns the downcasted uint232 from uint256, reverting on
overflow (when the input is greater than largest uint232).

Counterpart to Solidity's `uint232` operator.

Requirements:

- input must fit into 232 bits

\_Available since v4.7.\_\_

### toUint224

```solidity
function toUint224(uint256 value) internal pure returns (uint224)
```

\_Returns the downcasted uint224 from uint256, reverting on
overflow (when the input is greater than largest uint224).

Counterpart to Solidity's `uint224` operator.

Requirements:

- input must fit into 224 bits

\_Available since v4.2.\_\_

### toUint216

```solidity
function toUint216(uint256 value) internal pure returns (uint216)
```

\_Returns the downcasted uint216 from uint256, reverting on
overflow (when the input is greater than largest uint216).

Counterpart to Solidity's `uint216` operator.

Requirements:

- input must fit into 216 bits

\_Available since v4.7.\_\_

### toUint208

```solidity
function toUint208(uint256 value) internal pure returns (uint208)
```

\_Returns the downcasted uint208 from uint256, reverting on
overflow (when the input is greater than largest uint208).

Counterpart to Solidity's `uint208` operator.

Requirements:

- input must fit into 208 bits

\_Available since v4.7.\_\_

### toUint200

```solidity
function toUint200(uint256 value) internal pure returns (uint200)
```

\_Returns the downcasted uint200 from uint256, reverting on
overflow (when the input is greater than largest uint200).

Counterpart to Solidity's `uint200` operator.

Requirements:

- input must fit into 200 bits

\_Available since v4.7.\_\_

### toUint192

```solidity
function toUint192(uint256 value) internal pure returns (uint192)
```

\_Returns the downcasted uint192 from uint256, reverting on
overflow (when the input is greater than largest uint192).

Counterpart to Solidity's `uint192` operator.

Requirements:

- input must fit into 192 bits

\_Available since v4.7.\_\_

### toUint184

```solidity
function toUint184(uint256 value) internal pure returns (uint184)
```

\_Returns the downcasted uint184 from uint256, reverting on
overflow (when the input is greater than largest uint184).

Counterpart to Solidity's `uint184` operator.

Requirements:

- input must fit into 184 bits

\_Available since v4.7.\_\_

### toUint176

```solidity
function toUint176(uint256 value) internal pure returns (uint176)
```

\_Returns the downcasted uint176 from uint256, reverting on
overflow (when the input is greater than largest uint176).

Counterpart to Solidity's `uint176` operator.

Requirements:

- input must fit into 176 bits

\_Available since v4.7.\_\_

### toUint168

```solidity
function toUint168(uint256 value) internal pure returns (uint168)
```

\_Returns the downcasted uint168 from uint256, reverting on
overflow (when the input is greater than largest uint168).

Counterpart to Solidity's `uint168` operator.

Requirements:

- input must fit into 168 bits

\_Available since v4.7.\_\_

### toUint160

```solidity
function toUint160(uint256 value) internal pure returns (uint160)
```

\_Returns the downcasted uint160 from uint256, reverting on
overflow (when the input is greater than largest uint160).

Counterpart to Solidity's `uint160` operator.

Requirements:

- input must fit into 160 bits

\_Available since v4.7.\_\_

### toUint152

```solidity
function toUint152(uint256 value) internal pure returns (uint152)
```

\_Returns the downcasted uint152 from uint256, reverting on
overflow (when the input is greater than largest uint152).

Counterpart to Solidity's `uint152` operator.

Requirements:

- input must fit into 152 bits

\_Available since v4.7.\_\_

### toUint144

```solidity
function toUint144(uint256 value) internal pure returns (uint144)
```

\_Returns the downcasted uint144 from uint256, reverting on
overflow (when the input is greater than largest uint144).

Counterpart to Solidity's `uint144` operator.

Requirements:

- input must fit into 144 bits

\_Available since v4.7.\_\_

### toUint136

```solidity
function toUint136(uint256 value) internal pure returns (uint136)
```

\_Returns the downcasted uint136 from uint256, reverting on
overflow (when the input is greater than largest uint136).

Counterpart to Solidity's `uint136` operator.

Requirements:

- input must fit into 136 bits

\_Available since v4.7.\_\_

### toUint128

```solidity
function toUint128(uint256 value) internal pure returns (uint128)
```

\_Returns the downcasted uint128 from uint256, reverting on
overflow (when the input is greater than largest uint128).

Counterpart to Solidity's `uint128` operator.

Requirements:

- input must fit into 128 bits

\_Available since v2.5.\_\_

### toUint120

```solidity
function toUint120(uint256 value) internal pure returns (uint120)
```

\_Returns the downcasted uint120 from uint256, reverting on
overflow (when the input is greater than largest uint120).

Counterpart to Solidity's `uint120` operator.

Requirements:

- input must fit into 120 bits

\_Available since v4.7.\_\_

### toUint112

```solidity
function toUint112(uint256 value) internal pure returns (uint112)
```

\_Returns the downcasted uint112 from uint256, reverting on
overflow (when the input is greater than largest uint112).

Counterpart to Solidity's `uint112` operator.

Requirements:

- input must fit into 112 bits

\_Available since v4.7.\_\_

### toUint104

```solidity
function toUint104(uint256 value) internal pure returns (uint104)
```

\_Returns the downcasted uint104 from uint256, reverting on
overflow (when the input is greater than largest uint104).

Counterpart to Solidity's `uint104` operator.

Requirements:

- input must fit into 104 bits

\_Available since v4.7.\_\_

### toUint96

```solidity
function toUint96(uint256 value) internal pure returns (uint96)
```

\_Returns the downcasted uint96 from uint256, reverting on
overflow (when the input is greater than largest uint96).

Counterpart to Solidity's `uint96` operator.

Requirements:

- input must fit into 96 bits

\_Available since v4.2.\_\_

### toUint88

```solidity
function toUint88(uint256 value) internal pure returns (uint88)
```

\_Returns the downcasted uint88 from uint256, reverting on
overflow (when the input is greater than largest uint88).

Counterpart to Solidity's `uint88` operator.

Requirements:

- input must fit into 88 bits

\_Available since v4.7.\_\_

### toUint80

```solidity
function toUint80(uint256 value) internal pure returns (uint80)
```

\_Returns the downcasted uint80 from uint256, reverting on
overflow (when the input is greater than largest uint80).

Counterpart to Solidity's `uint80` operator.

Requirements:

- input must fit into 80 bits

\_Available since v4.7.\_\_

### toUint72

```solidity
function toUint72(uint256 value) internal pure returns (uint72)
```

\_Returns the downcasted uint72 from uint256, reverting on
overflow (when the input is greater than largest uint72).

Counterpart to Solidity's `uint72` operator.

Requirements:

- input must fit into 72 bits

\_Available since v4.7.\_\_

### toUint64

```solidity
function toUint64(uint256 value) internal pure returns (uint64)
```

\_Returns the downcasted uint64 from uint256, reverting on
overflow (when the input is greater than largest uint64).

Counterpart to Solidity's `uint64` operator.

Requirements:

- input must fit into 64 bits

\_Available since v2.5.\_\_

### toUint56

```solidity
function toUint56(uint256 value) internal pure returns (uint56)
```

\_Returns the downcasted uint56 from uint256, reverting on
overflow (when the input is greater than largest uint56).

Counterpart to Solidity's `uint56` operator.

Requirements:

- input must fit into 56 bits

\_Available since v4.7.\_\_

### toUint48

```solidity
function toUint48(uint256 value) internal pure returns (uint48)
```

\_Returns the downcasted uint48 from uint256, reverting on
overflow (when the input is greater than largest uint48).

Counterpart to Solidity's `uint48` operator.

Requirements:

- input must fit into 48 bits

\_Available since v4.7.\_\_

### toUint40

```solidity
function toUint40(uint256 value) internal pure returns (uint40)
```

\_Returns the downcasted uint40 from uint256, reverting on
overflow (when the input is greater than largest uint40).

Counterpart to Solidity's `uint40` operator.

Requirements:

- input must fit into 40 bits

\_Available since v4.7.\_\_

### toUint32

```solidity
function toUint32(uint256 value) internal pure returns (uint32)
```

\_Returns the downcasted uint32 from uint256, reverting on
overflow (when the input is greater than largest uint32).

Counterpart to Solidity's `uint32` operator.

Requirements:

- input must fit into 32 bits

\_Available since v2.5.\_\_

### toUint24

```solidity
function toUint24(uint256 value) internal pure returns (uint24)
```

\_Returns the downcasted uint24 from uint256, reverting on
overflow (when the input is greater than largest uint24).

Counterpart to Solidity's `uint24` operator.

Requirements:

- input must fit into 24 bits

\_Available since v4.7.\_\_

### toUint16

```solidity
function toUint16(uint256 value) internal pure returns (uint16)
```

\_Returns the downcasted uint16 from uint256, reverting on
overflow (when the input is greater than largest uint16).

Counterpart to Solidity's `uint16` operator.

Requirements:

- input must fit into 16 bits

\_Available since v2.5.\_\_

### toUint8

```solidity
function toUint8(uint256 value) internal pure returns (uint8)
```

\_Returns the downcasted uint8 from uint256, reverting on
overflow (when the input is greater than largest uint8).

Counterpart to Solidity's `uint8` operator.

Requirements:

- input must fit into 8 bits

\_Available since v2.5.\_\_

### toUint256

```solidity
function toUint256(int256 value) internal pure returns (uint256)
```

\_Converts a signed int256 into an unsigned uint256.

Requirements:

- input must be greater than or equal to 0.

\_Available since v3.0.\_\_

### toInt248

```solidity
function toInt248(int256 value) internal pure returns (int248 downcasted)
```

\_Returns the downcasted int248 from int256, reverting on
overflow (when the input is less than smallest int248 or
greater than largest int248).

Counterpart to Solidity's `int248` operator.

Requirements:

- input must fit into 248 bits

\_Available since v4.7.\_\_

### toInt240

```solidity
function toInt240(int256 value) internal pure returns (int240 downcasted)
```

\_Returns the downcasted int240 from int256, reverting on
overflow (when the input is less than smallest int240 or
greater than largest int240).

Counterpart to Solidity's `int240` operator.

Requirements:

- input must fit into 240 bits

\_Available since v4.7.\_\_

### toInt232

```solidity
function toInt232(int256 value) internal pure returns (int232 downcasted)
```

\_Returns the downcasted int232 from int256, reverting on
overflow (when the input is less than smallest int232 or
greater than largest int232).

Counterpart to Solidity's `int232` operator.

Requirements:

- input must fit into 232 bits

\_Available since v4.7.\_\_

### toInt224

```solidity
function toInt224(int256 value) internal pure returns (int224 downcasted)
```

\_Returns the downcasted int224 from int256, reverting on
overflow (when the input is less than smallest int224 or
greater than largest int224).

Counterpart to Solidity's `int224` operator.

Requirements:

- input must fit into 224 bits

\_Available since v4.7.\_\_

### toInt216

```solidity
function toInt216(int256 value) internal pure returns (int216 downcasted)
```

\_Returns the downcasted int216 from int256, reverting on
overflow (when the input is less than smallest int216 or
greater than largest int216).

Counterpart to Solidity's `int216` operator.

Requirements:

- input must fit into 216 bits

\_Available since v4.7.\_\_

### toInt208

```solidity
function toInt208(int256 value) internal pure returns (int208 downcasted)
```

\_Returns the downcasted int208 from int256, reverting on
overflow (when the input is less than smallest int208 or
greater than largest int208).

Counterpart to Solidity's `int208` operator.

Requirements:

- input must fit into 208 bits

\_Available since v4.7.\_\_

### toInt200

```solidity
function toInt200(int256 value) internal pure returns (int200 downcasted)
```

\_Returns the downcasted int200 from int256, reverting on
overflow (when the input is less than smallest int200 or
greater than largest int200).

Counterpart to Solidity's `int200` operator.

Requirements:

- input must fit into 200 bits

\_Available since v4.7.\_\_

### toInt192

```solidity
function toInt192(int256 value) internal pure returns (int192 downcasted)
```

\_Returns the downcasted int192 from int256, reverting on
overflow (when the input is less than smallest int192 or
greater than largest int192).

Counterpart to Solidity's `int192` operator.

Requirements:

- input must fit into 192 bits

\_Available since v4.7.\_\_

### toInt184

```solidity
function toInt184(int256 value) internal pure returns (int184 downcasted)
```

\_Returns the downcasted int184 from int256, reverting on
overflow (when the input is less than smallest int184 or
greater than largest int184).

Counterpart to Solidity's `int184` operator.

Requirements:

- input must fit into 184 bits

\_Available since v4.7.\_\_

### toInt176

```solidity
function toInt176(int256 value) internal pure returns (int176 downcasted)
```

\_Returns the downcasted int176 from int256, reverting on
overflow (when the input is less than smallest int176 or
greater than largest int176).

Counterpart to Solidity's `int176` operator.

Requirements:

- input must fit into 176 bits

\_Available since v4.7.\_\_

### toInt168

```solidity
function toInt168(int256 value) internal pure returns (int168 downcasted)
```

\_Returns the downcasted int168 from int256, reverting on
overflow (when the input is less than smallest int168 or
greater than largest int168).

Counterpart to Solidity's `int168` operator.

Requirements:

- input must fit into 168 bits

\_Available since v4.7.\_\_

### toInt160

```solidity
function toInt160(int256 value) internal pure returns (int160 downcasted)
```

\_Returns the downcasted int160 from int256, reverting on
overflow (when the input is less than smallest int160 or
greater than largest int160).

Counterpart to Solidity's `int160` operator.

Requirements:

- input must fit into 160 bits

\_Available since v4.7.\_\_

### toInt152

```solidity
function toInt152(int256 value) internal pure returns (int152 downcasted)
```

\_Returns the downcasted int152 from int256, reverting on
overflow (when the input is less than smallest int152 or
greater than largest int152).

Counterpart to Solidity's `int152` operator.

Requirements:

- input must fit into 152 bits

\_Available since v4.7.\_\_

### toInt144

```solidity
function toInt144(int256 value) internal pure returns (int144 downcasted)
```

\_Returns the downcasted int144 from int256, reverting on
overflow (when the input is less than smallest int144 or
greater than largest int144).

Counterpart to Solidity's `int144` operator.

Requirements:

- input must fit into 144 bits

\_Available since v4.7.\_\_

### toInt136

```solidity
function toInt136(int256 value) internal pure returns (int136 downcasted)
```

\_Returns the downcasted int136 from int256, reverting on
overflow (when the input is less than smallest int136 or
greater than largest int136).

Counterpart to Solidity's `int136` operator.

Requirements:

- input must fit into 136 bits

\_Available since v4.7.\_\_

### toInt128

```solidity
function toInt128(int256 value) internal pure returns (int128 downcasted)
```

\_Returns the downcasted int128 from int256, reverting on
overflow (when the input is less than smallest int128 or
greater than largest int128).

Counterpart to Solidity's `int128` operator.

Requirements:

- input must fit into 128 bits

\_Available since v3.1.\_\_

### toInt120

```solidity
function toInt120(int256 value) internal pure returns (int120 downcasted)
```

\_Returns the downcasted int120 from int256, reverting on
overflow (when the input is less than smallest int120 or
greater than largest int120).

Counterpart to Solidity's `int120` operator.

Requirements:

- input must fit into 120 bits

\_Available since v4.7.\_\_

### toInt112

```solidity
function toInt112(int256 value) internal pure returns (int112 downcasted)
```

\_Returns the downcasted int112 from int256, reverting on
overflow (when the input is less than smallest int112 or
greater than largest int112).

Counterpart to Solidity's `int112` operator.

Requirements:

- input must fit into 112 bits

\_Available since v4.7.\_\_

### toInt104

```solidity
function toInt104(int256 value) internal pure returns (int104 downcasted)
```

\_Returns the downcasted int104 from int256, reverting on
overflow (when the input is less than smallest int104 or
greater than largest int104).

Counterpart to Solidity's `int104` operator.

Requirements:

- input must fit into 104 bits

\_Available since v4.7.\_\_

### toInt96

```solidity
function toInt96(int256 value) internal pure returns (int96 downcasted)
```

\_Returns the downcasted int96 from int256, reverting on
overflow (when the input is less than smallest int96 or
greater than largest int96).

Counterpart to Solidity's `int96` operator.

Requirements:

- input must fit into 96 bits

\_Available since v4.7.\_\_

### toInt88

```solidity
function toInt88(int256 value) internal pure returns (int88 downcasted)
```

\_Returns the downcasted int88 from int256, reverting on
overflow (when the input is less than smallest int88 or
greater than largest int88).

Counterpart to Solidity's `int88` operator.

Requirements:

- input must fit into 88 bits

\_Available since v4.7.\_\_

### toInt80

```solidity
function toInt80(int256 value) internal pure returns (int80 downcasted)
```

\_Returns the downcasted int80 from int256, reverting on
overflow (when the input is less than smallest int80 or
greater than largest int80).

Counterpart to Solidity's `int80` operator.

Requirements:

- input must fit into 80 bits

\_Available since v4.7.\_\_

### toInt72

```solidity
function toInt72(int256 value) internal pure returns (int72 downcasted)
```

\_Returns the downcasted int72 from int256, reverting on
overflow (when the input is less than smallest int72 or
greater than largest int72).

Counterpart to Solidity's `int72` operator.

Requirements:

- input must fit into 72 bits

\_Available since v4.7.\_\_

### toInt64

```solidity
function toInt64(int256 value) internal pure returns (int64 downcasted)
```

\_Returns the downcasted int64 from int256, reverting on
overflow (when the input is less than smallest int64 or
greater than largest int64).

Counterpart to Solidity's `int64` operator.

Requirements:

- input must fit into 64 bits

\_Available since v3.1.\_\_

### toInt56

```solidity
function toInt56(int256 value) internal pure returns (int56 downcasted)
```

\_Returns the downcasted int56 from int256, reverting on
overflow (when the input is less than smallest int56 or
greater than largest int56).

Counterpart to Solidity's `int56` operator.

Requirements:

- input must fit into 56 bits

\_Available since v4.7.\_\_

### toInt48

```solidity
function toInt48(int256 value) internal pure returns (int48 downcasted)
```

\_Returns the downcasted int48 from int256, reverting on
overflow (when the input is less than smallest int48 or
greater than largest int48).

Counterpart to Solidity's `int48` operator.

Requirements:

- input must fit into 48 bits

\_Available since v4.7.\_\_

### toInt40

```solidity
function toInt40(int256 value) internal pure returns (int40 downcasted)
```

\_Returns the downcasted int40 from int256, reverting on
overflow (when the input is less than smallest int40 or
greater than largest int40).

Counterpart to Solidity's `int40` operator.

Requirements:

- input must fit into 40 bits

\_Available since v4.7.\_\_

### toInt32

```solidity
function toInt32(int256 value) internal pure returns (int32 downcasted)
```

\_Returns the downcasted int32 from int256, reverting on
overflow (when the input is less than smallest int32 or
greater than largest int32).

Counterpart to Solidity's `int32` operator.

Requirements:

- input must fit into 32 bits

\_Available since v3.1.\_\_

### toInt24

```solidity
function toInt24(int256 value) internal pure returns (int24 downcasted)
```

\_Returns the downcasted int24 from int256, reverting on
overflow (when the input is less than smallest int24 or
greater than largest int24).

Counterpart to Solidity's `int24` operator.

Requirements:

- input must fit into 24 bits

\_Available since v4.7.\_\_

### toInt16

```solidity
function toInt16(int256 value) internal pure returns (int16 downcasted)
```

\_Returns the downcasted int16 from int256, reverting on
overflow (when the input is less than smallest int16 or
greater than largest int16).

Counterpart to Solidity's `int16` operator.

Requirements:

- input must fit into 16 bits

\_Available since v3.1.\_\_

### toInt8

```solidity
function toInt8(int256 value) internal pure returns (int8 downcasted)
```

\_Returns the downcasted int8 from int256, reverting on
overflow (when the input is less than smallest int8 or
greater than largest int8).

Counterpart to Solidity's `int8` operator.

Requirements:

- input must fit into 8 bits

\_Available since v3.1.\_\_

### toInt256

```solidity
function toInt256(uint256 value) internal pure returns (int256)
```

\_Converts an unsigned uint256 into a signed int256.

Requirements:

- input must be less than or equal to maxInt256.

\_Available since v3.0.\_\_

## SignedMath

_Standard signed math utilities missing in the Solidity language._

### max

```solidity
function max(int256 a, int256 b) internal pure returns (int256)
```

_Returns the largest of two signed numbers._

### min

```solidity
function min(int256 a, int256 b) internal pure returns (int256)
```

_Returns the smallest of two signed numbers._

### average

```solidity
function average(int256 a, int256 b) internal pure returns (int256)
```

_Returns the average of two signed numbers without overflow.
The result is rounded towards zero._

### abs

```solidity
function abs(int256 n) internal pure returns (uint256)
```

_Returns the absolute unsigned value of a signed value._

## DoubleEndedQueue

\_A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
the existing queue contents are left in storage.

The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
used in storage, and not in memory.

```solidity
DoubleEndedQueue.Bytes32Deque queue;
```

\_Available since v4.6.\_\_

### Empty

```solidity
error Empty()
```

_An operation (e.g. {front}) couldn't be completed due to the queue being empty._

### OutOfBounds

```solidity
error OutOfBounds()
```

_An operation (e.g. {at}) couldn't be completed due to an index being out of bounds._

### Bytes32Deque

```solidity
struct Bytes32Deque {
  int128 _begin;
  int128 _end;
  mapping(int128 => bytes32) _data;
}
```

### pushBack

```solidity
function pushBack(struct DoubleEndedQueue.Bytes32Deque deque, bytes32 value) internal
```

_Inserts an item at the end of the queue._

### popBack

```solidity
function popBack(struct DoubleEndedQueue.Bytes32Deque deque) internal returns (bytes32 value)
```

\_Removes the item at the end of the queue and returns it.

Reverts with `Empty` if the queue is empty.\_

### pushFront

```solidity
function pushFront(struct DoubleEndedQueue.Bytes32Deque deque, bytes32 value) internal
```

_Inserts an item at the beginning of the queue._

### popFront

```solidity
function popFront(struct DoubleEndedQueue.Bytes32Deque deque) internal returns (bytes32 value)
```

\_Removes the item at the beginning of the queue and returns it.

Reverts with `Empty` if the queue is empty.\_

### front

```solidity
function front(struct DoubleEndedQueue.Bytes32Deque deque) internal view returns (bytes32 value)
```

\_Returns the item at the beginning of the queue.

Reverts with `Empty` if the queue is empty.\_

### back

```solidity
function back(struct DoubleEndedQueue.Bytes32Deque deque) internal view returns (bytes32 value)
```

\_Returns the item at the end of the queue.

Reverts with `Empty` if the queue is empty.\_

### at

```solidity
function at(struct DoubleEndedQueue.Bytes32Deque deque, uint256 index) internal view returns (bytes32 value)
```

\_Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
`length(deque) - 1`.

Reverts with `OutOfBounds` if the index is out of bounds.\_

### clear

```solidity
function clear(struct DoubleEndedQueue.Bytes32Deque deque) internal
```

\_Resets the queue back to being empty.

NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
out on potential gas refunds.\_

### length

```solidity
function length(struct DoubleEndedQueue.Bytes32Deque deque) internal view returns (uint256)
```

_Returns the number of items in the queue._

### empty

```solidity
function empty(struct DoubleEndedQueue.Bytes32Deque deque) internal view returns (bool)
```

_Returns true if the queue is empty._

## PRBMath_MulDiv_Overflow

```solidity
error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator)
```

Thrown when the resultant value in {mulDiv} overflows uint256.

## PRBMath_MulDiv18_Overflow

```solidity
error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y)
```

Thrown when the resultant value in {mulDiv18} overflows uint256.

## PRBMath_MulDivSigned_InputTooSmall

```solidity
error PRBMath_MulDivSigned_InputTooSmall()
```

Thrown when one of the inputs passed to {mulDivSigned} is `type(int256).min`.

## PRBMath_MulDivSigned_Overflow

```solidity
error PRBMath_MulDivSigned_Overflow(int256 x, int256 y)
```

Thrown when the resultant value in {mulDivSigned} overflows int256.

## MAX_UINT128

```solidity
uint128 MAX_UINT128
```

## MAX_UINT40

```solidity
uint40 MAX_UINT40
```

## UNIT

```solidity
uint256 UNIT
```

## UNIT_INVERSE

```solidity
uint256 UNIT_INVERSE
```

## UNIT_LPOTD

```solidity
uint256 UNIT_LPOTD
```

## exp2

```solidity
function exp2(uint256 x) internal pure returns (uint256 result)
```

Calculates the binary exponent of x using the binary fraction method.

_Has to use 192.64-bit fixed-point numbers. See https://ethereum.stackexchange.com/a/96594/24693._

### Parameters

| Name | Type    | Description                                                |
| ---- | ------- | ---------------------------------------------------------- |
| x    | uint256 | The exponent as an unsigned 192.64-bit fixed-point number. |

### Return Values

| Name   | Type    | Description                                                 |
| ------ | ------- | ----------------------------------------------------------- |
| result | uint256 | The result as an unsigned 60.18-decimal fixed-point number. |

## msb

```solidity
function msb(uint256 x) internal pure returns (uint256 result)
```

Finds the zero-based index of the first 1 in the binary representation of x.

\_See the note on "msb" in this Wikipedia article: https://en.wikipedia.org/wiki/Find_first_set

Each step in this implementation is equivalent to this high-level code:

```solidity
if (x >= 2 ** 128) {
    x >>= 128;
    result += 128;
}
```

Where 128 is replaced with each respective power of two factor. See the full high-level implementation here:
https://gist.github.com/PaulRBerg/f932f8693f2733e30c4d479e8e980948

The Yul instructions used below are:

- "gt" is "greater than"
- "or" is the OR bitwise operator
- "shl" is "shift left"
- "shr" is "shift right"\_

### Parameters

| Name | Type    | Description                                                                 |
| ---- | ------- | --------------------------------------------------------------------------- |
| x    | uint256 | The uint256 number for which to find the index of the most significant bit. |

### Return Values

| Name   | Type    | Description                                         |
| ------ | ------- | --------------------------------------------------- |
| result | uint256 | The index of the most significant bit as a uint256. |

## mulDiv

```solidity
function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result)
```

Calculates x\*y÷denominator with 512-bit precision.

\_Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.

Notes:

- The result is rounded toward zero.

Requirements:

- The denominator must not be zero.
- The result must fit in uint256.\_

### Parameters

| Name        | Type    | Description                    |
| ----------- | ------- | ------------------------------ |
| x           | uint256 | The multiplicand as a uint256. |
| y           | uint256 | The multiplier as a uint256.   |
| denominator | uint256 | The divisor as a uint256.      |

### Return Values

| Name   | Type    | Description              |
| ------ | ------- | ------------------------ |
| result | uint256 | The result as a uint256. |

## mulDiv18

```solidity
function mulDiv18(uint256 x, uint256 y) internal pure returns (uint256 result)
```

Calculates x\*y÷1e18 with 512-bit precision.

\_A variant of {mulDiv} with constant folding, i.e. in which the denominator is hard coded to 1e18.

Notes:

- The body is purposely left uncommented; to understand how this works, see the documentation in {mulDiv}.
- The result is rounded toward zero.
- We take as an axiom that the result cannot be `MAX_UINT256` when x and y solve the following system of equations:

$$
\begin{cases}
    x * y = MAX\_UINT256 * UNIT \\
    (x * y) \% UNIT \geq \frac{UNIT}{2}
\end{cases}
$$

Requirements:

- Refer to the requirements in {mulDiv}.
- The result must fit in uint256.\_

### Parameters

| Name | Type    | Description                                                       |
| ---- | ------- | ----------------------------------------------------------------- |
| x    | uint256 | The multiplicand as an unsigned 60.18-decimal fixed-point number. |
| y    | uint256 | The multiplier as an unsigned 60.18-decimal fixed-point number.   |

### Return Values

| Name   | Type    | Description                                                 |
| ------ | ------- | ----------------------------------------------------------- |
| result | uint256 | The result as an unsigned 60.18-decimal fixed-point number. |

## mulDivSigned

```solidity
function mulDivSigned(int256 x, int256 y, int256 denominator) internal pure returns (int256 result)
```

Calculates x\*y÷denominator with 512-bit precision.

\_This is an extension of {mulDiv} for signed numbers, which works by computing the signs and the absolute values separately.

Notes:

- The result is rounded toward zero.

Requirements:

- Refer to the requirements in {mulDiv}.
- None of the inputs can be `type(int256).min`.
- The result must fit in int256.\_

### Parameters

| Name        | Type   | Description                    |
| ----------- | ------ | ------------------------------ |
| x           | int256 | The multiplicand as an int256. |
| y           | int256 | The multiplier as an int256.   |
| denominator | int256 | The divisor as an int256.      |

### Return Values

| Name   | Type   | Description              |
| ------ | ------ | ------------------------ |
| result | int256 | The result as an int256. |

## sqrt

```solidity
function sqrt(uint256 x) internal pure returns (uint256 result)
```

Calculates the square root of x using the Babylonian method.

\_See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.

Notes:

- If x is not a perfect square, the result is rounded down.
- Credits to OpenZeppelin for the explanations in comments below.\_

### Parameters

| Name | Type    | Description                                                |
| ---- | ------- | ---------------------------------------------------------- |
| x    | uint256 | The uint256 number for which to calculate the square root. |

### Return Values

| Name   | Type    | Description              |
| ------ | ------- | ------------------------ |
| result | uint256 | The result as a uint256. |

## PRBMath_IntoSD1x18_Overflow

```solidity
error PRBMath_IntoSD1x18_Overflow(uint128 x)
```

Thrown when trying to cast a uint128 that doesn't fit in SD1x18.

## PRBMath_IntoUD2x18_Overflow

```solidity
error PRBMath_IntoUD2x18_Overflow(uint128 x)
```

Thrown when trying to cast a uint128 that doesn't fit in UD2x18.

## PRBMathCastingUint128

Casting utilities for uint128.

### intoSD1x18

```solidity
function intoSD1x18(uint128 x) internal pure returns (SD1x18 result)
```

Casts a uint128 number to SD1x18.

\_Requirements:

- x must be less than or equal to `MAX_SD1x18`.\_

### intoSD59x18

```solidity
function intoSD59x18(uint128 x) internal pure returns (SD59x18 result)
```

Casts a uint128 number to SD59x18.

_There is no overflow check because the domain of uint128 is a subset of SD59x18._

### intoUD2x18

```solidity
function intoUD2x18(uint128 x) internal pure returns (UD2x18 result)
```

Casts a uint128 number to UD2x18.

\_Requirements:

- x must be less than or equal to `MAX_SD1x18`.\_

### intoUD60x18

```solidity
function intoUD60x18(uint128 x) internal pure returns (UD60x18 result)
```

Casts a uint128 number to UD60x18.

_There is no overflow check because the domain of uint128 is a subset of UD60x18._

## PRBMath_IntoSD1x18_Overflow

```solidity
error PRBMath_IntoSD1x18_Overflow(uint256 x)
```

Thrown when trying to cast a uint256 that doesn't fit in SD1x18.

## PRBMath_IntoSD59x18_Overflow

```solidity
error PRBMath_IntoSD59x18_Overflow(uint256 x)
```

Thrown when trying to cast a uint256 that doesn't fit in SD59x18.

## PRBMath_IntoUD2x18_Overflow

```solidity
error PRBMath_IntoUD2x18_Overflow(uint256 x)
```

Thrown when trying to cast a uint256 that doesn't fit in UD2x18.

## PRBMathCastingUint256

Casting utilities for uint256.

### intoSD1x18

```solidity
function intoSD1x18(uint256 x) internal pure returns (SD1x18 result)
```

Casts a uint256 number to SD1x18.

\_Requirements:

- x must be less than or equal to `MAX_SD1x18`.\_

### intoSD59x18

```solidity
function intoSD59x18(uint256 x) internal pure returns (SD59x18 result)
```

Casts a uint256 number to SD59x18.

\_Requirements:

- x must be less than or equal to `MAX_SD59x18`.\_

### intoUD2x18

```solidity
function intoUD2x18(uint256 x) internal pure returns (UD2x18 result)
```

Casts a uint256 number to UD2x18.

### intoUD60x18

```solidity
function intoUD60x18(uint256 x) internal pure returns (UD60x18 result)
```

Casts a uint256 number to UD60x18.

## PRBMathCastingUint40

Casting utilities for uint40.

### intoSD1x18

```solidity
function intoSD1x18(uint40 x) internal pure returns (SD1x18 result)
```

Casts a uint40 number into SD1x18.

_There is no overflow check because the domain of uint40 is a subset of SD1x18._

### intoSD59x18

```solidity
function intoSD59x18(uint40 x) internal pure returns (SD59x18 result)
```

Casts a uint40 number into SD59x18.

_There is no overflow check because the domain of uint40 is a subset of SD59x18._

### intoUD2x18

```solidity
function intoUD2x18(uint40 x) internal pure returns (UD2x18 result)
```

Casts a uint40 number into UD2x18.

_There is no overflow check because the domain of uint40 is a subset of UD2x18._

### intoUD60x18

```solidity
function intoUD60x18(uint40 x) internal pure returns (UD60x18 result)
```

Casts a uint40 number into UD60x18.

_There is no overflow check because the domain of uint40 is a subset of UD60x18._

## intoSD59x18

```solidity
function intoSD59x18(SD1x18 x) internal pure returns (SD59x18 result)
```

Casts an SD1x18 number into SD59x18.

_There is no overflow check because the domain of SD1x18 is a subset of SD59x18._

## intoUD2x18

```solidity
function intoUD2x18(SD1x18 x) internal pure returns (UD2x18 result)
```

Casts an SD1x18 number into UD2x18.

- x must be positive.

## intoUD60x18

```solidity
function intoUD60x18(SD1x18 x) internal pure returns (UD60x18 result)
```

Casts an SD1x18 number into UD60x18.

\_Requirements:

- x must be positive.\_

## intoUint256

```solidity
function intoUint256(SD1x18 x) internal pure returns (uint256 result)
```

Casts an SD1x18 number into uint256.

\_Requirements:

- x must be positive.\_

## intoUint128

```solidity
function intoUint128(SD1x18 x) internal pure returns (uint128 result)
```

Casts an SD1x18 number into uint128.

\_Requirements:

- x must be positive.\_

## intoUint40

```solidity
function intoUint40(SD1x18 x) internal pure returns (uint40 result)
```

Casts an SD1x18 number into uint40.

\_Requirements:

- x must be positive.
- x must be less than or equal to `MAX_UINT40`.\_

## sd1x18

```solidity
function sd1x18(int64 x) internal pure returns (SD1x18 result)
```

Alias for {wrap}.

## unwrap

```solidity
function unwrap(SD1x18 x) internal pure returns (int64 result)
```

Unwraps an SD1x18 number into int64.

## wrap

```solidity
function wrap(int64 x) internal pure returns (SD1x18 result)
```

Wraps an int64 number into SD1x18.

## E

```solidity
SD1x18 E
```

## uMAX_SD1x18

```solidity
int64 uMAX_SD1x18
```

## MAX_SD1x18

```solidity
SD1x18 MAX_SD1x18
```

## uMIN_SD1x18

```solidity
int64 uMIN_SD1x18
```

## MIN_SD1x18

```solidity
SD1x18 MIN_SD1x18
```

## PI

```solidity
SD1x18 PI
```

## UNIT

```solidity
SD1x18 UNIT
```

## uUNIT

```solidity
int256 uUNIT
```

## PRBMath_SD1x18_ToUD2x18_Underflow

```solidity
error PRBMath_SD1x18_ToUD2x18_Underflow(SD1x18 x)
```

Thrown when trying to cast a SD1x18 number that doesn't fit in UD2x18.

## PRBMath_SD1x18_ToUD60x18_Underflow

```solidity
error PRBMath_SD1x18_ToUD60x18_Underflow(SD1x18 x)
```

Thrown when trying to cast a SD1x18 number that doesn't fit in UD60x18.

## PRBMath_SD1x18_ToUint128_Underflow

```solidity
error PRBMath_SD1x18_ToUint128_Underflow(SD1x18 x)
```

Thrown when trying to cast a SD1x18 number that doesn't fit in uint128.

## PRBMath_SD1x18_ToUint256_Underflow

```solidity
error PRBMath_SD1x18_ToUint256_Underflow(SD1x18 x)
```

Thrown when trying to cast a SD1x18 number that doesn't fit in uint256.

## PRBMath_SD1x18_ToUint40_Overflow

```solidity
error PRBMath_SD1x18_ToUint40_Overflow(SD1x18 x)
```

Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.

## PRBMath_SD1x18_ToUint40_Underflow

```solidity
error PRBMath_SD1x18_ToUint40_Underflow(SD1x18 x)
```

Thrown when trying to cast a SD1x18 number that doesn't fit in uint40.

## SD1x18

## intoInt256

```solidity
function intoInt256(SD59x18 x) internal pure returns (int256 result)
```

Casts an SD59x18 number into int256.

_This is basically a functional alias for {unwrap}._

## intoSD1x18

```solidity
function intoSD1x18(SD59x18 x) internal pure returns (SD1x18 result)
```

Casts an SD59x18 number into SD1x18.

\_Requirements:

- x must be greater than or equal to `uMIN_SD1x18`.
- x must be less than or equal to `uMAX_SD1x18`.\_

## intoUD2x18

```solidity
function intoUD2x18(SD59x18 x) internal pure returns (UD2x18 result)
```

Casts an SD59x18 number into UD2x18.

\_Requirements:

- x must be positive.
- x must be less than or equal to `uMAX_UD2x18`.\_

## intoUD60x18

```solidity
function intoUD60x18(SD59x18 x) internal pure returns (UD60x18 result)
```

Casts an SD59x18 number into UD60x18.

\_Requirements:

- x must be positive.\_

## intoUint256

```solidity
function intoUint256(SD59x18 x) internal pure returns (uint256 result)
```

Casts an SD59x18 number into uint256.

\_Requirements:

- x must be positive.\_

## intoUint128

```solidity
function intoUint128(SD59x18 x) internal pure returns (uint128 result)
```

Casts an SD59x18 number into uint128.

\_Requirements:

- x must be positive.
- x must be less than or equal to `uMAX_UINT128`.\_

## intoUint40

```solidity
function intoUint40(SD59x18 x) internal pure returns (uint40 result)
```

Casts an SD59x18 number into uint40.

\_Requirements:

- x must be positive.
- x must be less than or equal to `MAX_UINT40`.\_

## sd

```solidity
function sd(int256 x) internal pure returns (SD59x18 result)
```

Alias for {wrap}.

## sd59x18

```solidity
function sd59x18(int256 x) internal pure returns (SD59x18 result)
```

Alias for {wrap}.

## unwrap

```solidity
function unwrap(SD59x18 x) internal pure returns (int256 result)
```

Unwraps an SD59x18 number into int256.

## wrap

```solidity
function wrap(int256 x) internal pure returns (SD59x18 result)
```

Wraps an int256 number into SD59x18.

## E

```solidity
SD59x18 E
```

## uEXP_MAX_INPUT

```solidity
int256 uEXP_MAX_INPUT
```

## EXP_MAX_INPUT

```solidity
SD59x18 EXP_MAX_INPUT
```

## uEXP2_MAX_INPUT

```solidity
int256 uEXP2_MAX_INPUT
```

## EXP2_MAX_INPUT

```solidity
SD59x18 EXP2_MAX_INPUT
```

## uHALF_UNIT

```solidity
int256 uHALF_UNIT
```

## HALF_UNIT

```solidity
SD59x18 HALF_UNIT
```

## uLOG2_10

```solidity
int256 uLOG2_10
```

## LOG2_10

```solidity
SD59x18 LOG2_10
```

## uLOG2_E

```solidity
int256 uLOG2_E
```

## LOG2_E

```solidity
SD59x18 LOG2_E
```

## uMAX_SD59x18

```solidity
int256 uMAX_SD59x18
```

## MAX_SD59x18

```solidity
SD59x18 MAX_SD59x18
```

## uMAX_WHOLE_SD59x18

```solidity
int256 uMAX_WHOLE_SD59x18
```

## MAX_WHOLE_SD59x18

```solidity
SD59x18 MAX_WHOLE_SD59x18
```

## uMIN_SD59x18

```solidity
int256 uMIN_SD59x18
```

## MIN_SD59x18

```solidity
SD59x18 MIN_SD59x18
```

## uMIN_WHOLE_SD59x18

```solidity
int256 uMIN_WHOLE_SD59x18
```

## MIN_WHOLE_SD59x18

```solidity
SD59x18 MIN_WHOLE_SD59x18
```

## PI

```solidity
SD59x18 PI
```

## uUNIT

```solidity
int256 uUNIT
```

## UNIT

```solidity
SD59x18 UNIT
```

## uUNIT_SQUARED

```solidity
int256 uUNIT_SQUARED
```

## UNIT_SQUARED

```solidity
SD59x18 UNIT_SQUARED
```

## ZERO

```solidity
SD59x18 ZERO
```

## convert

```solidity
function convert(int256 x) internal pure returns (SD59x18 result)
```

Converts a simple integer to SD59x18 by multiplying it by `UNIT`.

\_Requirements:

- x must be greater than or equal to `MIN_SD59x18 / UNIT`.
- x must be less than or equal to `MAX_SD59x18 / UNIT`.\_

### Parameters

| Name | Type   | Description                   |
| ---- | ------ | ----------------------------- |
| x    | int256 | The basic integer to convert. |

## convert

```solidity
function convert(SD59x18 x) internal pure returns (int256 result)
```

Converts an SD59x18 number to a simple integer by dividing it by `UNIT`.

_The result is rounded toward zero._

### Parameters

| Name | Type    | Description                    |
| ---- | ------- | ------------------------------ |
| x    | SD59x18 | The SD59x18 number to convert. |

### Return Values

| Name   | Type   | Description                          |
| ------ | ------ | ------------------------------------ |
| result | int256 | The same number as a simple integer. |

## PRBMath_SD59x18_Abs_MinSD59x18

```solidity
error PRBMath_SD59x18_Abs_MinSD59x18()
```

Thrown when taking the absolute value of `MIN_SD59x18`.

## PRBMath_SD59x18_Ceil_Overflow

```solidity
error PRBMath_SD59x18_Ceil_Overflow(SD59x18 x)
```

Thrown when ceiling a number overflows SD59x18.

## PRBMath_SD59x18_Convert_Overflow

```solidity
error PRBMath_SD59x18_Convert_Overflow(int256 x)
```

Thrown when converting a basic integer to the fixed-point format overflows SD59x18.

## PRBMath_SD59x18_Convert_Underflow

```solidity
error PRBMath_SD59x18_Convert_Underflow(int256 x)
```

Thrown when converting a basic integer to the fixed-point format underflows SD59x18.

## PRBMath_SD59x18_Div_InputTooSmall

```solidity
error PRBMath_SD59x18_Div_InputTooSmall()
```

Thrown when dividing two numbers and one of them is `MIN_SD59x18`.

## PRBMath_SD59x18_Div_Overflow

```solidity
error PRBMath_SD59x18_Div_Overflow(SD59x18 x, SD59x18 y)
```

Thrown when dividing two numbers and one of the intermediary unsigned results overflows SD59x18.

## PRBMath_SD59x18_Exp_InputTooBig

```solidity
error PRBMath_SD59x18_Exp_InputTooBig(SD59x18 x)
```

Thrown when taking the natural exponent of a base greater than 133_084258667509499441.

## PRBMath_SD59x18_Exp2_InputTooBig

```solidity
error PRBMath_SD59x18_Exp2_InputTooBig(SD59x18 x)
```

Thrown when taking the binary exponent of a base greater than 192e18.

## PRBMath_SD59x18_Floor_Underflow

```solidity
error PRBMath_SD59x18_Floor_Underflow(SD59x18 x)
```

Thrown when flooring a number underflows SD59x18.

## PRBMath_SD59x18_Gm_NegativeProduct

```solidity
error PRBMath_SD59x18_Gm_NegativeProduct(SD59x18 x, SD59x18 y)
```

Thrown when taking the geometric mean of two numbers and their product is negative.

## PRBMath_SD59x18_Gm_Overflow

```solidity
error PRBMath_SD59x18_Gm_Overflow(SD59x18 x, SD59x18 y)
```

Thrown when taking the geometric mean of two numbers and multiplying them overflows SD59x18.

## PRBMath_SD59x18_IntoSD1x18_Overflow

```solidity
error PRBMath_SD59x18_IntoSD1x18_Overflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.

## PRBMath_SD59x18_IntoSD1x18_Underflow

```solidity
error PRBMath_SD59x18_IntoSD1x18_Underflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.

## PRBMath_SD59x18_IntoUD2x18_Overflow

```solidity
error PRBMath_SD59x18_IntoUD2x18_Overflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.

## PRBMath_SD59x18_IntoUD2x18_Underflow

```solidity
error PRBMath_SD59x18_IntoUD2x18_Underflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.

## PRBMath_SD59x18_IntoUD60x18_Underflow

```solidity
error PRBMath_SD59x18_IntoUD60x18_Underflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in UD60x18.

## PRBMath_SD59x18_IntoUint128_Overflow

```solidity
error PRBMath_SD59x18_IntoUint128_Overflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.

## PRBMath_SD59x18_IntoUint128_Underflow

```solidity
error PRBMath_SD59x18_IntoUint128_Underflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.

## PRBMath_SD59x18_IntoUint256_Underflow

```solidity
error PRBMath_SD59x18_IntoUint256_Underflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in uint256.

## PRBMath_SD59x18_IntoUint40_Overflow

```solidity
error PRBMath_SD59x18_IntoUint40_Overflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.

## PRBMath_SD59x18_IntoUint40_Underflow

```solidity
error PRBMath_SD59x18_IntoUint40_Underflow(SD59x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.

## PRBMath_SD59x18_Log_InputTooSmall

```solidity
error PRBMath_SD59x18_Log_InputTooSmall(SD59x18 x)
```

Thrown when taking the logarithm of a number less than or equal to zero.

## PRBMath_SD59x18_Mul_InputTooSmall

```solidity
error PRBMath_SD59x18_Mul_InputTooSmall()
```

Thrown when multiplying two numbers and one of the inputs is `MIN_SD59x18`.

## PRBMath_SD59x18_Mul_Overflow

```solidity
error PRBMath_SD59x18_Mul_Overflow(SD59x18 x, SD59x18 y)
```

Thrown when multiplying two numbers and the intermediary absolute result overflows SD59x18.

## PRBMath_SD59x18_Powu_Overflow

```solidity
error PRBMath_SD59x18_Powu_Overflow(SD59x18 x, uint256 y)
```

Thrown when raising a number to a power and the intermediary absolute result overflows SD59x18.

## PRBMath_SD59x18_Sqrt_NegativeInput

```solidity
error PRBMath_SD59x18_Sqrt_NegativeInput(SD59x18 x)
```

Thrown when taking the square root of a negative number.

## PRBMath_SD59x18_Sqrt_Overflow

```solidity
error PRBMath_SD59x18_Sqrt_Overflow(SD59x18 x)
```

Thrown when the calculating the square root overflows SD59x18.

## add

```solidity
function add(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Implements the checked addition operation (+) in the SD59x18 type.

## and

```solidity
function and(SD59x18 x, int256 bits) internal pure returns (SD59x18 result)
```

Implements the AND (&) bitwise operation in the SD59x18 type.

## and2

```solidity
function and2(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Implements the AND (&) bitwise operation in the SD59x18 type.

## eq

```solidity
function eq(SD59x18 x, SD59x18 y) internal pure returns (bool result)
```

Implements the equal (=) operation in the SD59x18 type.

## gt

```solidity
function gt(SD59x18 x, SD59x18 y) internal pure returns (bool result)
```

Implements the greater than operation (>) in the SD59x18 type.

## gte

```solidity
function gte(SD59x18 x, SD59x18 y) internal pure returns (bool result)
```

Implements the greater than or equal to operation (>=) in the SD59x18 type.

## isZero

```solidity
function isZero(SD59x18 x) internal pure returns (bool result)
```

Implements a zero comparison check function in the SD59x18 type.

## lshift

```solidity
function lshift(SD59x18 x, uint256 bits) internal pure returns (SD59x18 result)
```

Implements the left shift operation (<<) in the SD59x18 type.

## lt

```solidity
function lt(SD59x18 x, SD59x18 y) internal pure returns (bool result)
```

Implements the lower than operation (<) in the SD59x18 type.

## lte

```solidity
function lte(SD59x18 x, SD59x18 y) internal pure returns (bool result)
```

Implements the lower than or equal to operation (<=) in the SD59x18 type.

## mod

```solidity
function mod(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Implements the unchecked modulo operation (%) in the SD59x18 type.

## neq

```solidity
function neq(SD59x18 x, SD59x18 y) internal pure returns (bool result)
```

Implements the not equal operation (!=) in the SD59x18 type.

## not

```solidity
function not(SD59x18 x) internal pure returns (SD59x18 result)
```

Implements the NOT (~) bitwise operation in the SD59x18 type.

## or

```solidity
function or(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Implements the OR (|) bitwise operation in the SD59x18 type.

## rshift

```solidity
function rshift(SD59x18 x, uint256 bits) internal pure returns (SD59x18 result)
```

Implements the right shift operation (>>) in the SD59x18 type.

## sub

```solidity
function sub(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Implements the checked subtraction operation (-) in the SD59x18 type.

## unary

```solidity
function unary(SD59x18 x) internal pure returns (SD59x18 result)
```

Implements the checked unary minus operation (-) in the SD59x18 type.

## uncheckedAdd

```solidity
function uncheckedAdd(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Implements the unchecked addition operation (+) in the SD59x18 type.

## uncheckedSub

```solidity
function uncheckedSub(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Implements the unchecked subtraction operation (-) in the SD59x18 type.

## uncheckedUnary

```solidity
function uncheckedUnary(SD59x18 x) internal pure returns (SD59x18 result)
```

Implements the unchecked unary minus operation (-) in the SD59x18 type.

## xor

```solidity
function xor(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Implements the XOR (^) bitwise operation in the SD59x18 type.

## abs

```solidity
function abs(SD59x18 x) internal pure returns (SD59x18 result)
```

Calculates the absolute value of x.

\_Requirements:

- x must be greater than `MIN_SD59x18`.\_

### Parameters

| Name | Type    | Description                                                   |
| ---- | ------- | ------------------------------------------------------------- |
| x    | SD59x18 | The SD59x18 number for which to calculate the absolute value. |

## avg

```solidity
function avg(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Calculates the arithmetic average of x and y.

\_Notes:

- The result is rounded toward zero.\_

### Parameters

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| x    | SD59x18 | The first operand as an SD59x18 number.  |
| y    | SD59x18 | The second operand as an SD59x18 number. |

### Return Values

| Name   | Type    | Description                                  |
| ------ | ------- | -------------------------------------------- |
| result | SD59x18 | The arithmetic average as an SD59x18 number. |

## ceil

```solidity
function ceil(SD59x18 x) internal pure returns (SD59x18 result)
```

Yields the smallest whole number greater than or equal to x.

\_Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.

Requirements:

- x must be less than or equal to `MAX_WHOLE_SD59x18`.\_

### Parameters

| Name | Type    | Description                 |
| ---- | ------- | --------------------------- |
| x    | SD59x18 | The SD59x18 number to ceil. |

## div

```solidity
function div(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Divides two SD59x18 numbers, returning a new SD59x18 number.

\_This is an extension of {Common.mulDiv} for signed numbers, which works by computing the signs and the absolute
values separately.

Notes:

- Refer to the notes in {Common.mulDiv}.
- The result is rounded toward zero.

Requirements:

- Refer to the requirements in {Common.mulDiv}.
- None of the inputs can be `MIN_SD59x18`.
- The denominator must not be zero.
- The result must fit in SD59x18.\_

### Parameters

| Name | Type    | Description                           |
| ---- | ------- | ------------------------------------- |
| x    | SD59x18 | The numerator as an SD59x18 number.   |
| y    | SD59x18 | The denominator as an SD59x18 number. |

## exp

```solidity
function exp(SD59x18 x) internal pure returns (SD59x18 result)
```

Calculates the natural exponent of x using the following formula:

$$
e^x = 2^{x * log_2{e}}
$$

\_Notes:

- Refer to the notes in {exp2}.

Requirements:

- Refer to the requirements in {exp2}.
- x must be less than 133*084258667509499441.*

### Parameters

| Name | Type    | Description                        |
| ---- | ------- | ---------------------------------- |
| x    | SD59x18 | The exponent as an SD59x18 number. |

### Return Values

| Name   | Type    | Description                      |
| ------ | ------- | -------------------------------- |
| result | SD59x18 | The result as an SD59x18 number. |

## exp2

```solidity
function exp2(SD59x18 x) internal pure returns (SD59x18 result)
```

Calculates the binary exponent of x using the binary fraction method using the following formula:

$$
2^{-x} = \frac{1}{2^x}
$$

\_See https://ethereum.stackexchange.com/q/79903/24693.

Notes:

- If x is less than -59_794705707972522261, the result is zero.

Requirements:

- x must be less than 192e18.
- The result must fit in SD59x18.\_

### Parameters

| Name | Type    | Description                        |
| ---- | ------- | ---------------------------------- |
| x    | SD59x18 | The exponent as an SD59x18 number. |

### Return Values

| Name   | Type    | Description                      |
| ------ | ------- | -------------------------------- |
| result | SD59x18 | The result as an SD59x18 number. |

## floor

```solidity
function floor(SD59x18 x) internal pure returns (SD59x18 result)
```

Yields the greatest whole number less than or equal to x.

\_Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.

Requirements:

- x must be greater than or equal to `MIN_WHOLE_SD59x18`.\_

### Parameters

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| x    | SD59x18 | The SD59x18 number to floor. |

## frac

```solidity
function frac(SD59x18 x) internal pure returns (SD59x18 result)
```

Yields the excess beyond the floor of x for positive numbers and the part of the number to the right.
of the radix point for negative numbers.

_Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part_

### Parameters

| Name | Type    | Description                                       |
| ---- | ------- | ------------------------------------------------- |
| x    | SD59x18 | The SD59x18 number to get the fractional part of. |

## gm

```solidity
function gm(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$.

\_Notes:

- The result is rounded toward zero.

Requirements:

- x \* y must fit in SD59x18.
- x \* y must not be negative, since complex numbers are not supported.\_

### Parameters

| Name | Type    | Description                              |
| ---- | ------- | ---------------------------------------- |
| x    | SD59x18 | The first operand as an SD59x18 number.  |
| y    | SD59x18 | The second operand as an SD59x18 number. |

### Return Values

| Name   | Type    | Description                      |
| ------ | ------- | -------------------------------- |
| result | SD59x18 | The result as an SD59x18 number. |

## inv

```solidity
function inv(SD59x18 x) internal pure returns (SD59x18 result)
```

Calculates the inverse of x.

\_Notes:

- The result is rounded toward zero.

Requirements:

- x must not be zero.\_

### Parameters

| Name | Type    | Description                                            |
| ---- | ------- | ------------------------------------------------------ |
| x    | SD59x18 | The SD59x18 number for which to calculate the inverse. |

### Return Values

| Name   | Type    | Description                       |
| ------ | ------- | --------------------------------- |
| result | SD59x18 | The inverse as an SD59x18 number. |

## ln

```solidity
function ln(SD59x18 x) internal pure returns (SD59x18 result)
```

Calculates the natural logarithm of x using the following formula:

$$
ln{x} = log_2{x} / log_2{e}
$$

\_Notes:

- Refer to the notes in {log2}.
- The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.

Requirements:

- Refer to the requirements in {log2}.\_

### Parameters

| Name | Type    | Description                                                      |
| ---- | ------- | ---------------------------------------------------------------- |
| x    | SD59x18 | The SD59x18 number for which to calculate the natural logarithm. |

### Return Values

| Name   | Type    | Description                                 |
| ------ | ------- | ------------------------------------------- |
| result | SD59x18 | The natural logarithm as an SD59x18 number. |

## log10

```solidity
function log10(SD59x18 x) internal pure returns (SD59x18 result)
```

Calculates the common logarithm of x using the following formula:

$$
log_{10}{x} = log_2{x} / log_2{10}
$$

However, if x is an exact power of ten, a hard coded value is returned.

\_Notes:

- Refer to the notes in {log2}.

Requirements:

- Refer to the requirements in {log2}.\_

### Parameters

| Name | Type    | Description                                                     |
| ---- | ------- | --------------------------------------------------------------- |
| x    | SD59x18 | The SD59x18 number for which to calculate the common logarithm. |

### Return Values

| Name   | Type    | Description                                |
| ------ | ------- | ------------------------------------------ |
| result | SD59x18 | The common logarithm as an SD59x18 number. |

## log2

```solidity
function log2(SD59x18 x) internal pure returns (SD59x18 result)
```

Calculates the binary logarithm of x using the iterative approximation algorithm:

$$
log_2{x} = n + log_2{y}, \text{ where } y = x*2^{-n}, \ y \in [1, 2)
$$

For $0 \leq x \lt 1$, the input is inverted:

$$
log_2{x} = -log_2{\frac{1}{x}}
$$

\_See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation.

Notes:

- Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.

Requirements:

- x must be greater than zero.\_

### Parameters

| Name | Type    | Description                                                     |
| ---- | ------- | --------------------------------------------------------------- |
| x    | SD59x18 | The SD59x18 number for which to calculate the binary logarithm. |

### Return Values

| Name   | Type    | Description                                |
| ------ | ------- | ------------------------------------------ |
| result | SD59x18 | The binary logarithm as an SD59x18 number. |

## mul

```solidity
function mul(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Multiplies two SD59x18 numbers together, returning a new SD59x18 number.

\_Notes:

- Refer to the notes in {Common.mulDiv18}.

Requirements:

- Refer to the requirements in {Common.mulDiv18}.
- None of the inputs can be `MIN_SD59x18`.
- The result must fit in SD59x18.\_

### Parameters

| Name | Type    | Description                            |
| ---- | ------- | -------------------------------------- |
| x    | SD59x18 | The multiplicand as an SD59x18 number. |
| y    | SD59x18 | The multiplier as an SD59x18 number.   |

### Return Values

| Name   | Type    | Description                       |
| ------ | ------- | --------------------------------- |
| result | SD59x18 | The product as an SD59x18 number. |

## pow

```solidity
function pow(SD59x18 x, SD59x18 y) internal pure returns (SD59x18 result)
```

Raises x to the power of y using the following formula:

$$
x^y = 2^{log_2{x} * y}
$$

\_Notes:

- Refer to the notes in {exp2}, {log2}, and {mul}.
- Returns `UNIT` for 0^0.

Requirements:

- Refer to the requirements in {exp2}, {log2}, and {mul}.\_

### Parameters

| Name | Type    | Description                                  |
| ---- | ------- | -------------------------------------------- |
| x    | SD59x18 | The base as an SD59x18 number.               |
| y    | SD59x18 | Exponent to raise x to, as an SD59x18 number |

### Return Values

| Name   | Type    | Description                                |
| ------ | ------- | ------------------------------------------ |
| result | SD59x18 | x raised to power y, as an SD59x18 number. |

## powu

```solidity
function powu(SD59x18 x, uint256 y) internal pure returns (SD59x18 result)
```

Raises x (an SD59x18 number) to the power y (an unsigned basic integer) using the well-known
algorithm "exponentiation by squaring".

\_See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.

Notes:

- Refer to the notes in {Common.mulDiv18}.
- Returns `UNIT` for 0^0.

Requirements:

- Refer to the requirements in {abs} and {Common.mulDiv18}.
- The result must fit in SD59x18.\_

### Parameters

| Name | Type    | Description                    |
| ---- | ------- | ------------------------------ |
| x    | SD59x18 | The base as an SD59x18 number. |
| y    | uint256 | The exponent as a uint256.     |

### Return Values

| Name   | Type    | Description                      |
| ------ | ------- | -------------------------------- |
| result | SD59x18 | The result as an SD59x18 number. |

## sqrt

```solidity
function sqrt(SD59x18 x) internal pure returns (SD59x18 result)
```

Calculates the square root of x using the Babylonian method.

\_See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.

Notes:

- Only the positive root is returned.
- The result is rounded toward zero.

Requirements:

- x cannot be negative, since complex numbers are not supported.
- x must be less than `MAX_SD59x18 / UNIT`.\_

### Parameters

| Name | Type    | Description                                                |
| ---- | ------- | ---------------------------------------------------------- |
| x    | SD59x18 | The SD59x18 number for which to calculate the square root. |

### Return Values

| Name   | Type    | Description                      |
| ------ | ------- | -------------------------------- |
| result | SD59x18 | The result as an SD59x18 number. |

## SD59x18

## intoSD1x18

```solidity
function intoSD1x18(UD2x18 x) internal pure returns (SD1x18 result)
```

Casts a UD2x18 number into SD1x18.

- x must be less than or equal to `uMAX_SD1x18`.

## intoSD59x18

```solidity
function intoSD59x18(UD2x18 x) internal pure returns (SD59x18 result)
```

Casts a UD2x18 number into SD59x18.

_There is no overflow check because the domain of UD2x18 is a subset of SD59x18._

## intoUD60x18

```solidity
function intoUD60x18(UD2x18 x) internal pure returns (UD60x18 result)
```

Casts a UD2x18 number into UD60x18.

_There is no overflow check because the domain of UD2x18 is a subset of UD60x18._

## intoUint128

```solidity
function intoUint128(UD2x18 x) internal pure returns (uint128 result)
```

Casts a UD2x18 number into uint128.

_There is no overflow check because the domain of UD2x18 is a subset of uint128._

## intoUint256

```solidity
function intoUint256(UD2x18 x) internal pure returns (uint256 result)
```

Casts a UD2x18 number into uint256.

_There is no overflow check because the domain of UD2x18 is a subset of uint256._

## intoUint40

```solidity
function intoUint40(UD2x18 x) internal pure returns (uint40 result)
```

Casts a UD2x18 number into uint40.

\_Requirements:

- x must be less than or equal to `MAX_UINT40`.\_

## ud2x18

```solidity
function ud2x18(uint64 x) internal pure returns (UD2x18 result)
```

Alias for {wrap}.

## unwrap

```solidity
function unwrap(UD2x18 x) internal pure returns (uint64 result)
```

Unwrap a UD2x18 number into uint64.

## wrap

```solidity
function wrap(uint64 x) internal pure returns (UD2x18 result)
```

Wraps a uint64 number into UD2x18.

## E

```solidity
UD2x18 E
```

## uMAX_UD2x18

```solidity
uint64 uMAX_UD2x18
```

## MAX_UD2x18

```solidity
UD2x18 MAX_UD2x18
```

## PI

```solidity
UD2x18 PI
```

## uUNIT

```solidity
uint256 uUNIT
```

## UNIT

```solidity
UD2x18 UNIT
```

## PRBMath_UD2x18_IntoSD1x18_Overflow

```solidity
error PRBMath_UD2x18_IntoSD1x18_Overflow(UD2x18 x)
```

Thrown when trying to cast a UD2x18 number that doesn't fit in SD1x18.

## PRBMath_UD2x18_IntoUint40_Overflow

```solidity
error PRBMath_UD2x18_IntoUint40_Overflow(UD2x18 x)
```

Thrown when trying to cast a UD2x18 number that doesn't fit in uint40.

## UD2x18

## intoSD1x18

```solidity
function intoSD1x18(UD60x18 x) internal pure returns (SD1x18 result)
```

Casts a UD60x18 number into SD1x18.

\_Requirements:

- x must be less than or equal to `uMAX_SD1x18`.\_

## intoUD2x18

```solidity
function intoUD2x18(UD60x18 x) internal pure returns (UD2x18 result)
```

Casts a UD60x18 number into UD2x18.

\_Requirements:

- x must be less than or equal to `uMAX_UD2x18`.\_

## intoSD59x18

```solidity
function intoSD59x18(UD60x18 x) internal pure returns (SD59x18 result)
```

Casts a UD60x18 number into SD59x18.

\_Requirements:

- x must be less than or equal to `uMAX_SD59x18`.\_

## intoUint256

```solidity
function intoUint256(UD60x18 x) internal pure returns (uint256 result)
```

Casts a UD60x18 number into uint128.

_This is basically an alias for {unwrap}._

## intoUint128

```solidity
function intoUint128(UD60x18 x) internal pure returns (uint128 result)
```

Casts a UD60x18 number into uint128.

\_Requirements:

- x must be less than or equal to `MAX_UINT128`.\_

## intoUint40

```solidity
function intoUint40(UD60x18 x) internal pure returns (uint40 result)
```

Casts a UD60x18 number into uint40.

\_Requirements:

- x must be less than or equal to `MAX_UINT40`.\_

## ud

```solidity
function ud(uint256 x) internal pure returns (UD60x18 result)
```

Alias for {wrap}.

## ud60x18

```solidity
function ud60x18(uint256 x) internal pure returns (UD60x18 result)
```

Alias for {wrap}.

## unwrap

```solidity
function unwrap(UD60x18 x) internal pure returns (uint256 result)
```

Unwraps a UD60x18 number into uint256.

## wrap

```solidity
function wrap(uint256 x) internal pure returns (UD60x18 result)
```

Wraps a uint256 number into the UD60x18 value type.

## E

```solidity
UD60x18 E
```

## uEXP_MAX_INPUT

```solidity
uint256 uEXP_MAX_INPUT
```

## EXP_MAX_INPUT

```solidity
UD60x18 EXP_MAX_INPUT
```

## uEXP2_MAX_INPUT

```solidity
uint256 uEXP2_MAX_INPUT
```

## EXP2_MAX_INPUT

```solidity
UD60x18 EXP2_MAX_INPUT
```

## uHALF_UNIT

```solidity
uint256 uHALF_UNIT
```

## HALF_UNIT

```solidity
UD60x18 HALF_UNIT
```

## uLOG2_10

```solidity
uint256 uLOG2_10
```

## LOG2_10

```solidity
UD60x18 LOG2_10
```

## uLOG2_E

```solidity
uint256 uLOG2_E
```

## LOG2_E

```solidity
UD60x18 LOG2_E
```

## uMAX_UD60x18

```solidity
uint256 uMAX_UD60x18
```

## MAX_UD60x18

```solidity
UD60x18 MAX_UD60x18
```

## uMAX_WHOLE_UD60x18

```solidity
uint256 uMAX_WHOLE_UD60x18
```

## MAX_WHOLE_UD60x18

```solidity
UD60x18 MAX_WHOLE_UD60x18
```

## PI

```solidity
UD60x18 PI
```

## uUNIT

```solidity
uint256 uUNIT
```

## UNIT

```solidity
UD60x18 UNIT
```

## uUNIT_SQUARED

```solidity
uint256 uUNIT_SQUARED
```

## UNIT_SQUARED

```solidity
UD60x18 UNIT_SQUARED
```

## ZERO

```solidity
UD60x18 ZERO
```

## convert

```solidity
function convert(UD60x18 x) internal pure returns (uint256 result)
```

Converts a UD60x18 number to a simple integer by dividing it by `UNIT`.

_The result is rounded toward zero._

### Parameters

| Name | Type    | Description                    |
| ---- | ------- | ------------------------------ |
| x    | UD60x18 | The UD60x18 number to convert. |

### Return Values

| Name   | Type    | Description                            |
| ------ | ------- | -------------------------------------- |
| result | uint256 | The same number in basic integer form. |

## convert

```solidity
function convert(uint256 x) internal pure returns (UD60x18 result)
```

Converts a simple integer to UD60x18 by multiplying it by `UNIT`.

\_Requirements:

- x must be less than or equal to `MAX_UD60x18 / UNIT`.\_

### Parameters

| Name | Type    | Description                   |
| ---- | ------- | ----------------------------- |
| x    | uint256 | The basic integer to convert. |

## PRBMath_UD60x18_Ceil_Overflow

```solidity
error PRBMath_UD60x18_Ceil_Overflow(UD60x18 x)
```

Thrown when ceiling a number overflows UD60x18.

## PRBMath_UD60x18_Convert_Overflow

```solidity
error PRBMath_UD60x18_Convert_Overflow(uint256 x)
```

Thrown when converting a basic integer to the fixed-point format overflows UD60x18.

## PRBMath_UD60x18_Exp_InputTooBig

```solidity
error PRBMath_UD60x18_Exp_InputTooBig(UD60x18 x)
```

Thrown when taking the natural exponent of a base greater than 133_084258667509499441.

## PRBMath_UD60x18_Exp2_InputTooBig

```solidity
error PRBMath_UD60x18_Exp2_InputTooBig(UD60x18 x)
```

Thrown when taking the binary exponent of a base greater than 192e18.

## PRBMath_UD60x18_Gm_Overflow

```solidity
error PRBMath_UD60x18_Gm_Overflow(UD60x18 x, UD60x18 y)
```

Thrown when taking the geometric mean of two numbers and multiplying them overflows UD60x18.

## PRBMath_UD60x18_IntoSD1x18_Overflow

```solidity
error PRBMath_UD60x18_IntoSD1x18_Overflow(UD60x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in SD1x18.

## PRBMath_UD60x18_IntoSD59x18_Overflow

```solidity
error PRBMath_UD60x18_IntoSD59x18_Overflow(UD60x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in SD59x18.

## PRBMath_UD60x18_IntoUD2x18_Overflow

```solidity
error PRBMath_UD60x18_IntoUD2x18_Overflow(UD60x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in UD2x18.

## PRBMath_UD60x18_IntoUint128_Overflow

```solidity
error PRBMath_UD60x18_IntoUint128_Overflow(UD60x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in uint128.

## PRBMath_UD60x18_IntoUint40_Overflow

```solidity
error PRBMath_UD60x18_IntoUint40_Overflow(UD60x18 x)
```

Thrown when trying to cast a UD60x18 number that doesn't fit in uint40.

## PRBMath_UD60x18_Log_InputTooSmall

```solidity
error PRBMath_UD60x18_Log_InputTooSmall(UD60x18 x)
```

Thrown when taking the logarithm of a number less than 1.

## PRBMath_UD60x18_Sqrt_Overflow

```solidity
error PRBMath_UD60x18_Sqrt_Overflow(UD60x18 x)
```

Thrown when calculating the square root overflows UD60x18.

## add

```solidity
function add(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Implements the checked addition operation (+) in the UD60x18 type.

## and

```solidity
function and(UD60x18 x, uint256 bits) internal pure returns (UD60x18 result)
```

Implements the AND (&) bitwise operation in the UD60x18 type.

## and2

```solidity
function and2(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Implements the AND (&) bitwise operation in the UD60x18 type.

## eq

```solidity
function eq(UD60x18 x, UD60x18 y) internal pure returns (bool result)
```

Implements the equal operation (==) in the UD60x18 type.

## gt

```solidity
function gt(UD60x18 x, UD60x18 y) internal pure returns (bool result)
```

Implements the greater than operation (>) in the UD60x18 type.

## gte

```solidity
function gte(UD60x18 x, UD60x18 y) internal pure returns (bool result)
```

Implements the greater than or equal to operation (>=) in the UD60x18 type.

## isZero

```solidity
function isZero(UD60x18 x) internal pure returns (bool result)
```

Implements a zero comparison check function in the UD60x18 type.

## lshift

```solidity
function lshift(UD60x18 x, uint256 bits) internal pure returns (UD60x18 result)
```

Implements the left shift operation (<<) in the UD60x18 type.

## lt

```solidity
function lt(UD60x18 x, UD60x18 y) internal pure returns (bool result)
```

Implements the lower than operation (<) in the UD60x18 type.

## lte

```solidity
function lte(UD60x18 x, UD60x18 y) internal pure returns (bool result)
```

Implements the lower than or equal to operation (<=) in the UD60x18 type.

## mod

```solidity
function mod(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Implements the checked modulo operation (%) in the UD60x18 type.

## neq

```solidity
function neq(UD60x18 x, UD60x18 y) internal pure returns (bool result)
```

Implements the not equal operation (!=) in the UD60x18 type.

## not

```solidity
function not(UD60x18 x) internal pure returns (UD60x18 result)
```

Implements the NOT (~) bitwise operation in the UD60x18 type.

## or

```solidity
function or(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Implements the OR (|) bitwise operation in the UD60x18 type.

## rshift

```solidity
function rshift(UD60x18 x, uint256 bits) internal pure returns (UD60x18 result)
```

Implements the right shift operation (>>) in the UD60x18 type.

## sub

```solidity
function sub(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Implements the checked subtraction operation (-) in the UD60x18 type.

## uncheckedAdd

```solidity
function uncheckedAdd(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Implements the unchecked addition operation (+) in the UD60x18 type.

## uncheckedSub

```solidity
function uncheckedSub(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Implements the unchecked subtraction operation (-) in the UD60x18 type.

## xor

```solidity
function xor(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Implements the XOR (^) bitwise operation in the UD60x18 type.

## avg

```solidity
function avg(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Calculates the arithmetic average of x and y using the following formula:

$$
avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
$$

In English, this is what this formula does:

1. AND x and y.
2. Calculate half of XOR x and y.
3. Add the two results together.

This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223

\_Notes:

- The result is rounded toward zero.\_

### Parameters

| Name | Type    | Description                             |
| ---- | ------- | --------------------------------------- |
| x    | UD60x18 | The first operand as a UD60x18 number.  |
| y    | UD60x18 | The second operand as a UD60x18 number. |

### Return Values

| Name   | Type    | Description                                 |
| ------ | ------- | ------------------------------------------- |
| result | UD60x18 | The arithmetic average as a UD60x18 number. |

## ceil

```solidity
function ceil(UD60x18 x) internal pure returns (UD60x18 result)
```

Yields the smallest whole number greater than or equal to x.

\_This is optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional
counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.

Requirements:

- x must be less than or equal to `MAX_WHOLE_UD60x18`.\_

### Parameters

| Name | Type    | Description                 |
| ---- | ------- | --------------------------- |
| x    | UD60x18 | The UD60x18 number to ceil. |

## div

```solidity
function div(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Divides two UD60x18 numbers, returning a new UD60x18 number.

\_Uses {Common.mulDiv} to enable overflow-safe multiplication and division.

Notes:

- Refer to the notes in {Common.mulDiv}.

Requirements:

- Refer to the requirements in {Common.mulDiv}.\_

### Parameters

| Name | Type    | Description                          |
| ---- | ------- | ------------------------------------ |
| x    | UD60x18 | The numerator as a UD60x18 number.   |
| y    | UD60x18 | The denominator as a UD60x18 number. |

## exp

```solidity
function exp(UD60x18 x) internal pure returns (UD60x18 result)
```

Calculates the natural exponent of x using the following formula:

$$
e^x = 2^{x * log_2{e}}
$$

\_Requirements:

- x must be less than 133*084258667509499441.*

### Parameters

| Name | Type    | Description                       |
| ---- | ------- | --------------------------------- |
| x    | UD60x18 | The exponent as a UD60x18 number. |

### Return Values

| Name   | Type    | Description                     |
| ------ | ------- | ------------------------------- |
| result | UD60x18 | The result as a UD60x18 number. |

## exp2

```solidity
function exp2(UD60x18 x) internal pure returns (UD60x18 result)
```

Calculates the binary exponent of x using the binary fraction method.

\_See https://ethereum.stackexchange.com/q/79903/24693

Requirements:

- x must be less than 192e18.
- The result must fit in UD60x18.\_

### Parameters

| Name | Type    | Description                       |
| ---- | ------- | --------------------------------- |
| x    | UD60x18 | The exponent as a UD60x18 number. |

### Return Values

| Name   | Type    | Description                     |
| ------ | ------- | ------------------------------- |
| result | UD60x18 | The result as a UD60x18 number. |

## floor

```solidity
function floor(UD60x18 x) internal pure returns (UD60x18 result)
```

Yields the greatest whole number less than or equal to x.

_Optimized for fractional value inputs, because every whole value has (1e18 - 1) fractional counterparts.
See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions._

### Parameters

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| x    | UD60x18 | The UD60x18 number to floor. |

## frac

```solidity
function frac(UD60x18 x) internal pure returns (UD60x18 result)
```

Yields the excess beyond the floor of x using the odd function definition.

_See https://en.wikipedia.org/wiki/Fractional_part._

### Parameters

| Name | Type    | Description                                       |
| ---- | ------- | ------------------------------------------------- |
| x    | UD60x18 | The UD60x18 number to get the fractional part of. |

## gm

```solidity
function gm(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Calculates the geometric mean of x and y, i.e. $\sqrt{x * y}$, rounding down.

\_Requirements:

- x \* y must fit in UD60x18.\_

### Parameters

| Name | Type    | Description                             |
| ---- | ------- | --------------------------------------- |
| x    | UD60x18 | The first operand as a UD60x18 number.  |
| y    | UD60x18 | The second operand as a UD60x18 number. |

### Return Values

| Name   | Type    | Description                     |
| ------ | ------- | ------------------------------- |
| result | UD60x18 | The result as a UD60x18 number. |

## inv

```solidity
function inv(UD60x18 x) internal pure returns (UD60x18 result)
```

Calculates the inverse of x.

\_Notes:

- The result is rounded toward zero.

Requirements:

- x must not be zero.\_

### Parameters

| Name | Type    | Description                                            |
| ---- | ------- | ------------------------------------------------------ |
| x    | UD60x18 | The UD60x18 number for which to calculate the inverse. |

### Return Values

| Name   | Type    | Description                      |
| ------ | ------- | -------------------------------- |
| result | UD60x18 | The inverse as a UD60x18 number. |

## ln

```solidity
function ln(UD60x18 x) internal pure returns (UD60x18 result)
```

Calculates the natural logarithm of x using the following formula:

$$
ln{x} = log_2{x} / log_2{e}
$$

\_Notes:

- Refer to the notes in {log2}.
- The precision isn't sufficiently fine-grained to return exactly `UNIT` when the input is `E`.

Requirements:

- Refer to the requirements in {log2}.\_

### Parameters

| Name | Type    | Description                                                      |
| ---- | ------- | ---------------------------------------------------------------- |
| x    | UD60x18 | The UD60x18 number for which to calculate the natural logarithm. |

### Return Values

| Name   | Type    | Description                                |
| ------ | ------- | ------------------------------------------ |
| result | UD60x18 | The natural logarithm as a UD60x18 number. |

## log10

```solidity
function log10(UD60x18 x) internal pure returns (UD60x18 result)
```

Calculates the common logarithm of x using the following formula:

$$
log_{10}{x} = log_2{x} / log_2{10}
$$

However, if x is an exact power of ten, a hard coded value is returned.

\_Notes:

- Refer to the notes in {log2}.

Requirements:

- Refer to the requirements in {log2}.\_

### Parameters

| Name | Type    | Description                                                     |
| ---- | ------- | --------------------------------------------------------------- |
| x    | UD60x18 | The UD60x18 number for which to calculate the common logarithm. |

### Return Values

| Name   | Type    | Description                               |
| ------ | ------- | ----------------------------------------- |
| result | UD60x18 | The common logarithm as a UD60x18 number. |

## log2

```solidity
function log2(UD60x18 x) internal pure returns (UD60x18 result)
```

Calculates the binary logarithm of x using the iterative approximation algorithm:

$$
log_2{x} = n + log_2{y}, \text{ where } y = x*2^{-n}, \ y \in [1, 2)
$$

For $0 \leq x \lt 1$, the input is inverted:

$$
log_2{x} = -log_2{\frac{1}{x}}
$$

\_See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation

Notes:

- Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.

Requirements:

- x must be greater than zero.\_

### Parameters

| Name | Type    | Description                                                     |
| ---- | ------- | --------------------------------------------------------------- |
| x    | UD60x18 | The UD60x18 number for which to calculate the binary logarithm. |

### Return Values

| Name   | Type    | Description                               |
| ------ | ------- | ----------------------------------------- |
| result | UD60x18 | The binary logarithm as a UD60x18 number. |

## mul

```solidity
function mul(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Multiplies two UD60x18 numbers together, returning a new UD60x18 number.

\_Uses {Common.mulDiv} to enable overflow-safe multiplication and division.

Notes:

- Refer to the notes in {Common.mulDiv}.

Requirements:

- Refer to the requirements in {Common.mulDiv}.

See the documentation in {Common.mulDiv18}.\_

### Parameters

| Name | Type    | Description                           |
| ---- | ------- | ------------------------------------- |
| x    | UD60x18 | The multiplicand as a UD60x18 number. |
| y    | UD60x18 | The multiplier as a UD60x18 number.   |

### Return Values

| Name   | Type    | Description                      |
| ------ | ------- | -------------------------------- |
| result | UD60x18 | The product as a UD60x18 number. |

## pow

```solidity
function pow(UD60x18 x, UD60x18 y) internal pure returns (UD60x18 result)
```

Raises x to the power of y.

For $1 \leq x \leq \infty$, the following standard formula is used:

$$
x^y = 2^{log_2{x} * y}
$$

For $0 \leq x \lt 1$, since the unsigned {log2} is undefined, an equivalent formula is used:

$$
i = \frac{1}{x}
w = 2^{log_2{i} * y}
x^y = \frac{1}{w}
$$

\_Notes:

- Refer to the notes in {log2} and {mul}.
- Returns `UNIT` for 0^0.
- It may not perform well with very small values of x. Consider using SD59x18 as an alternative.

Requirements:

- Refer to the requirements in {exp2}, {log2}, and {mul}.\_

### Parameters

| Name | Type    | Description                       |
| ---- | ------- | --------------------------------- |
| x    | UD60x18 | The base as a UD60x18 number.     |
| y    | UD60x18 | The exponent as a UD60x18 number. |

### Return Values

| Name   | Type    | Description                     |
| ------ | ------- | ------------------------------- |
| result | UD60x18 | The result as a UD60x18 number. |

## powu

```solidity
function powu(UD60x18 x, uint256 y) internal pure returns (UD60x18 result)
```

Raises x (a UD60x18 number) to the power y (an unsigned basic integer) using the well-known
algorithm "exponentiation by squaring".

\_See https://en.wikipedia.org/wiki/Exponentiation_by_squaring.

Notes:

- Refer to the notes in {Common.mulDiv18}.
- Returns `UNIT` for 0^0.

Requirements:

- The result must fit in UD60x18.\_

### Parameters

| Name | Type    | Description                   |
| ---- | ------- | ----------------------------- |
| x    | UD60x18 | The base as a UD60x18 number. |
| y    | uint256 | The exponent as a uint256.    |

### Return Values

| Name   | Type    | Description                     |
| ------ | ------- | ------------------------------- |
| result | UD60x18 | The result as a UD60x18 number. |

## sqrt

```solidity
function sqrt(UD60x18 x) internal pure returns (UD60x18 result)
```

Calculates the square root of x using the Babylonian method.

\_See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.

Notes:

- The result is rounded toward zero.

Requirements:

- x must be less than `MAX_UD60x18 / UNIT`.\_

### Parameters

| Name | Type    | Description                                                |
| ---- | ------- | ---------------------------------------------------------- |
| x    | UD60x18 | The UD60x18 number for which to calculate the square root. |

### Return Values

| Name   | Type    | Description                     |
| ------ | ------- | ------------------------------- |
| result | UD60x18 | The result as a UD60x18 number. |

## UD60x18
