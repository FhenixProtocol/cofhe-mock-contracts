// import axios from 'axios'

import { HardhatRuntimeEnvironment } from 'hardhat/types'

export const TASK_MANAGER_ADDRESS = '0xeA30c4B8b44078Bbf8a6ef5b9f1eC1626C7848D9'
export const ZK_VERIFIER_ADDRESS = '0x0000000000000000000000000000000000000100'
export const QUERY_DECRYPTER_ADDRESS = '0x0000000000000000000000000000000000000200'

// export const anvilSetCode = async (address: string, bytecode: string) => {
// 	await axios.post('http://127.0.0.1:8545', {
// 		jsonrpc: '2.0',
// 		method: 'anvil_setCode',
// 		params: [address, bytecode],
// 		id: 1,
// 	})
// }

export const hardhatSetCode = async (hre: HardhatRuntimeEnvironment, address: string, bytecode: string) => {
	await hre.network.provider.send('hardhat_setCode', [address, bytecode])
}
