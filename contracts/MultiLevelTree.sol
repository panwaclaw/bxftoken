// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./AccountStorage.sol";


contract MultiLevelTree is AccountStorage {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    struct Rank {
        string name;
        uint256 selfBuy;
        uint256 turnover;
        uint256 percent;
        uint256 splitRulePercent;
    }

    uint256 constant private DIRECT_FEE = 10;
    uint256 private minimumSelfBuyForDirectBonus = 0.05 ether;

    Rank[] private AFFILIATE_RANKS;

    event MinimumSelfBuyForDirectBonusUpdate(uint256 amount);


    constructor() {
        AFFILIATE_RANKS.push(Rank("User",         0 ether,   0 ether,    0,  100));
        AFFILIATE_RANKS.push(Rank("Member",       0.2 ether, 2 ether,    2,  100));
        AFFILIATE_RANKS.push(Rank("Affiliate",    0.5 ether, 5 ether,    3,  100));
        AFFILIATE_RANKS.push(Rank("Pro",          1 ether,   10 ether,   4,  100));
        AFFILIATE_RANKS.push(Rank("Shepherd",     2 ether,   20 ether,   5,  100));
        AFFILIATE_RANKS.push(Rank("VIP",          4 ether,   40 ether,   6,  100));
        AFFILIATE_RANKS.push(Rank("Gold VIP",     8 ether,   100 ether,  7,  100));
        AFFILIATE_RANKS.push(Rank("Platinum VIP", 16 ether,  400 ether,  8,   60));
        AFFILIATE_RANKS.push(Rank("Red Diamond",  32 ether,  1000 ether, 9,   60));
        AFFILIATE_RANKS.push(Rank("Blue Diamond", 50 ether,  3000 ether, 10,  60));
    }


    function getMinimumSelfBuyForDirectBonus() public view returns(uint256) {
        return minimumSelfBuyForDirectBonus;
    }


    function setMinimumSelfBuyForDirectBonus(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BXFToken: must have admin role to set minimum self buy for direct bonus");
        minimumSelfBuyForDirectBonus = amount;

        emit MinimumSelfBuyForDirectBonusUpdate(amount);
    }


    function updateMaxChildTurnoverForSponsor(address account) internal {
        if (turnoverOf(account) + selfBuyOf(account) > maxChildTurnoverOf(sponsorOf(account))) {
            setMaxChildTurnoverFor(sponsorOf(account), turnoverOf(account) + selfBuyOf(account));
        }
    }

    function tryToUpdateRank(address account) internal {
        for (uint i = 0; i < AFFILIATE_RANKS.length; i++) {
            Rank memory curRank = AFFILIATE_RANKS[i];
            if (i < rankOf(account)) {
                continue;
            }
            if (turnoverOf(account) > curRank.turnover && selfBuyOf(account) > curRank.selfBuy) {
                uint256 requiredSplitValue = SafeMath.div(SafeMath.mul(turnoverOf(account), curRank.splitRulePercent), 100);
                if (maxChildTurnoverOf(account) <= requiredSplitValue) {
                    setRankFor(account, i);
                }
            }
        }
    }

    function calculateDirectBonus(uint256 amount) internal pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, DIRECT_FEE), 100);
    }

    function calculateIndirectBonus(uint256 amount, uint rank1, uint rank2) internal view returns(uint256) {
        uint256 percentDifference = AFFILIATE_RANKS[rank1].percent - AFFILIATE_RANKS[rank2].percent;
        return SafeMath.div(SafeMath.mul(amount, percentDifference), 100);
    }

    function isEligibleForDirectBonus(address sponsor) internal view returns(bool) {
        return (sponsor != address(this) && selfBuyOf(sponsor) > minimumSelfBuyForDirectBonus);
    }
}
