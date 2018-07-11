pragma solidity ^0.4.18 ;
pragma experimental ABIEncoderV2 ;

contract ContractiumInterface {
    function balanceOf(address who) public view returns (uint256);
    function contractSpend(address _from, uint256 _value) public returns (bool);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract MvpContract is Ownable {

    ContractiumInterface ctuContract;
    uint8 public constant decimals = 18;
    uint256 fee = 50 * (10 ** uint256(decimals));
    address owner;

    struct Party {
        address addr;
        bool isSigned;
    }

    struct LaborContract {
        Party partyA;
        Party partyB;

        string content;
        bool validate;
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
    event SignContract(address _partyAddress, string _content, bool _isSuccess);
    event NewContract(address _issuerAddress, string _content);
    
    /**
    *  Create contract
    */

    function createContract(address _addrB, string _content) public returns (bool) {
        require(!contractCreated[_content]);

        Party memory partyA = Party(msg.sender, false);
        Party memory partyB = Party(_addrB, false);

        LaborContract memory c = LaborContract(partyA, partyB, _content, false);

        contracts.push(c);
        contentToContract[_content] = c;
        contractCreated[_content] = true;
        
        contractsByUser[msg.sender].push(c);
        contractsByUser[_addrB].push(c);
        
        contractCount++;
        emit NewContract(msg.sender, _content);
        return true;
    }

    /**
    *  Sign in contract
    *
    */
    function sign(string _key) public canSign(_key) isCreated(_key) returns (bool) {
        LaborContract storage c = contentToContract[_key];

        if (c.partyA.addr == msg.sender) {
            c.partyA.isSigned = true;
        } else {
            c.partyB.isSigned = true;
        }
        
        require(ctuContract.balanceOf(msg.sender) >= fee);
        ctuContract.contractSpend(msg.sender, fee);
        checkContractComplete(_key);
        emit SignContract(msg.sender, _key, true);
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
        require(c.partyA.addr == _addr || c.partyB.addr == _addr);
        if (c.partyA.addr == _addr ) {
            require(!c.partyA.isSigned);
        }
        else {
            require(!c.partyB.isSigned);
        }
        require(ctuContract.balanceOf(_addr) >= fee);
        _;
    }


    /**
    * Complete a contract, called when a party signes in the contract.
    * If both of party signed, contract is completed and cannot be changed.
    *
    */
    function checkContractComplete(string _key) internal {
        LaborContract storage c = contentToContract[_key];

        if (c.partyA.isSigned && c.partyB.isSigned) {
            c.validate = true;
        }
    }

    function getContractByKey(string _key) public view isCreated(_key) returns (address partyA, address partyB, bool partyASigned, bool partyBSigned, bool validate) {
        LaborContract storage c = contentToContract[_key];
        return (c.partyA.addr, c.partyB.addr, c.partyA.isSigned, c.partyB.isSigned, c.validate);
    }


    function MvpContract() {
        ctuContract =  ContractiumInterface(0x1b7ed7b675e8dbfc7eefa9ada5af37ccd93ab93b);
        owner = msg.sender;
    }

    function getCtuBalance() public view returns (uint256 balance) {
        return ctuContract.balanceOf(msg.sender);
    }
    
    function getContractsOfAddr() public view returns (address[] partyA, address[] partyB, string[] content, bool[] partyASigned, bool[] partyBSigned) {
        LaborContract[] storage contractsUser = contractsByUser[msg.sender]; 

        return formatDataReturn(contractsUser);
    }
    
    function getContractsByAddr(address _addr) public view onlyOwner returns (address[] partyA, address[] partyB, string[] content, bool[] partyASigned, bool[] partyBSigned) {
        require(_addr != address(0x0));
        LaborContract[] storage contractsUser = contractsByUser[_addr]; 
        
        return formatDataReturn(contractsUser);
    }
    
    function getAllContracts() public view onlyOwner returns (address[] partyA, address[] partyB, string[] content, bool[] partyASigned, bool[] partyBSigned) {
        return formatDataReturn(contracts);
    }
    
    function formatDataReturn(LaborContract[] _contracts) internal returns (address[] partyA, address[] partyB, string[] content, bool[] partyASigned, bool[] partyBSigned) {
        uint length = _contracts.length;
        
        address[] memory _partyA = new address[](length);
        address[] memory _partyB = new address[](length);
        string[] memory _content = new string[](length);
        bool[] memory _partyASigned = new bool[](length);
        bool[] memory _partyBSigned = new bool[](length);
        
        for (uint i = 0; i < length; i++) {
          _partyA[i] = _contracts[i].partyA.addr;
          _partyB[i] = _contracts[i].partyB.addr;
          _partyASigned[i] = _contracts[i].partyA.isSigned;
          _partyBSigned[i] = _contracts[i].partyB.isSigned;
          _content[i] = _contracts[i].content;
        }
        
        return (_partyA, _partyB, _content, _partyASigned, _partyBSigned);
    }
    
    function setCtuContract(address _ctuAddress) public onlyOwner  returns (bool) {
        require(_ctuAddress != address(0x0));
        ctuContract = ContractiumInterface(_ctuAddress);
        return true;
    }

    function setFee(uint256 _fee) public onlyOwner returns (bool) {
        fee = _fee;
        return true;
    }

    function transferOwnership(address _addr) public onlyOwner{
        super.transferOwnership(_addr);
    }

}
