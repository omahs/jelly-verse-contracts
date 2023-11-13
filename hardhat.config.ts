import * as dotenv from 'dotenv';

import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-chai-matchers';
import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-network-helpers';
import './deployment';

dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ETHEREUM_SEPOLIA_RPC_URL = process.env.ETHEREUM_SEPOLIA_RPC_URL;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const DMC_CHANGI_RPC_URL = process.env.DMC_CHANGI_RPC_URL;
const DMC_CHANGI_API_URL = process.env.DMC_CHANGI_API_URL;
const DMC_CHANGI_BROWSER_URL = process.env.DMC_CHANGI_BROWSER_URL;

const DMC_TESTNET3_RPC_URL = process.env.DMC_TESTNET3_RPC_URL;
const DMC_TESTNET3_API_URL = process.env.DMC_TESTNET3_API_URL;
const DMC_TESTNET3_BROWSER_URL = process.env.DMC_TESTNET3_BROWSER_URL;

const BLOCKSCOUT_DMC_API_KEY = process.env.BLOCKSCOUT_DMC_API_KEY;

const config: HardhatUserConfig = {
	solidity: '0.8.19',
	networks: {
		hardhat: {
			chainId: 31337,
		},
		sepolia: {
			url:
				ETHEREUM_SEPOLIA_RPC_URL !== undefined ? ETHEREUM_SEPOLIA_RPC_URL : '',
			accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
			chainId: 11155111,
		},
		changi: {
			url:
				DMC_CHANGI_RPC_URL !== undefined ? DMC_CHANGI_RPC_URL : '',
			accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
			chainId: 1133,
		},
		testnet3: {
			url:
				DMC_TESTNET3_RPC_URL !== undefined ? DMC_TESTNET3_RPC_URL : '',
			accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
			chainId: 1131,
		}
	},
	etherscan: {
		// npx hardhat verify --network rinkeby {contractAddress} [{constructor arguments}]
		apiKey: {
			sepolia: ETHERSCAN_API_KEY !== undefined ? ETHERSCAN_API_KEY : '',
			dmc: BLOCKSCOUT_DMC_API_KEY !== undefined ? BLOCKSCOUT_DMC_API_KEY : ''
		},
		customChains: [
			{
				network: "changi",
				chainId: 1133,
				urls: {
					apiURL: DMC_CHANGI_API_URL !== undefined ? DMC_CHANGI_API_URL : '',
					browserURL: DMC_CHANGI_BROWSER_URL !== undefined ? DMC_CHANGI_BROWSER_URL : '',
				}
			},
			{
				network: "testnet3",
				chainId: 1131,
				urls: {
					apiURL: DMC_TESTNET3_API_URL !== undefined ? DMC_TESTNET3_API_URL : '',
					browserURL: DMC_TESTNET3_BROWSER_URL !== undefined ? DMC_TESTNET3_BROWSER_URL : '',
				}
			},
		]
	},
};

export default config;
