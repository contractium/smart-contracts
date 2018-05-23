pragma solidity ^0.4.21;

import "./TokenOffering.sol";
import "./WithdrawTrack.sol";

contract ContractiumToken is TokenOffering, WithdrawTrack {

    string public constant name = "Contractium";
    string public constant symbol = "CTU";
    uint8 public constant decimals = 18;
  
    uint256 public constant INITIAL_SUPPLY = 3000000000 * (10 ** uint256(decimals));
  
    uint256 public unitsOneEthCanBuy = 15000;

    // total ether funds
    uint256 internal totalWeiRaised;

    function ContractiumToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function() public payable {
        require(isOfferingStarted);

        if (hasClosedOffering()) {
            
            // close offering
            endOffering();

            // return ether to sender
            msg.sender.transfer(msg.value);  

        } else {
            require(msg.sender != owner);

            // number of tokens to sale in wei
            uint256 amount = msg.value.mul(unitsOneEthCanBuy);

            // amount of bonus tokens
            uint256 amountBonus = msg.value.mul(bonusRateOneEth);
            
            // amount with bonus value
            amount = amount.add(amountBonus);

            // validate 
            preValidatePurchase(amount);
            require(balances[owner] >= amount);
            
            totalWeiRaised = totalWeiRaised.add(msg.value);
        
            // increase current amount of tokens offered
            currentTokenOfferingRaised = currentTokenOfferingRaised.add(amount); 
            
            balances[owner] = balances[owner].sub(amount);
            balances[msg.sender] = balances[msg.sender].add(amount);

            emit Transfer(owner, msg.sender, amount); // Broadcast a message to the blockchain

            //Transfer ether to owner
            owner.transfer(msg.value);  
        }
                              
    }

}
