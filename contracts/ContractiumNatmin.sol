pragma solidity ^0.4.24;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

contract ContractiumNatmin is Ownable {
    using SafeMath for uint256;
    
    uint256 constant public CTU_RATE = 19500; // 1 ETH/19500 CTU
    uint256 constant public NAT_RATE = 10400; // 1 ETH/10400 NAT
    
    mapping (string => ERC20) tokenAddresses;
    mapping (string => address) approverAddresses;
    uint256 receivedETH;
    
    event Deposit(address indexed _from, uint256 _ctuAmount, uint256 _natAmount);
    
    constructor(
        address _ctu,
        address _nat,
        address _approverCTUAddress,
        address _approverNATAddress
    ) public {
        setToken(_ctu, "CTU");
        setToken(_nat, "NAT");
        setApproverCTUAddress(_approverCTUAddress);
        setApproverNATAddress(_approverNATAddress);
    }
    
    function () public payable {
        address sender = msg.sender;
        uint256 depositAmount = msg.value;
        uint256 halfOfDepositAmount = depositAmount.div(2);
        uint256 ctuAmount = depositAmount.mul(CTU_RATE);
        uint256 natAmount = depositAmount.mul(NAT_RATE);
        ERC20 ctuToken = tokenAddresses["CTU"];
        ERC20 natToken = tokenAddresses["NAT"];
        
        require(ctuToken.transferFrom(approverAddresses["CTU"], sender, ctuAmount));
        require(natToken.transferFrom(approverAddresses["NAT"], sender, natAmount));
        
        receivedETH = receivedETH + depositAmount;
        
        approverAddresses["CTU"].transfer(halfOfDepositAmount);
        approverAddresses["NAT"].transfer(depositAmount.sub(halfOfDepositAmount));
        
        emit Deposit(sender, ctuAmount, natAmount);
    }
    
    function setApproverCTUAddress(address _address) public onlyOwner {
        setApprover(_address, "CTU");
    }
    
    function setApproverNATAddress(address _address) public onlyOwner {
        setApprover(_address, "NAT");
    }
    
    
    function getAvailableCTU() public view returns (uint256) {
        return getAvailableToken("CTU");
    }
    
    function getAvailableNAT() public view returns (uint256) {
        return getAvailableToken("NAT");
    }
    
    function getTokenAddress(string _tokenSymbol) public view returns (address) {
        return tokenAddresses[_tokenSymbol];
    }
    
    function getApproverAddress(string _tokenSymbol) public view returns (address) {
        return approverAddresses[_tokenSymbol];
    }
    
    function getAvailableToken(string _tokenSymbol) internal view returns (uint256) {
        ERC20 token = tokenAddresses[_tokenSymbol];
        uint256 allowance = token.allowance(approverAddresses[_tokenSymbol], this);
        uint256 approverBalance = token.balanceOf(approverAddresses[_tokenSymbol]);
        
        return allowance > approverBalance ? approverBalance : allowance;
    }
    
    function setToken(address _address, string _symbol) internal onlyOwner {
        require(_address != 0x0);
        tokenAddresses[_symbol] = ERC20(_address);
    }
    
    function setApprover(address _address, string _tokenSymbol) internal onlyOwner {
        require(_address != 0x0);
        approverAddresses[_tokenSymbol] = _address;
    }
    
}
