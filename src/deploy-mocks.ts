import { task } from 'hardhat/config'
import { MockZkVerifier, MockQueryDecrypter, TaskManager, ACL } from '../typechain-types'
import { hardhatSetCode } from './utils'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { compileMockContractPaths } from './compile-mock-contracts'
import { TASK_MANAGER_ADDRESS, ZK_VERIFIER_ADDRESS, QUERY_DECRYPTER_ADDRESS } from './addresses'

const deployMockTaskManager = async (hre: HardhatRuntimeEnvironment) => {
	const [signer] = await hre.ethers.getSigners()

	console.log('Task Manager')

	// Deploy MockTaskManager
	const TaskManagerArtifact = await hre.artifacts.readArtifact('TaskManager')
	await hardhatSetCode(hre, TASK_MANAGER_ADDRESS, TaskManagerArtifact.deployedBytecode)
	const taskManager: TaskManager = (await hre.ethers.getContractAt('TaskManager', TASK_MANAGER_ADDRESS)) as unknown as TaskManager
	console.log('  - deployed')

	// Initialize MockTaskManager
	const initTx = await taskManager.initialize(signer.address)
	await initTx.wait()
	console.log('  - initialized')

	const tmExists = await taskManager.exists()
	console.log('  - exists', tmExists ? 'yes' : 'no')

	console.log('  - address:', await taskManager.getAddress())

	return taskManager
}

const deployMockACL = async (hre: HardhatRuntimeEnvironment) => {
	// Get Signer
	const [signer] = await hre.ethers.getSigners()

	console.log('ACL')

	// Deploy ACL implementation
	const aclFactory = await hre.ethers.getContractFactory('ACL')
	const aclImplementation = await aclFactory.deploy()
	await aclImplementation.waitForDeployment()
	console.log('  - implementation deployed')

	// Encode initialization data
	const aclInitData = aclImplementation.interface.encodeFunctionData('initialize', [signer.address])

	// Deploy ERC1967 Proxy
	const ERC1967Proxy = await hre.ethers.getContractFactory('ERC1967Proxy')
	const proxy = await ERC1967Proxy.deploy(await aclImplementation.getAddress(), aclInitData)
	await proxy.waitForDeployment()
	console.log('  - proxy deployed')

	// Get ACL instance at proxy address
	const acl: ACL = (await hre.ethers.getContractAt('ACL', await proxy.getAddress())) as unknown as ACL
	console.log('  - address:', await acl.getAddress())

	return acl
}

const deployMockZkVerifier = async (hre: HardhatRuntimeEnvironment) => {
	console.log('ZkVerifier')

	const zkVerifierArtifact = await hre.artifacts.readArtifact('MockZkVerifier')
	await hardhatSetCode(hre, ZK_VERIFIER_ADDRESS, zkVerifierArtifact.deployedBytecode)
	const zkVerifier: MockZkVerifier = (await hre.ethers.getContractAt('MockZkVerifier', ZK_VERIFIER_ADDRESS)) as unknown as MockZkVerifier
	console.log('  - deployed')

	const zkVerifierExists = await zkVerifier.exists()
	console.log('  - exists', zkVerifierExists ? 'yes' : 'no')

	console.log('  - address:', await zkVerifier.getAddress())

	return zkVerifier
}

const deployMockQueryDecrypter = async (hre: HardhatRuntimeEnvironment, acl: ACL) => {
	console.log('QueryDecrypter')

	const queryDecrypterArtifact = await hre.artifacts.readArtifact('MockQueryDecrypter')
	await hardhatSetCode(hre, QUERY_DECRYPTER_ADDRESS, queryDecrypterArtifact.deployedBytecode)
	const queryDecrypter: MockQueryDecrypter = (await hre.ethers.getContractAt('MockQueryDecrypter', QUERY_DECRYPTER_ADDRESS)) as unknown as MockQueryDecrypter
	console.log('  - deployed')

	const queryDecrypterExists = await queryDecrypter.exists()
	console.log('  - exists', queryDecrypterExists ? 'yes' : 'no')

	// Initialize MockQueryDecrypter
	const initTx = await queryDecrypter.initialize(TASK_MANAGER_ADDRESS, await acl.getAddress())
	await initTx.wait()
	console.log('  - initialized')

	console.log('  - address:', await queryDecrypter.getAddress())

	return queryDecrypter
}

const setTaskManagerACL = async (taskManager: TaskManager, acl: ACL) => {
	const setAclTx = await taskManager.setACLContract(await acl.getAddress())
	await setAclTx.wait()
	console.log('TaskManager ACL set')
}

task('deploy-mocks', 'Deploys the mock contracts on the Hardhat network').setAction(async (taskArgs, hre) => {
	console.log('Deploy Mocks On Hardhat... \n')
	// await compileMockContractPaths(hre)

	const network = hre.network.name
	if (network !== 'hardhat') {
		console.log(`This task is intended to run on the Hardhat network. Current network: ${network}`)
		return
	}

	await hre.run('compile')

	const artifactPaths = await hre.artifacts.getArtifactPaths()
	console.log('artifactPaths', artifactPaths)

	const taskManager = await deployMockTaskManager(hre)
	const acl = await deployMockACL(hre)

	console.log('Task Manager Exists', await taskManager.getAddress(), await taskManager.exists())
	await setTaskManagerACL(taskManager, acl)
	const zkVerifier = await deployMockZkVerifier(hre)
	const queryDecrypter = await deployMockQueryDecrypter(hre, acl)

	console.log('Done!')
})
