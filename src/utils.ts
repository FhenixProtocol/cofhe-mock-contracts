import { HardhatRuntimeEnvironment } from 'hardhat/types'

export const hardhatSetCode = async (hre: HardhatRuntimeEnvironment, address: string, bytecode: string) => {
	await hre.network.provider.send('hardhat_setCode', [address, bytecode])
}
