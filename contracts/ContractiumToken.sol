pragma solidity ^0.4.21;

import './TokenOffering.sol';

contract ContractiumToken is TokenOffering {

  string public constant name = "Contractium";
  string public constant symbol = "CTU";
  uint8 public constant decimals = 18;
  
  uint256 public constant INITIAL_SUPPLY = 3000000000 * (10 ** uint256(decimals));
  uint256 public constant INITIAL_TOKEN_OFFERING_ALLOWANCE = 1500000000 * (10 ** uint256(decimals));
  bool public constant INTIIAL_OFFERING_ENABLED = true;
  
  uint256 public unitsOneEthCanBuy = 15000;

  // total ether funds
  uint256 internal totalEthInWei;

  function ContractiumToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    currentOfferingAllowance = INITIAL_TOKEN_OFFERING_ALLOWANCE;
    offeringEnabled = INTIIAL_OFFERING_ENABLED;

    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

  function() public payable {
    uint256 amount = msg.value * unitsOneEthCanBuy;
    if (isOfferingAccepted(amount)) {
      require(balances[owner] >= amount);
      totalEthInWei = totalEthInWei + msg.value;
    
      currentOfferingRaised = currentOfferingRaised + amount; // increase current amount of tokens offered
      
      balances[owner] = balances[owner].sub(amount);
      balances[msg.sender] = balances[msg.sender].add(amount);

      emit Transfer(owner, msg.sender, amount); // Broadcast a message to the blockchain

      //Transfer ether to owner
      owner.transfer(msg.value);         
    } else {
      revert();
    }
                            
  }

}
