# JellyStaking

Jellyverse introduces a staking system where users can create multiple staking positions, each represented as a soul-bounded NFT called "Chest." These chests allow for distinct and flexible management of Jelly tokens, enabling actions such as deposits, withdrawals, or locking of tokens for enhanced voting power and returns.

## Types of chests

### Regular Chests

Regular Chests enable users to stake JLY tokens with adjustable freezing periods up to three years. The minimum staking amount is 1,000 JLY tokens. Users can freely add funds or increase the freezing period to their chests, provided the total staked amount never drops below the minimum requirement and the freezing period is within the defined range, minimum 7 days and maximum 3\*365 days.

### Special Chests

Special Chests are designed for committed partners or investors, allowing for longer freezing periods of up to five years with a vesting schedule. These chests require a minimum of 1,000 JLY tokens and cannot be modified once created.

## Voting power

Only frozen chests have voting power; if they are open, the voting power is 0.

### Regular Chest

The voting power in a Regular Chest is calculated based on the amount of tokens staked and the length of the freezing period. The system introduces a dynamic "booster" mechanism that increases voting power incrementally the longer the tokens are staked. Regular chests do not utilize a nerf parameter, thus providing a straightforward enhancement to the user's governance capabilities.

### Special Chest

Special Chests calculate voting power by considering the staked amount, the freezing duration, vesting period, and a nerf parameter. Special Chests do not obtain a booster.

### Booster

In Regular Chests, the booster starts with an initial value and increases weekly, capped at twice the initial value. This mechanism incentivizes prolonged staking by progressively increasing the voting power of long-term stakers. Chest booster is accumulated and the starting point is higher if you had your chest frozen for some period. On unstake, it resets to the initial value.

### Nerf Parameter

Exclusive to Special Chests, the nerf parameter adjusts the voting power to prevent large stakeholders from having disproportionately high influence. This parameter reduces the voting power in a way that balances equity among participants, ensuring a fair governance process.

### Invariants

- Chest is soul-bounded.
- User cannot withdraw more than deposited.
- Booster shouldn't have a value bigger than the maximum.
- Special chest can't be modified.
- An open chest shouldn't have voting power.
