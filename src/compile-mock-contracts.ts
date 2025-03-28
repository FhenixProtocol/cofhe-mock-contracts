import chalk from 'chalk'
import fs from 'fs'
import { TASK_NODE, TASK_RUN, TASK_TEST } from 'hardhat/builtin-tasks/task-names'
import { task } from 'hardhat/config'
import { HARDHAT_NETWORK_NAME, HardhatPluginError } from 'hardhat/plugins'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import path from 'path'

const paths = ['ACL.sol', 'MockCoFHE.sol', 'MockQueryDecrypter.sol', 'MockTaskManager.sol', 'MockZkVerifier.sol']
const pluginName = 'cofhe-mock-contracts'

const generate = function (dependency: string) {
	return ['// SPDX-License-Identifier: UNLICENSED', 'pragma solidity >0.0.0;', `import '${dependency}';`].map((l) => `${l}\n`).join('')
}

export const compileMockContractPaths = async (hre: HardhatRuntimeEnvironment) => {
	// other packages may incorrectly set a relative sources path so it must be explicitly resolved
	const sources = path.resolve(hre.config.paths.sources)

	console.log('sources', sources)

	const directory = path.resolve(sources, pluginName)
	const tracker = path.resolve(directory, `.${pluginName}`)

	console.log('directory', directory)
	console.log('tracker', tracker)

	if (!fs.existsSync(sources)) {
		fs.mkdirSync(sources)
	}

	if (!directory.startsWith(sources)) {
		throw new HardhatPluginError(pluginName, 'resolved path must be inside of sources directory')
	}

	if (directory === sources) {
		throw new HardhatPluginError(pluginName, 'resolved path must not be sources directory')
	}

	if (fs.existsSync(directory)) {
		// delete directory only if tracker is found or directory is empty
		if (fs.existsSync(tracker) || fs.readdirSync(directory).length === 0) {
			fs.rmSync(directory, { recursive: true })
		} else {
			throw new HardhatPluginError(pluginName, `temporary source directory must have been generated by ${pluginName}`)
		}
	}

	fs.mkdirSync(directory)
	fs.writeFileSync(tracker, `directory approved for write access by ${pluginName}\n`)

	for (const dependency of paths) {
		const fullPath = path.join(directory, dependency)

		if (!fs.existsSync(path.dirname(fullPath))) {
			fs.mkdirSync(path.dirname(fullPath), { recursive: true })
		}

		console.log('fullPath', fullPath)
		console.log('generate', generate(dependency))

		fs.writeFileSync(fullPath, generate(dependency))
	}

	try {
		await hre.run('compile')
	} finally {
		fs.rmSync(directory, { recursive: true })
	}
}

// /**
//  * Injects mock Fhenix FHE contracts on the hardhat network. Noop if not on the hardhat network.
//  *
//  * Currently injected into the `test`, `node`, and `run` tasks.
//  */
// export const injectFhenixMocks = async (hre: HardhatRuntimeEnvironment) => {
// 	if (hre.network.name === HARDHAT_NETWORK_NAME) {
// 		await compileMockContractPaths(hre)

// 		const MockFheOpsArtifact = await hre.artifacts.readArtifact('MockFheOps')

// 		await hre.network.provider.send('hardhat_setCode', ['0x0000000000000000000000000000000000000080', MockFheOpsArtifact.deployedBytecode])

// 		console.log(chalk.bold(chalk.green('fhenix-hardhat-network - Using mocked FHE on Hardhat network')))
// 	}
// }

// task(TASK_NODE, 'Deploy fhenix mock contracts into standalone hardhat node').setAction(async ({}, hre: HardhatRuntimeEnvironment, runSuper) => {
// 	await injectFhenixMocks(hre)
// 	return runSuper()
// })

// task(TASK_RUN, 'Deploy fhenix mock contracts into hardhat run task').setAction(async ({}, hre: HardhatRuntimeEnvironment, runSuper) => {
// 	await injectFhenixMocks(hre)
// 	return runSuper()
// })
