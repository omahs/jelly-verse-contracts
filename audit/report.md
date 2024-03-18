# Introduction

A time-boxed practice security review of the **JellyVerse** protocol was done by **vani**.

# Disclaimer

A smart contract security review can never verify the complete absence of vulnerabilities. This is a time, resource and expertise bound effort where I try to find as many vulnerabilities as possible. I can not guarantee 100% security after the review or even if the review will find any problems with your smart contracts. Subsequent security reviews, bug bounty programs and on-chain monitoring are strongly recommended.

# About **JellyVerse**
TBF
## Observations
TBF
## Privileged Roles & Actors
TBF
# Severity classification

| Severity               | Impact: High | Impact: Medium | Impact: Low |
| ---------------------- | ------------ | -------------- | ----------- |
| **Likelihood: High**   | Critical     | High           | Medium      |
| **Likelihood: Medium** | High         | Medium         | Low         |
| **Likelihood: Low**    | Medium       | Low            | Low         |

**Impact** - the technical, economic and reputation damage of a successful attack

**Likelihood** - the chance that a particular vulnerability gets discovered and exploited

**Severity** - the overall criticality of the risk

# Security Assessment Summary

**_review commit hash_ - [bc27b5fe86e714a9266ea9cbc5c483a7381d7c1a](https://github.com/MVPWorkshop/jelly-verse-contracts/commit/bc27b5fe86e714a9266ea9cbc5c483a7381d7c1a)**

**No fixes implemented.**

### Scope

The following smart contracts were in scope of the audit:

- `JellyToken.sol`
- `JellyTokenDeployer.sol`
- `DailySnapshot.sol`
- `OfficialPoolRegister.sol`
- `VestingLib.sol`
- `VestingLibChest.sol`

---

The following number of issues were found, categorized by their severity:

- High: 3 issues
- Medium: 2 issues
- Low: 5 issues
- Informational: 3 issues

# Findings Summary

| ID     | Title                                       | Severity      |
| ------ | ------------------------------------------- | ------------- |
| [H-01] | Faulty Randomness Generation                | High          |
| [H-02] | Hardcoded Block Time Dependency             | High          |
| [H-03] | Underflow in `releasableAmount` Calculation | High          |
| [M-01] | Minting of `JellyToken` is centralized      | Medium        |
| [M-02] | Burned Tokens Can Be Reissued by Minters    | Medium        |
| [L-01] | Missing input validation in constructor     | Low           |
| [L-02] | Missing input validation in premint         | Low           |
| [L-03] | No Check for Duplicate Pool Registration    | Low           |
| [L-04] | Wasteful Pool Registration Logic            | Low           |
| [L-05] | Redundant Pool Struct                       | Low           |
| [I-01] | Suboptimal Storage Layout                   | Informational |
| [I-02] | Suboptimal Storage Layout for Struct        | Informational |
| [I-03] | Code Style Enhancements                     | Informational |

# Detailed Findings

# [H-01] Faulty Randomness Generation

Use of `block.prevrandao` as random seed, depends heavily on the selected chain.

## Recommendations

Consider using a decentralized oracle for the generation of random numbers. If `DailySnapshot` data is solely for off-chain purposes, consider moving the entire process off-chain to avoid on-chain manipulation, as the data isn't utilized within the smart contract itself.

# [H-02] Hardcoded Block Time Dependency

The contract assumes a fixed number of blocks per day (`ONE_DAY = 7200`), which is a brittle design choice because block times can vary and change. This can lead to inaccuracies in determining the start of a new day.

## Recommendations

Replace the reliance on block numbers with Unix timestamps, which are consistent and independent of block time variability.

# [H-03] Underflow in `releasableAmount` Calculation

## Severity

**Impact:**
High, as this underflow can cause the releasableAmount function to revert, potentially disrupting the intended vesting mechanics.

**Likelihood:**
Medium, depends on the usage of the vesting library. If positions are not updated, the problem won't exist.

## Descripton

An underflow occurs in the `releasableAmount` function when a vesting position's total amount is increased after some tokens have been released. The test case demonstrates this by creating a vesting position, releasing part of the vested tokens, and then updating the position with an increased total vested amount and a new future cliff. When releasableAmount is called after the new cliff, the calculation underflows because it subtracts the previously released amount from the newly vested amount, which is not yet greater than the released amount due to the vesting schedule reset.

```solidity
function test_vestingLib() external {
    address beneficiary = msg.sender;
    uint256 amount = 1000;
    uint32 cliffDuration = 100;
    uint32 vestingDuration = 100;

    uint256 withrawAmount = 500;

    // Initial position state
    // totalVestedAmount = 1000
    // releasedAmount = 0
    // cliffDuration = 100
    // vestingDuration = 100
    VestingLib.VestingPosition memory vestingPosition =
        createVestingPosition(amount, beneficiary, cliffDuration, vestingDuration);
    uint256 positionIndex = index - 1;

    vm.warp(vestingPosition.cliffTimestamp + vestingDuration);

    updateReleasedAmount(0, withrawAmount);

    // Now imagine update of position happens
    vestingPositions[positionIndex].totalVestedAmount += amount; // totalVestedAmount is now 2x amount
    vestingPositions[positionIndex].cliffTimestamp = uint48(block.timestamp + cliffDuration);

    vm.warp(vestingPositions[positionIndex].cliffTimestamp + 1);
    vm.expectRevert();
    uint256 releasableAmount = releasableAmount(0);
}
```

## Recommendations

Ensure that any updates to vesting positions properly handle previously released amounts to prevent underflow.

# [M-01] Minting of `JellyToken` is centralized

## Severity

**Impact:**
High, as token supply can be minted to cap value at any moment.

**Likelihood:**
Low, as it requires a malicious or compromised admin/minter

## Description

Currently the `mint` method in `JellyToken` is controlled by `MINTER_ROLE`. Minter roles are controlled by the `DEFAULT_ADMIN_ROLE` which is given to the `_defaultAdminRole` on deployment. This means that if the admin or minter account is malicious or compromised it can decide to mint token supply to cap which would lead to a loss of funds for users.

## Recommendations

Give those roles only to contracts that have a Timelock mechanism so that users have enough time to exit their `JellyToken` positions if they decide that they don't agree with a transaction of the admin/minter.

# [M-02] Burned Tokens Can Be Reissued by Minters

This issue permits any entity with the `Minter` role to re-mint tokens that have been previously burned. This could affect scenarios like a presale where unsold tokens are burned, as they might be re-minted later. It's important to verify within the tokenomics whether the cap refers to the circulating supply or the total minted supply.

# [L-01] Missing input validation in constructor

The `_defaultAdminRole `is a critical parameter in the `JellyToken` contract, initialized in the constructor. Assigning a address zero to this parameter would require re-deployment.

```diff
+ if (_defaultAdminRole == address(0)) {
+   revert CustomError();
+ }
```

# [L-02] Missing input validation in premint function

The `_minterContract `is a parameter passed in the `JellyToken` contract in the `premint` function. Assigning a role to address zero would require doing the action again.

```diff
+ if (_minterContract == address(0)) {
+   revert CustomError();
+ }
```

# [L-03] No Check for Duplicate Pool Registration

The `registerOfficialPool` function doesn't prevent registering a pool more than once. Add a check to avoid duplicates.

# [L-04] Wasteful Pool Registration Logic

Updating the list of official pools requires clearing and re-adding all pools, which is inefficient. Improve the update process to modify only what's necessary.
Check `OfficialPoolsRegisterNew.sol` implementation for reference.

# [L-05] Redundant Pool Struct

The `Pool` struct is not effectively used. Remove it if the `weight` field is unnecessary, and simplify the pool registration process.

# [I-01] Suboptimal Storage Layout

The contract's storage layout is suboptimal, with `beginningOfTheNewDayBlocknumber` unnecessarily consuming a full 32-byte storage slot. Reducing `epoch` and `beginningOfTheNewDayBlocknumber` types to uint40 allows for tighter packing of these state variables.

```diff
-uint48 public epoch;
+uint40 public epoch;
-uint48 public beginningOfTheNewDayBlocknumber;
+uint40 public beginningOfTheNewDayBlocknumber;
```

# [I-02] Suboptimal Storage Layout for Struct

The original order of fields within the `VestingPosition` struct is not optimized. By rearranging the fields to group variables of similar types and sizes together, we can minimize storage slots used and reduce gas costs for contract operations involving this struct.

```diff
- struct VestingPosition {
-   address beneficiary;
-   uint256 totalVestedAmount;
-   uint256 releasedAmount;
-   uint48 cliffTimestamp;
-   uint32 vestingDuration;
- }

+struct VestingPosition {
+   uint256 totalVestedAmount;
+   uint256 releasedAmount;
+   address beneficiary;
+   uint48 cliffTimestamp;
+   uint32 vestingDuration;
+ }
```

# [I-03] Code Style Enhancements

- Replace hardcoded magic numbers with named constants for better code clarity.
- Correct spelling errors, such as changing "Snapshoting" to "Snapshotting," for consistency and professionalism.
- Utilize the import { } from syntax to maintain clean and organized code imports.
- Follow the official Solidity style guide. The current declaration style in `VestingLib/VestingLibChest` lacks consistency and does not align with the recommended guidelines.
