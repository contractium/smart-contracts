pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";

/**
 * @title Offer to sell tokens
 */
contract TokenOffering is StandardToken, Ownable, BurnableToken {
  
    bool public offeringEnabled;

    // maximum amount of tokens being sold in current offering session
    uint256 public currentTotalTokenOffering;

    // amount of tokens raised in current offering session
    uint256 public currentTokenOfferingRaised;

    // number of bonus tokens per one ETH
    uint256 public bonusRateOneEth;

    // Start and end timestamps in seconds
    uint256 public startTime;
    uint256 public endTime;

    bool public isBurnInClose = false;

    bool public isOfferingStarted = false;

    event OfferingOpens(uint256 startTime, uint256 endTime, uint256 totalTokenOffering, uint256 bonusRateOneEth);
    event OfferingCloses(uint256 endTime, uint256 tokenOfferingRaised);

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
        require(isOfferingStarted);
        require(offeringEnabled);
        require(currentTokenOfferingRaised.add(_amount) <= currentTotalTokenOffering);
        require(block.timestamp >= startTime && block.timestamp <= endTime);
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
    * @param _bonusRateOneEth number of bonus tokens per one ETH
    * @param _startTime start timestamp in seconds
    * @param _endTime end timestamp in seconds
    * @param _isBurnInClose otional to burn remain offering toke remain
    */
    function startOffering(
        uint256 _tokenOffering, 
        uint256 _bonusRateOneEth, 
        uint256 _startTime, 
        uint256 _endTime,
        bool _isBurnInClose
    ) public onlyOwner returns (bool) {
        require(_tokenOffering <= balances[owner]);
        require(_startTime <= _endTime);
        require(_startTime >= block.timestamp);

        // close current offering before start another offering
        require(!isOfferingStarted);

        isOfferingStarted = true;

        // set offering timestamp
        startTime = _startTime;
        endTime = _endTime;

        // set burnable option
        isBurnInClose = _isBurnInClose;

        // set offering cap
        currentTokenOfferingRaised = 0;
        currentTotalTokenOffering = _tokenOffering;
        offeringEnabled = true;
        setBonusRate(_bonusRateOneEth);

        emit OfferingOpens(startTime, endTime, currentTotalTokenOffering, bonusRateOneEth);
        return true;
    }

    /**
    * @dev Update start timestamp
    * @param _startTime start timestamp
    */
    function updateStartTime(uint256 _startTime) public onlyOwner {
        require(isOfferingStarted);
        require(_startTime <= endTime);
        require(_startTime >= block.timestamp);
        startTime = _startTime;
    }

    /**
    * @dev Update end timestamp
    * @param _endTime end timestamp in seconds
    */
    function updateEndTime(uint256 _endTime) public onlyOwner {
        require(isOfferingStarted);
        require(_endTime >= startTime);
        endTime = _endTime;
    }

    /**
    * @dev Close offering
    */
    function endOffering() public onlyOwner {
        if (isBurnInClose) {
            burnRemainTokenOffering();
        }
        emit OfferingCloses(endTime, currentTokenOfferingRaised);
        resetOfferingStatus();
    }

    /**
    * @dev Burn remain token offering from owner balance
    */
    function burnRemainTokenOffering() internal {
        if (currentTokenOfferingRaised < currentTotalTokenOffering) {
            uint256 remainTokenOffering = currentTotalTokenOffering.sub(currentTokenOfferingRaised);
            _burn(owner, remainTokenOffering);
        }
    }

    /**
    * @dev Reset offering status
    */
    function resetOfferingStatus() internal {
        isOfferingStarted = false;        
        startTime = 0;
        endTime = 0;
        currentTotalTokenOffering = 0;
        currentTokenOfferingRaised = 0;
        bonusRateOneEth = 0;
        offeringEnabled = false;
        isBurnInClose = false;
    }
}