pragma solidity ^0.4.18 ;
pragma experimental ABIEncoderV2 ;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



contract ContractiumInterface {
    function balanceOf(address who) public view returns (uint256);
    function contractSpend(address _from, uint256 _value) public returns (bool);
}

contract MvpContract is Ownable {

    ContractiumInterface ctuContract;
    uint8 public constant decimals = 18;
    uint256 public fee = 50 * (10 ** uint256(decimals));
    address public owner;

    struct Party {
        address addr;
        bool isSigned;
    }
    
    struct ContractState {
        string content;
        string checksum;
    }

    struct LaborContract {
        ContractState initState;
        ContractState finishState;
        bool valid;
        address[] partyAddresses;
        mapping(address => Party) addr2Party;
    }

    //Store all contracts
    mapping(string => LaborContract) contentToContract;
    
    //Store all created contracts, use to check contract is created or not
    mapping(string => bool) contractCreated;
    
    //Store all created contracts grouped by user
    mapping(address => LaborContract[]) contractsByUser;
    
    LaborContract[] contracts;
    uint256 contractCount = 0;
    
    // events
    event NewContract(address _issuerAddress, string _content);
    event SignContract(address _partyAddress, string _content);
    event ConfirmedContract(address[] _partyAddresses, string _content, bool _isValid);
    
    
    constructor() public {
        ctuContract =  ContractiumInterface(0x0dc319Fa14b3809ea2f0f9Ae28311f957a9bE4a3);
        owner = msg.sender;
    }

    
    /**
    *  Create contract
    */

    function createContract(address[] _addresses, string _content, string _checksum) public returns (bool) {
        require(!contractCreated[_content]);
        address _addr = msg.sender;
        LaborContract memory c = LaborContract(
            ContractState(_content, _checksum),
            ContractState('', ''),
            false,
            new address[](0)
            );
        
        contracts.push(c);
        contractCreated[_content] = true;
        contentToContract[_content] = c;
        
        contractsByUser[_addr].push(c);
        for (uint i = 0; i < _addresses.length; i++) {
            contractsByUser[_addresses[i]].push(c);
        }
        addpartyAddresses(_addresses, _addr, _content);
        
        contractCount++;
        
        emit NewContract(_addr, _content);
        return true;
    }
    
    function addpartyAddresses(address[] _addresses, address _creator, string _content) internal{
        LaborContract storage c = contentToContract[_content];
        Party memory party = Party(_creator, false);
        c.addr2Party[_creator] = party;
        c.partyAddresses.push(_creator);
        for (uint i = 0; i < _addresses.length; i++) {
            if (_addresses[i] != address(0x0) && _addresses[i] != _creator) {
                party = Party(_addresses[i], false);
                c.addr2Party[_addresses[i]] = party;
                c.partyAddresses.push(_addresses[i]);
            }
        }
    }
    
    /**
    *  Sign in contract
    *
    */
    function sign(string _content) public canSign(_content) isCreated(_content) returns (bool) {
        address _addr = msg.sender;
        LaborContract storage c = contentToContract[_content];
        
        c.addr2Party[_addr].isSigned = true;
        require(ctuContract.balanceOf(_addr) >= fee);
        ctuContract.contractSpend(_addr, fee);
        
        emit SignContract(_addr, _content);
        return true;
    }
    
    function sign(string _content, string _finishContent, string _finishChecksum) public canSign(_content) isCreated(_content) returns (bool) {
        address _addr = msg.sender;
        LaborContract storage c = contentToContract[_content];
        
        c.addr2Party[_addr].isSigned = true;
        require(ctuContract.balanceOf(_addr) >= fee);
        ctuContract.contractSpend(_addr, fee);
        
        checkContractFinish(_content, _finishContent, _finishChecksum);
        
        emit SignContract(_addr, _content);
        return true;
    }

    /**
    *  Check contract is created or not
    *
    */
    modifier isCreated(string _key) {
        require(contractCreated[_key]);
        _;
    }

    /**
    *  Check msg.sender can sign or not
    *
    */
    modifier canSign(string _key) {
        LaborContract storage c = contentToContract[_key];
        address _addr = msg.sender;
        require(c.addr2Party[_addr].addr != address(0x0));
        require(!c.addr2Party[_addr].isSigned);
        require(ctuContract.balanceOf(_addr) >= fee);
        _;
    }


    /**
    * Complete a contract, called when a party signes in the contract.
    * If both of party signed, contract is completed and cannot be changed.
    *
    */
    function checkContractFinish(string _content, string _finishContent, string _finishChecksum) internal {
        LaborContract storage c = contentToContract[_content];
        bool valid = true;
        
        for (uint i = 0; i < c.partyAddresses.length; i++) {
            if (!c.addr2Party[c.partyAddresses[i]].isSigned) {
                valid = false;
            }
        }
        
        if (valid) {
            c.finishState.content = _finishContent;
            c.finishState.checksum = _finishChecksum;
            c.valid = valid;
            emit ConfirmedContract(c.partyAddresses, _content, c.valid);
        }
        
    }

    function getContractByHash(string _content) public view isCreated(_content) returns (address[] partyAddresses, bool[] isSigned, string content, string checksum, string finishContent, string finishChecksum, bool valid) {
        LaborContract storage c = contentToContract[_content];
        uint length = c.partyAddresses.length;
        bool[] memory _isSigned;
        
        for (uint i = 0; i < length; i++) {
            _isSigned[i] = c.addr2Party[c.partyAddresses[i]].isSigned;
        }
      
        return (c.partyAddresses, _isSigned, c.initState.content, c.initState.checksum, c.finishState.content, c.finishState.checksum, c.valid);
    }

    
    
    function getContractsOfAddr() public view returns (string[] content, string[] checksum, bool[] valid) {
        LaborContract[] storage contractsUser = contractsByUser[msg.sender]; 
        return formatDataReturn(contractsUser);
    }
    
    function getContractsByAddr(address _addr) public view onlyOwner returns (string[] content, string[] checksum, bool[] valid) {
        require(_addr != address(0x0));
        LaborContract[] storage contractsUser = contractsByUser[_addr];
        return formatDataReturn(contractsUser);
    }
    
    function getAllContracts() public view onlyOwner returns (string[] content, string[] checksum, bool[] valid) {
        return formatDataReturn(contracts);
    }
    
    function formatDataReturn(LaborContract[] _contracts) internal returns (string[] content, string[] checksum, bool[] valid) {
        uint length = _contracts.length;
        
        string[] memory _content;
        string[] memory _checksum;
        bool[] memory _valid;
        for (uint i = 0; i < length; i++) {
          _content[i] = _contracts[i].initState.content;
          _checksum[i] = _contracts[i].initState.checksum;
          _valid[i] = _contracts[i].valid;
        }
        
        return (_content, _checksum, _valid);
    }
    
    
    function setCtuContract(address _ctuAddress) public onlyOwner  returns (bool) {
        require(_ctuAddress != address(0x0));
        ctuContract = ContractiumInterface(_ctuAddress);
        return true;
    }

    function getCtuBalance() public view returns (uint256 balance) {
        return ctuContract.balanceOf(msg.sender);
    }

    function transferOwnership(address _addr) public onlyOwner{
        super.transferOwnership(_addr);
    }

}