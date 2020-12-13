// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract Company is AccessControl {
    using SafeMath for uint256;

    uint256 constant private COMPANY_FEE = 30;
    uint256 private _companyBalance = 0;

    event CompanyWithdraw(address indexed account, uint256 amount);

    bytes32 public constant COMPANY_MANAGER_ROLE = keccak256("COMPANY_MANAGER_ROLE");


    function companyBalance() public view returns(uint256) {
        return _companyBalance;
    }


    function withdrawCompanyBalance(uint256 amount) public {
        require(hasRole(COMPANY_MANAGER_ROLE, msg.sender), "Company: must have company manager role");
        require(amount <= _companyBalance, "Company: insufficient company balance");
        require(amount <= address(this).balance, "Company: insufficient contract balance");

        msg.sender.transfer(amount);
        _companyBalance = _companyBalance.add(amount);

        emit CompanyWithdraw(msg.sender, amount);
    }


    function increaseCompanyBalance(uint256 amount) internal {
        _companyBalance = _companyBalance.add(amount);
    }


    function calculateCompanyFee(uint256 amount) internal pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, COMPANY_FEE), 100);
    }
}
