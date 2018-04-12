pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract TokenOffering is StandardToken, Ownable {
  bool public offeringEnabled;
  uint256 public currentOfferingAllowance;
  uint256 public currentOfferingRaised;


  function isOfferingAccepted(uint256 amount) internal view returns (bool) {
    require(amount > 0);
    return (offeringEnabled && currentOfferingRaised + amount <= currentOfferingAllowance); 
  }
  
  function stopOffering() public onlyOwner {
    offeringEnabled = false;
  }
  
  function resumeOffering() public onlyOwner {
    offeringEnabled = true;
  }

  function startOffering(uint256 _tokenOfferingAllowance) public onlyOwner returns (bool) {
    require(_tokenOfferingAllowance <= balances[owner]);
    currentOfferingRaised = 0;
    currentOfferingAllowance = _tokenOfferingAllowance;
    offeringEnabled = true;
    return true;
  }

}