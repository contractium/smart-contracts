const BigNumber = web3.BigNumber;
const ContractiumToken = artifacts.require('./ContractiumToken.sol')

contract('ContractiumToken', function (accounts) {

	const owner = accounts[0];

	beforeEach(async function () {
    instanceDefault = await ContractiumToken.deployed();
  });

 	it("should have 18 decimal places", async () => {
    const decimals = await instanceDefault.decimals();
    assert.equal(decimals, 18);
  });

  it("should have an initial owner balance of 3 billion tokens", async () => {
    const ownerBalance = (await instanceDefault.balanceOf(owner)).toNumber();
    assert.equal(ownerBalance, 3e+27, "the owner balance should initially be 3 billion tokens");
  });

  it("shoud allow offering when init contract", async () => {
    let offeringEnabled = await instanceDefault.offeringEnabled();
    assert.equal(offeringEnabled, true);
  });

  it("should have an initial offering allowance of 900 million tokens", async () => {
    let currentTotalTokenOffering = await instanceDefault.currentTotalTokenOffering();
    let currentTokenOfferingRaised = await instanceDefault.currentTokenOfferingRaised();
    assert.equal(currentTotalTokenOffering, 0.9e+27);
    assert.equal(currentTokenOfferingRaised, 0);
  });

  it("should be received 15000 tokens when send eth to contract", async () => {
    let sendFrom = accounts[1];
    let ownerBalanceBefore = web3.fromWei(web3.eth.getBalance(accounts[0])).toNumber();
    let senderBalanceBefore = web3.fromWei(web3.eth.getBalance(sendFrom)).toNumber();
    let gasLimit = web3.toWei(1, "Gwei"); // wei
    await instanceDefault.sendTransaction({from: sendFrom, value: web3.toWei(1, "ether"), gasLimit: gasLimit });
    let balance = (await instanceDefault.balanceOf(sendFrom)).toNumber();

    // sender should receive 15000 tokens
    assert.equal(balance, 15e+21);

    // sender balance is descreased 1 eth
    let senderBalanceAfter = web3.fromWei(web3.eth.getBalance(sendFrom)).toNumber();
    assert(senderBalanceBefore - senderBalanceAfter <= 1 + web3.fromWei(gasLimit));

    // owner should receive 1 eth
    let ownerBalanceAfter = web3.fromWei(web3.eth.getBalance(accounts[0])).toNumber();
    assert.equal(ownerBalanceBefore + 1, ownerBalanceAfter);
  });

  it("should start offering", async () => {
    let instance = await ContractiumToken.deployed();
    let result = await instance.startOffering(1.5e+27);
    let currentTokenOfferingRaised = (await instance.currentTokenOfferingRaised()).toNumber();
    let currentTotalTokenOffering = (await instance.currentTotalTokenOffering()).toNumber();
    let offeringEnabled = await instance.offeringEnabled();
    assert.equal(currentTokenOfferingRaised, 0);
    assert.equal(currentTotalTokenOffering, 1.5e+27);
    assert.equal(offeringEnabled, true);

    let sendFrom = accounts[2];
    await instance.sendTransaction({from: sendFrom, value: web3.toWei(1, "ether")});
    let balance = (await instance.balanceOf(sendFrom)).toNumber();
    assert.equal(balance, 15e+21);
  });

  it("should not allow offering over offering allowance", async () => {
    let sendFrom = accounts[3];
    let result = await instanceDefault.startOffering(30000 * 1e18);
    let balanceBefore = (await instanceDefault.balanceOf(sendFrom)).toNumber();
    
    // send ether to contract
    let success = true;
    await instanceDefault.sendTransaction({from: sendFrom, value: web3.toWei(5, "ether") })
      .then(result => success = true)
      .catch(err => success = false);
    
    let balanceAfter = (await instanceDefault.balanceOf(sendFrom)).toNumber();
  
    assert.equal(success, false);
    assert.equal(balanceBefore, balanceAfter);
  });

  it("should start offering by only owner", async () => {
    let success = true;
    let randomOfferingAmount = 1.23456e+27;
    let instance = await ContractiumToken.deployed();
    await instance.startOffering(randomOfferingAmount, {from: accounts[1]})
      .then(result => success = true)
      .catch(err => success = false);
    assert.equal(success, false);  
  });

  it("should not stop offering by accounts are not owner", async () => {
    let success = true;
    await instanceDefault.stopOffering({from: accounts[1]})
      .then(result => success = true)
      .catch(err => success = false);
    assert.equal(success, false);
  });

  it("should not resume offering by accounts are not owner", async () => {
    let result = true;
    await instanceDefault.resumeOffering({from: accounts[1]})
      .then(result => result = true)
      .catch(err => result = false);
    assert.equal(result, false);
  });

  it("should withdraw tokens by only owner", async () => {
    await instanceDefault.withdrawToken(accounts[3], 15000e+18, "0")
      .then(result => success = true)
      .catch(err => success = false);
    assert.equal(success, true);  
    let balance = (await instanceDefault.balanceOf(accounts[3])).toNumber();
    assert.equal(balance, 15000e+18);
  });

  it("should not withdraw tokens by another account", async () => {
    let success = true;
    await instanceDefault.withdrawToken(accounts[3], 15000e+18, "0", {from: accounts[1]})
      .then(result => success = true)
      .catch(err => success = false);
    assert.equal(success, false);  
  });

});
