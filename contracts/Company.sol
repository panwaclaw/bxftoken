// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AccessControlRoles.sol";


contract Company is AccessControl, AccessControlRoles {
    using SafeMath for uint256;

    uint256 constant private COMPANY_FEE = 30;
    uint256 private _companyBalance = 0;

    event CompanyWithdraw(address indexed account, uint256 amount);


    function companyBalance() public view returns(uint256) {
        return _companyBalance;
    }


    function withdrawCompanyBalance(uint256 amount) public {
        require(hasRole(MANAGER_ROLE, msg.sender), "BXFToken: must have manager role");
        require(amount <= _companyBalance, "BXFToken: insufficient company balance");
        msg.sender.transfer(amount);
        _companyBalance.sub(amount);

        emit CompanyWithdraw(msg.sender, amount);
    }


    function increaseCompanyBalance(uint256 amount) internal view {
        _companyBalance.add(amount);
    }


    function calculateCompanyFee(uint256 amount) internal view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, COMPANY_FEE), 100);
    }
}
