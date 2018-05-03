pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Offer to sell tokens
 */
contract TokenOffering is StandardToken, Ownable {
  
  bool public offeringEnabled;

  // maximum amount of tokens being sold in current offering session
  uint256 public currentTotalTokenOffering;

  // amount of tokens raised in current offering session
  uint256 public currentTokenOfferingRaised;

  // number of bonus tokens per one ETH
  uint256 public bonusRateOneEth;

  /**
   * @dev
   * @param _bonusRateOneEth number of bonus tokens per one ETH
   */
  function setBonusRate(uint256 _bonusRateOneEth) public onlyOwner {
    bonusRateOneEth = _bonusRateOneEth;
  }

  /**
   * @dev Check for fundraising in current offering
   * @param _amount amount of tokens in wei want to buy
   * @return accept or not accept to fund
   */
  // function isOfferingAccepted(uint256 _amount) internal view returns (bool) {
  //   require(_amount > 0);
  //   return (offeringEnabled && currentTokenOfferingRaised + _amount <= currentTotalTokenOffering); 
  // }

  /**
   * @dev Validation of fundraising in current offering
   * @param _amount amount of tokens in wei want to buy
   */
  function preValidatePurchase(uint256 _amount) internal {
    require(_amount > 0);
    require(offeringEnabled);
    require(currentTokenOfferingRaised.add(_amount) <= currentTotalTokenOffering);
  }
  
  /**
   * @dev Stop selling in current offering session
   */
  function stopOffering() public onlyOwner {
    offeringEnabled = false;
  }
  
  /**
   * @dev Resume selling in current offering session
   */
  function resumeOffering() public onlyOwner {
    offeringEnabled = true;
  }

  /**
   * @dev Start a new offering session
   * @param _tokenOffering amount of token in offering session
   */
  function startOffering(uint256 _tokenOffering) public onlyOwner returns (bool) {
    require(_tokenOffering <= balances[owner]);
    currentTokenOfferingRaised = 0;
    currentTotalTokenOffering = _tokenOffering;
    offeringEnabled = true;
    return true;
  }

}