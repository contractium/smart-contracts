var ContractiumToken = artifacts.require("./ContractiumToken.sol");

module.exports = function(deployer, network, accounts) {
  let account = accounts[0];
  console.log("Account deploy ", account);
  deployer.deploy(ContractiumToken, {from: account});
};
