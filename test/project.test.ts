/* tslint:disable-next-line */
import { expect } from 'chai'

import { useEnvironment } from './helpers'
import { QUERY_DECRYPTER_ADDRESS, TASK_MANAGER_ADDRESS, ZK_VERIFIER_ADDRESS } from '../src/addresses'

describe('Cofhe Mock Contracts Plugin', function () {
	describe('Tests Hardhat Network Plugin Integration', function () {
		useEnvironment('hardhat')

		it('Should successfully inject the mocks', async function () {
			let taskManagerBytecode = await this.hre.network.provider.send('eth_getCode', [TASK_MANAGER_ADDRESS])
			let zkVerifierBytecode = await this.hre.network.provider.send('eth_getCode', [ZK_VERIFIER_ADDRESS])
			let queryDecrypterBytecode = await this.hre.network.provider.send('eth_getCode', [QUERY_DECRYPTER_ADDRESS])

			expect(taskManagerBytecode).to.eq('0x', 'MockTaskManager not deployed')
			expect(zkVerifierBytecode).to.eq('0x', 'MockZkVerifier not deployed')
			expect(queryDecrypterBytecode).to.eq('0x', 'MockQueryDecrypter not deployed')

			await this.hre.run('deploy-mocks')

			taskManagerBytecode = await this.hre.network.provider.send('eth_getCode', [TASK_MANAGER_ADDRESS])
			zkVerifierBytecode = await this.hre.network.provider.send('eth_getCode', [ZK_VERIFIER_ADDRESS])
			queryDecrypterBytecode = await this.hre.network.provider.send('eth_getCode', [QUERY_DECRYPTER_ADDRESS])

			expect(taskManagerBytecode).to.not.eq('0x', 'MockTaskManager deployed')
			expect(zkVerifierBytecode).to.not.eq('0x', 'MockZkVerifier deployed')
			expect(queryDecrypterBytecode).to.not.eq('0x', 'MockQueryDecrypter deployed')
		})
	})
})
