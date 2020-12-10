// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


contract StandardToken is Context, AccessControl, Pausable {
    using SafeMath for uint256;
    uint256 private _totalSupply = 0;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bytes32 public constant PAUSE_MANAGER_ROLE = keccak256("PAUSE_MANAGER_ROLE");


    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }


    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function pause() public virtual {
        require(hasRole(PAUSE_MANAGER_ROLE, msg.sender), "StandardToken: must have pauser manager role to pause");
        _pause();
    }


    function unpause() public virtual {
        require(hasRole(PAUSE_MANAGER_ROLE, msg.sender), "StandardToken: must have pauser manager role to unpause");
        _unpause();
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view {
        require(!paused(), "StandardToken: token transfer while paused");
    }


    function setTotalSupply(uint256 amount) internal {
        _totalSupply = amount;
    }


    function increaseTotalSupply(uint256 amount) internal view {
        _totalSupply.add(amount);
    }


    function decreaseTotalSupply(uint256 amount) internal view {
        _totalSupply.sub(amount);
    }
}
