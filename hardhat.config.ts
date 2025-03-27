import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import '@nomicfoundation/hardhat-ethers'

import './tasks'

const config: HardhatUserConfig = {
	solidity: {
		version: '0.8.28',
		settings: {
			evmVersion: 'cancun',
		},
	},
	networks: {
		hardhat: {
			chainId: 31337,
		},
	},
}

export default config
