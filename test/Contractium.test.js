
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

  // it("shoud allow offering when init contract", async () => {
  //   let offeringEnabled = await instanceDefault.offeringEnabled();
  //   assert.equal(offeringEnabled, true);
  // });

  // it("should have an initial offering allowance of 900 million tokens", async () => {
  //   let currentTotalTokenOffering = await instanceDefault.currentTotalTokenOffering();
  //   let currentTokenOfferingRaised = await instanceDefault.currentTokenOfferingRaised();
  //   assert.equal(currentTotalTokenOffering, 0.9e+27);
  //   assert.equal(currentTokenOfferingRaised, 0);
  // });

  it("should start offering", async () => {
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.setDate(now.getDate() + 2)/1000);

    let result = await instanceDefault.startOffering(9e26, 1000, startTime, endTime, true);
    let currentTokenOfferingRaised = (await instanceDefault.currentTokenOfferingRaised()).toNumber();
    let currentTotalTokenOffering = (await instanceDefault.currentTotalTokenOffering()).toNumber();
    let offeringEnabled = await instanceDefault.offeringEnabled();
    let bonusRateOneEth = await instanceDefault.bonusRateOneEth();
    assert.equal(currentTokenOfferingRaised, 0);
    assert.equal(currentTotalTokenOffering, 9e+26);
    assert.equal(offeringEnabled, true);
    assert.equal(bonusRateOneEth, 1000);

    let sendFrom = accounts[2];
    await instanceDefault.sendTransaction({from: sendFrom, value: web3.toWei(1, "ether")});
    let balance = (await instanceDefault.balanceOf(sendFrom)).toNumber();
    assert.equal(balance, 16e+21);
  });

  it("should be received 15000 tokens when send eth to contract", async () => {
    let sendFrom = accounts[1];
    let ownerBalanceBefore = web3.fromWei(web3.eth.getBalance(accounts[0])).toNumber();
    let senderBalanceBefore = web3.fromWei(web3.eth.getBalance(sendFrom)).toNumber();
    let gasLimit = web3.toWei(1, "Gwei"); // wei
    await instanceDefault.sendTransaction({from: sendFrom, value: web3.toWei(1, "ether"), gasLimit: gasLimit });
    let balance = (await instanceDefault.balanceOf(sendFrom)).toNumber();

    // sender should receive 16000 tokens
    assert.equal(balance, 16e+21);

    // sender balance is descreased 1 eth
    let senderBalanceAfter = web3.fromWei(web3.eth.getBalance(sendFrom)).toNumber();
    assert(senderBalanceBefore - senderBalanceAfter <= 1 + web3.fromWei(gasLimit));

    // owner should receive 1 eth
    let ownerBalanceAfter = web3.fromWei(web3.eth.getBalance(accounts[0])).toNumber();
    assert.equal(ownerBalanceBefore + 1, ownerBalanceAfter);
  });

  it("should not allow offering over offering allowance", async () => {
    await instanceDefault.endOffering();
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.setDate(now.getDate() + 2)/1000);

    let sendFrom = accounts[3];
    let result = await instanceDefault.startOffering(30000 * 1e18, 0, startTime, endTime, true)
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
    await instanceDefault.endOffering();
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.setDate(now.getDate() + 2)/1000);

    let success = true;
    let randomOfferingAmount = 30000e+18;
    await instanceDefault.startOffering(randomOfferingAmount, 0, startTime, endTime, false, {from: accounts[1]})
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

  it("should allow owner to set bonus rate", async () => {
    let success = true;
    let _bonusRate = 1000;
    await instanceDefault.setBonusRate(_bonusRate)
      .then(result => success = true)
      .catch(err => success = false);
    let bonusRateOneEth = (await instanceDefault.bonusRateOneEth()).toNumber();
    assert.equal(bonusRateOneEth, _bonusRate);
    assert.equal(success, true);  
  });

  it("should not allow users who are not owner to set bonus rate", async () => {
    let success = true;
    let _bonusRate = 1000;
    await instanceDefault.setBonusRate(_bonusRate, {from: accounts[1]})
      .then(result => success = true)
      .catch(err => success = false);
    assert.equal(success, false);  
  });

  // it("should be received bonus token", async () => {
  //   // bonusRate = 1000
  //   let sendFrom = accounts[4];
  //   let gasLimit = web3.toWei(1, "Gwei"); // wei
  //   let balanceSenderBefore = (await instanceDefault.balanceOf(sendFrom)).toNumber();

  //   await instanceDefault.sendTransaction({from: sendFrom, value: web3.toWei(1, "ether"), gasLimit: gasLimit });

  //   let balanceSenderAfter = (await instanceDefault.balanceOf(sendFrom)).toNumber();
  //   assert.equal(balanceSenderAfter - balanceSenderBefore, 16000e18)
    
  // });

});

contract('TokenOffering', function (accounts) {

  it("should burn remain token when closing offering", async () => {
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.setDate(now.getDate() + 5)/1000);
    let totalOfferingTokens = 9e26;
    let currentTotalSupply = (await instanceDefault.totalSupply()).toNumber();
    await instanceDefault.startOffering(totalOfferingTokens, 1000, startTime, endTime, true);

    // check offering is started
    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, true)
    let isBurnInClose = await instanceDefault.isBurnInClose();
    assert.equal(isBurnInClose, true)

    // a user buys tokens
    let sendFrom = accounts[2];
    await instanceDefault.sendTransaction({from: sendFrom, value: web3.toWei(1, "ether")});
    let tokenBought = (await instanceDefault.balanceOf(sendFrom)).toNumber();

    await instanceDefault.endOffering();
    isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, false);

    // check remain tokens burned
    let totalSupplyAfter = (await instanceDefault.totalSupply()).toNumber();
    let totalSupplyShouldBe = currentTotalSupply - totalOfferingTokens + tokenBought;
    let ownerBalance = (await instanceDefault.balanceOf(accounts[0])).toNumber()
    assert.equal(new BigNumber(currentTotalSupply).sub(totalOfferingTokens), ownerBalance)
    assert.equal(totalSupplyAfter, new BigNumber(ownerBalance).plus(tokenBought));
    assert.equal(totalSupplyAfter, new BigNumber(2.1e27).plus(tokenBought));
  });

  it("should end offering", async () => {
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.getTime()/1000);
    await instanceDefault.startOffering(9e26, 1000, startTime, endTime, false);
    let sendFrom = accounts[2];
    await instanceDefault.sendTransaction({from: sendFrom, value: web3.toWei(1, "ether")});
    let balance = (await instanceDefault.balanceOf(sendFrom)).toNumber();
    assert.equal(balance, 32e+21);
    await instanceDefault.endOffering();
    let isRevert = false;

    try {
      await instanceDefault.sendTransaction({from: sendFrom, value: web3.toWei(1, "ether")})
    } catch (error) {
      isRevert = true;
    }
    assert.equal(isRevert, true);
    balance = (await instanceDefault.balanceOf(sendFrom)).toNumber();
    assert.equal(balance, 32e+21);

    let currentTotalTokenOffering = (await instanceDefault.currentTotalTokenOffering()).toNumber();
    assert.equal(currentTotalTokenOffering, 0);

    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, false)
  });

  it("should close current offering before start new one", async () => {
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.setDate(now.getDate() + 5)/1000);
    
    await instanceDefault.startOffering(10000e18, 1000, startTime, endTime, false);
   
    assertRevert(instanceDefault.startOffering(10000e18, 1000, startTime, endTime, false))
  });

  it("should update start timestamp", async () => {
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.setDate(now.getDate() + 5)/1000);
    // await instanceDefault.startOffering(9e26, 1000, startTime, endTime, true);

    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, true)

    now = new Date();
    let newStartTime = Math.floor(now.setDate(now.getDate() + 1)/1000);

    await instanceDefault.updateStartTime(newStartTime);
    let currentStartTime = await instanceDefault.startTime();
    assert.equal(newStartTime, currentStartTime);
  });

  it("should not update start timestamp over end timestamp", async () => {
    await instanceDefault.endOffering();
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.setDate(now.getDate() + 5)/1000);
    await instanceDefault.startOffering(9e26, 1000, startTime, endTime, false);

    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, true)

    let newStartTime = Math.floor(now.setDate(now.getDate() + 10)/1000);

    assertRevert(instanceDefault.updateStartTime(newStartTime))

    let currentStartTime = (await instanceDefault.startTime()).toNumber();
    assert.notEqual(newStartTime, currentStartTime);
    assert.equal(startTime, currentStartTime);
  });

  it("should not update start timestamp in closed offering", async () => {
    await instanceDefault.endOffering();

    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, false)

    let now = new Date();
    let newStartTime = Math.floor(now.setDate(now.getDate() + 10)/1000);
    assertRevert(instanceDefault.updateStartTime(newStartTime))  
  });

  it("should update end timestamp", async () => {
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.setDate(now.getDate() + 5)/1000);
    await instanceDefault.startOffering(9e26, 1000, startTime, endTime, false);
  
    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, true)
  
    now = new Date();
    let newEndTime = Math.floor(now.setDate(now.getDate() + 4)/1000);
    await instanceDefault.updateEndTime(newEndTime);
    let currentEndTime = await instanceDefault.endTime();
    assert.equal(newEndTime, currentEndTime);

    newEndTime = Math.floor(now.setDate(now.getDate() + 6)/1000);
    await instanceDefault.updateEndTime(newEndTime);
    currentEndTime = await instanceDefault.endTime();
    assert.equal(newEndTime, currentEndTime);
  
  });

  it("should not update end timestamp less than start times", async () => {
    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, true)

    let now = new Date();
    let newEndTime = Math.floor(now.setDate(now.getDate() - 10)/1000);
    assertRevert(instanceDefault.updateStartTime(newEndTime))  
  });

  it("should not update end timestamp in closed offering", async () => {
    await instanceDefault.endOffering();

    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, false)

    let now = new Date();
    let newEndTime = Math.floor(now.setDate(now.getDate() + 10)/1000);
    assertRevert(instanceDefault.updateStartTime(newEndTime))  
  });

  it("should not update burnable token", async () => {
    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, false)

    assertRevert(instanceDefault.updateBurnableStatus(true))  
  });

  it("should update burnable token", async () => {
    let now = new Date();
    let startTime = Math.floor(now.getTime()/1000);
    let endTime = Math.floor(now.setDate(now.getDate() + 5)/1000);
    await instanceDefault.startOffering(9e26, 1000, startTime, endTime, true);

    let isOfferingStarted = await instanceDefault.isOfferingStarted();
    assert.equal(isOfferingStarted, true)

    let currentBurnableStatus = await instanceDefault.isBurnInClose();
    assert.equal(currentBurnableStatus, true)

    await instanceDefault.updateBurnableStatus(false);

    assert.equal( await instanceDefault.isBurnInClose(), false )
    
  });

});

contract('ContractSpendToken', function (accounts) {

  const owner = accounts[0];
  const spendContract = accounts[3];

	beforeEach(async function () {
    instanceDefault = await ContractiumToken.deployed();
  });

  it('should add trusted contract address success', async function() {
    await instanceDefault.addContract(spendContract, accounts[1]);
    let receiver = await instanceDefault.getContractReceiver(spendContract);
    expect(receiver).eq(accounts[1]);
  });

  it('should add trusted contract address failed', async function() {
    let rsMissingContract = instanceDefault.addContract('', accounts[1]);
    assertRevert(rsMissingContract);

    let rsMissingAccount = instanceDefault.addContract(spendContract, '');
    assertRevert(rsMissingAccount);

    let rsMissingAll = instanceDefault.addContract();
    assertRevert(rsMissingAll);
  });
  
  it('should remove contract success', async function() {
    await instanceDefault.addContract(spendContract, accounts[1]);
    await instanceDefault.removeContract(spendContract);    

    let receiver = await instanceDefault.getContractReceiver(spendContract);
    expect(receiver, 'remove success').eq('0x0000000000000000000000000000000000000000');    
  });

  it('should spend token', async function() {
    
    const initBalance = web3.toWei(1000, 'ether');
    const spendToken = web3.toWei(10, 'ether');
    await instanceDefault.transfer(accounts[2], initBalance);
    await instanceDefault.addContract(spendContract, accounts[1]);
    await instanceDefault.contractSpend(accounts[2], spendToken, {from: spendContract});

    const balance = (await instanceDefault.balanceOf(accounts[2])).toNumber();
    expect(balance).eq(initBalance - spendToken);
    const receiverBalance = (await instanceDefault.balanceOf(accounts[1])).toNumber();
    expect(receiverBalance + '').eq(spendToken);
  });

  it('should spend token failed', async function() {
    const spendToken = web3.toWei(10, 'ether');
    assertRevert(instanceDefault.contractSpend(accounts[2], spendToken));
  });

  it('should only owner can get receiver address from contract address', async function() {
    await instanceDefault.addContract(spendContract, accounts[1]);
    assertRevert(instanceDefault.getContractReceiver(spendContract, {from: accounts[1]}));
    const addr = await instanceDefault.getContractReceiver(spendContract, {from: owner});
    expect(addr).eq(accounts[1]);
  });
});

const assertRevert = async promise => {
  try {
    await promise;
    assert.fail('Expected revert not received');
  } catch (error) {
    const revertFound = error.message.search('revert') >= 0;
    assert(revertFound, `Expected "revert", got ${error} instead`);
  }
};