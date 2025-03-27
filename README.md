# @fhenixprotocol/cofhe-mock-contracts [![NPM Package][npm-badge]][npm] [![License: MIT][license-badge]][license]

[npm]: https://www.npmjs.com/package/@fhenixprotocol/cofhe-mock-contracts
[npm-badge]: https://img.shields.io/npm/v/@fhenixprotocol/cofhe-mock-contracts.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

A mock smart contract library for testing CoFHE (Confidential Computing Framework for Homomorphic Encryption) with FHE primitives. This package provides mock implementations of core CoFHE contracts for development and testing purposes.

## Features

- Mock implementations of core CoFHE contracts:
  - MockTaskManager
  - MockQueryDecrypter
  - MockZkVerifier
  - ACL (Access Control List)
- Synchronous operation simulation with mock delays
- On-chain access to unencrypted values for testing
- Compatible with the main `@fhenixprotocol/cofhe-contracts` package

## Installation

```bash
npm install @fhenixprotocol/cofhe-mock-contracts
```

## Usage

Integrate the `deploy-mocks` task into hardhat tasks like `node`, `test` and `compile`.

## Deploy Mocks Task

The package includes a `deploy-mocks` task that sets up all the necessary mock contracts on a local Hardhat network. This is particularly useful for development and testing.

To run the deploy-mocks task:

```bash
npm run deploy-mocks
```

or

```bash
npx hardhat deploy-mocks
```

The task will:

1. Deploy a MockTaskManager
2. Deploy an ACL contract
3. Deploy a MockZkVerifier
4. Deploy a MockQueryDecrypter
5. Set up the necessary connections between contracts
6. Initialize all contracts with the correct permissions

Note: This task is intended to run on the Hardhat network only. If you try to run it on a different network, it will display a warning message.

## Development

This package is designed to work alongside the main `@fhenixprotocol/cofhe-contracts` package for development and testing purposes. It provides mock implementations that simulate the behavior of the real CoFHE contracts while making development and testing easier.

## License

This project is licensed under MIT.
