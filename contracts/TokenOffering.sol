pragma solidity ^0.4.21;

import './ERC20/StandardToken.sol';
import './Ownable.sol';

contract TokenOffering is StandardToken, Ownable {
  bool public offeringEnabled;
  uint256 public currentOfferingAllowance;
  uint256 public currentOfferingRaised;


  function isOfferingAccepted(uint256 amount) internal view returns (bool) {
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