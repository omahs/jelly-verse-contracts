# Jelly Verse Contracts

## Project Overview

[Brief description of the project, its purpose, and key functionalities.]

## Technical Description

This project is developed using Solidity as the primary programming language for smart contract development. For testing and deployment, it leverages both Hardhat and Foundry.

## Testing instructions

### Prerequisites

Be sure to have installed the following

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Current LTS Node.js version](https://nodejs.org/en/about/releases/)

### Build & Compile

1. Clone the repo

```shell
git clone git@github.com:MVPWorkshop/jelly-verse-contracts.git && cd jelly-verse-contracts
```

2. Install packages

```shell
npm install
```

3. Install [Foundry](https://book.getfoundry.sh/getting-started/installation)

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

4. Compile contracts

```shell
npx hardhat compile
```

[Optionally]

```shell
forge build
```

5. Run tests

```shell
npx hardhat test
```

6. Run invariant tests

```shell
forge test
```

7. Get storage layout of contract

```shell
docker run -v $PWD:/src ethereum/solc:0.8.19 --storage-layout /src/contracts/Chest.sol
```

## Smart contracts scope

This project consists of the following smart contracts:

- [JellyToken](./contracts/JellyToken.sol)
- [Vesting](./contracts/Vesting.sol)
- [VestingJelly](./contracts/VestingJelly.sol)
- [Allocator](./contracts/Allocator.sol)
- [Chest](./contracts/Chest.sol)

## JellyToken.sol

### Contract Overview

[Brief description of the project, its purpose, and key functionalities.]

### Dependencies

**Inherits:**
[ERC20Capped](/contracts/vendor/openzeppelin/v4.9.0/token/ERC20/extensions/ERC20Capped.sol/abstract.ERC20Capped.md), [AccessControl](/contracts/vendor/openzeppelin/v4.9.0/access/AccessControl.sol/abstract.AccessControl.md), [ReentrancyGuard](/contracts/vendor/openzeppelin/v4.9.0/security/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)

### State Variables

##### MINTER_ROLE

```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
```

##### preminted

```solidity
bool internal preminted;
```

| Name          | Type                                              | Slot | Offset | Bytes | Contract                            |
| ------------- | ------------------------------------------------- | ---- | ------ | ----- | ----------------------------------- |
| \_balances    | mapping(address => uint256)                       | 0    | 0      | 32    | contracts/JellyToken.sol:JellyToken |
| \_allowances  | mapping(address => mapping(address => uint256))   | 1    | 0      | 32    | contracts/JellyToken.sol:JellyToken |
| \_totalSupply | uint256                                           | 2    | 0      | 32    | contracts/JellyToken.sol:JellyToken |
| \_name        | string                                            | 3    | 0      | 32    | contracts/JellyToken.sol:JellyToken |
| \_symbol      | string                                            | 4    | 0      | 32    | contracts/JellyToken.sol:JellyToken |
| \_roles       | mapping(bytes32 => struct AccessControl.RoleData) | 5    | 0      | 32    | contracts/JellyToken.sol:JellyToken |
| \_status      | uint256                                           | 6    | 0      | 32    | contracts/JellyToken.sol:JellyToken |
| preminted     | bool                                              | 7    | 0      | 1     | contracts/JellyToken.sol:JellyToken |

### Functions

##### onlyOnce

```solidity
modifier onlyOnce();
```

##### constructor

```solidity
constructor(address _defaultAdminRole) ERC20("Jelly Token", "JLY") ERC20Capped(1_000_000_000 * 10 ** decimals());
```

##### premint

```solidity
function premint(address _vesting, address _vestingJelly, address _allocator, address _minterContract)
    external
    onlyRole(MINTER_ROLE)
    onlyOnce
    nonReentrant;
```

##### mint

Mints specified amount of tokens to address.

_Only addresses with MINTER_ROLE can call._

```solidity
function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE);
```

**Parameters**

| Name     | Type      | Description                                              |
| -------- | --------- | -------------------------------------------------------- |
| `to`     | `address` | - address to mint tokens for.                            |
| `amount` | `uint256` | - amount of tokens to mint. No return, reverts on error. |

### Events & Errors

##### Preminted

```solidity
event Preminted(address indexed vesting, address indexed vestingJelly, address indexed allocator);
```

##### JellyToken\_\_AlreadyPreminted

```solidity
error JellyToken__AlreadyPreminted();
```
