var ContractiumToken = artifacts.require("./ContractiumToken.sol");

module.exports = function(deployer) {
  deployer.deploy(ContractiumToken);
};
