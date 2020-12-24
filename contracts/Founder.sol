// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./DirectBonus.sol";


abstract contract Founder is AccountStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 constant private FOUNDER_INVESTMENT_CAP_BONUS = 20 ether;
    bytes32 constant public FOUNDER_MANAGER_ROLE = keccak256("FOUNDER_MANAGER_ROLE");

    EnumerableSet.AddressSet private _founderAccounts;


    function isFounder(address account) public view returns(bool) {
        return _founderAccounts.contains(account);
    }


    function addFounder(address account) public returns(bool) {
        require(hasRole(FOUNDER_MANAGER_ROLE, msg.sender), "Founder: must have founder manager role to add founder");
        return _founderAccounts.add(account);
    }


    function removeFounder(address account) public returns(bool) {
        require(hasRole(FOUNDER_MANAGER_ROLE, msg.sender), "Founder: must have founder manager role to remove founder");
        return _founderAccounts.remove(account);
    }


    function founderBonusCapFor(address account) internal view returns(uint256) {
        return isFounder(account) ? FOUNDER_INVESTMENT_CAP_BONUS : 0;
    }
}
