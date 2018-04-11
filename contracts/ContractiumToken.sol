library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  // function transferOwnership(address newOwner) public onlyOwner {
  //   require(newOwner != address(0));
  //   emit OwnershipTransferred(owner, newOwner);
  //   owner = newOwner;
  // }

}

contract TokenOffering is StandardToken, Ownable {
  bool public offeringEnabled;
  uint256 public currentOfferingAllowance;
  uint256 public currentOfferingRaised;


  function isOfferingAccepted(uint256 amount) internal returns (bool) {
    return (offeringEnabled && currentOfferingRaised + amount <= currentOfferingAllowance); 
  }
  
  function enableOffering() public onlyOwner {
    offeringEnabled = true;
  }
  
  function stopOffering() public onlyOwner {
    offeringEnabled = false;
  }

}

contract ContractiumToken is TokenOffering {

  string public constant name = "Contractium";
  string public constant symbol = "CTU";
  uint8 public constant decimals = 18;
  
  uint256 public constant INITIAL_SUPPLY = 30 * (10 ** uint256(decimals));
  uint256 public constant INITIAL_TOKEN_OFFERING_ALLOWANCE = 15 * (10 ** uint256(decimals));
  bool public constant INTIIAL_OFFERING_ENABLED = true;
  
  uint256 public unitsOneEthCanBuy = 3;
  // bool public offeringEnabled;
  // uint256 public tokenOfferingAllowance;
  // uint256 public tokenRaisedAmount;

  // total ether funds
  uint256 public totalEthInWei;

  function ContractiumToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    currentOfferingAllowance = INITIAL_TOKEN_OFFERING_ALLOWANCE;
    offeringEnabled = true;

    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

  function() payable {
    uint256 amount = msg.value * unitsOneEthCanBuy;
    if (isOfferingAccepted(amount)) {
      require(balances[owner] >= amount);
      totalEthInWei = totalEthInWei + msg.value;
    
      currentOfferingRaised = currentOfferingRaised + amount; // increase current amount of tokens offered
      
      balances[owner] = balances[owner].sub(amount);
      balances[msg.sender] = balances[msg.sender].add(amount);

      Transfer(owner, msg.sender, amount); // Broadcast a message to the blockchain

      //Transfer ether to owner
      owner.transfer(msg.value);         
    } else {
      revert();
    }
                            
  }


}
