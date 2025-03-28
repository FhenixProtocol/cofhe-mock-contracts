import { resetHardhatContext } from 'hardhat/plugins-testing'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import path from 'path'

declare module 'mocha' {
	interface Context {
		hre: HardhatRuntimeEnvironment
	}
}

export function useEnvironment(fixtureProjectName: string) {
	beforeEach('Loading hardhat environment', function () {
		process.chdir(path.join(__dirname, 'fixture-projects', fixtureProjectName))

		// eslint-disable-next-line @typescript-eslint/no-require-imports
		this.hre = require('hardhat')
	})

	afterEach('Resetting hardhat', function () {
		resetHardhatContext()
	})
}
