# Kurtosis Ethereum Contract State Export

Export blockchain state from contract deployments to JSON format.

## Quick Start

### 1. Install dependencies

```bash
forge install
```

### 2. Deploy contracts and export state

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url http://127.0.0.1:32790 --broadcast
```

## Output Format

The generated `state-diff.json` contains:

- Contract address
- Deployed bytecode
- Storage slots and values (only non-zero values)

Example:

```json
[
  {
    "address": "0x...",
    "code": "0x608060405234801561000f575f5ffd5b50...",
    "storage": {
      "0x0000000000000000000000000000000000000000000000000000000000000000": "0x0000000000000000000000000000000000000000000000000000000000000064",
      "0x0000000000000000000000000000000000000000000000000000000000000001": "0x0000000000000000000000008943545177806ed17b9f23f0a21ee5948ecaa776"
    }
  }
]
```

## Configuration

- Default RPC URL: `http://127.0.0.1:32801` (Kurtosis local network)
- Modify `script/Deploy.s.sol` to deploy different contracts or change initialization

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Kurtosis](https://docs.kurtosis.com/install) (optional, for local network)

## Advanced Usage

### With broadcast (actually deploy to network)

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url http://127.0.0.1:32801 --broadcast
```
