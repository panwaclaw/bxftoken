// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./MultiLevelTree.sol";


abstract contract Founder is MultiLevelTree {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    uint256 constant private FOUNDER_FEE = 1;
    uint256 constant private FOUNDER_INVESTMENT_CAP_BONUS = 20 ether;
    bytes32 public constant FOUNDER_MANAGER_ROLE = keccak256("FOUNDER_MANAGER_ROLE");

    EnumerableSet.AddressSet private _founderAccounts;


    function isFounder(address account) public view returns(bool) {
        return _founderAccounts.contains(account);
    }


    function getFoundersCount() public view returns(uint256) {
        return _founderAccounts.length();
    }


    function addFounder(address account) public returns(bool) {
        require(hasRole(FOUNDER_MANAGER_ROLE, msg.sender), "Founder: must have founder manager role to add founder");
        return _founderAccounts.add(account);
    }


    function removeFounder(address account) public returns(bool) {
        require(hasRole(FOUNDER_MANAGER_ROLE, msg.sender), "Founder: must have founder manager role to remove founder");
        return _founderAccounts.remove(account);
    }


    function dropFounder(address account) internal returns(bool) {
        return _founderAccounts.remove(account);
    }


    function payToFounders(uint256 founderBonus) internal {
        uint256 foundersCount = getFoundersCount();
        uint256 payoutShare = SafeMath.div(founderBonus, foundersCount);

        for (uint i = 0; i < foundersCount; i++) {
            address account = _founderAccounts.at(i);
            addFounderBonusTo(account, payoutShare);
        }
    }


    function calculateFounderBonus(uint256 amount) internal pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, FOUNDER_FEE), 100);
    }


    function founderBonusCapFor(address account) internal view returns(uint256) {
        return isFounder(account) ? FOUNDER_INVESTMENT_CAP_BONUS : 0;
    }
}
