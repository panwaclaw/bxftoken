// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./MultiLevelTreeAccountStorage.sol";
import "./AccessControlRoles.sol";
import "./StandardToken.sol";


abstract contract Founder is MultiLevelTreeAccountStorage, StandardToken {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    uint256 constant private FOUNDER_FEE = 1;

    EnumerableSet.AddressSet private _founderAccounts;

    function isFounder(address account) public view returns(bool) {
        return _founderAccounts.contains(account);
    }


    function getFoundersCount() public view returns(uint256) {
        return _founderAccounts.length();
    }


    function addFounder(address account) public returns(bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "EthPire: must have admin role to add founder");
        return _founderAccounts.add(account);
    }


    function removeFounder(address account) public returns(bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "EthPire: must have admin role to remove founder");
        return _founderAccounts.remove(account);
    }


    function dropFounder(address account) internal returns(bool) {
        return _founderAccounts.remove(account);
    }


    function payToFounders(uint256 founderBonus) internal view {
        uint256 foundersCount = getFoundersCount();
        uint256 payoutShare = SafeMath.div(founderBonus, foundersCount);

        for (uint i = 0; i < foundersCount; i++) {
            address account = _founderAccounts.at(i);
            addFounderBonusTo(account, payoutShare);
        }
    }

    function calculateFounderBonus(uint256 amount) internal view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, FOUNDER_FEE), 100);
    }
}
