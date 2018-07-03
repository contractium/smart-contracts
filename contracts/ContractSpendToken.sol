pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
/**
 * @title Contract Spend Token
 * @dev Trusted contracts can spend this token
 * @dev Manage list of trusted contract
 * @dev each one has the destination address to receive the spender token
 */
contract ContractSpendToken is Ownable, StandardToken {
    mapping (address => address) private contractToReceiver;

    function addContract(address _contractAdd, address _to) external onlyOwner returns (bool) {
        contractToReceiver[_contractAdd] = _to;
        return true;
    }

    function removeContract(address _contractAdd) external onlyOwner returns (bool) {
        contractToReceiver[_contractAdd] = address(0);
        return true;
    }

    function contractSpend(address _from, uint256 _value) public returns (bool) {
        address _to = contractToReceiver[msg.sender];
        address _origin = tx.origin;
        require(_to != address(0));
        require(_origin == _from);
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}
