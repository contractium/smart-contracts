# Contractium

## Dev
1. Install Ganache-CLI: `npm install -g ganache-cli@7.0.0-beta.0`
2. Install `truffle`: `npm install -g truffle`
3. Install dependences: `npm install`
4. Copy `configs/config.example.json` to `configs/config.json` and fill private keys
5. Run private node: `./start_node.sh`
6. Compile contract: `truffle compile`
7. Deploy contract:
  - Localhost: `truffle migrate`
  - Testnet: `truffle migrate --network testnet`

## Verify contract
1. Run `npm run build-contracts` to merge all contract sol files to a single file in `out/` directory.
2. Copy code in `out/ContractiumToken.sol` file.
3. Paste code verify contract page.
4. Choose solidity compiler version: `v0.4.21+commit.dfe3193c`.
5. Enable optimizer.
6. Submit. 