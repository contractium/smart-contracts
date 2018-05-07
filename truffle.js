const config = require('./configs/config.json');
const HDWalletProvider = require("truffle-hdwallet-provider-privkey");

module.exports = {
  networks: {
    development: {
      provider: function() {
        const privKey = config.development.private_key;
        return new HDWalletProvider(privKey, config.development.provider_url)
      },
      network_id: "0" // Match any network id
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