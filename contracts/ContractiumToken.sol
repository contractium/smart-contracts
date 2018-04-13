pragma solidity ^0.4.21;

import './TokenOffering.sol';

contract ContractiumToken is TokenOffering {

  string public constant name = "Contractium";
  string public constant symbol = "CTU";
  uint8 public constant decimals = 18;
  
  uint256 public constant INITIAL_SUPPLY = 3000000000 * (10 ** uint256(decimals));
  uint256 public constant INITIAL_TOKEN_OFFERING = 1500000000 * (10 ** uint256(decimals));
  
  uint256 public unitsOneEthCanBuy = 15000;

  // total ether funds
  uint256 internal totalWeiRaised;

  function ContractiumToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    
    startOffering(INITIAL_TOKEN_OFFERING);

    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

  function() public payable {
    require(msg.sender != owner);

    // number of tokens to sale in wei
    uint256 amount = msg.value * unitsOneEthCanBuy;
    preValidatePurchase(amount);
    require(balances[owner] >= amount);
    
    totalWeiRaised = totalWeiRaised + msg.value;
  
    // increase current amount of tokens offered
    currentTokenOfferingRaised = currentTokenOfferingRaised + amount; 
    
    balances[owner] = balances[owner].sub(amount);
    balances[msg.sender] = balances[msg.sender].add(amount);

    emit Transfer(owner, msg.sender, amount); // Broadcast a message to the blockchain

    //Transfer ether to owner
    owner.transfer(msg.value);         
 
                            
  }

}
