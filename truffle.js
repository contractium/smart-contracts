const config = require('./configs/config.json');
const HDWalletProvider = require("truffle-hdwallet-provider-privkey");

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },  
    ropsten: {
      provider: function() {
        const privKeys = config.ropsten.private_key;
        return new HDWalletProvider(privKeys, config.ropsten.provider_url)
      },
      gas: 3000000,
      network_id: "2" // Match any network id
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};