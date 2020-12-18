// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AccountStorage.sol";
import "./RankSystem.sol";


abstract contract MultiLevelTree is AccountStorage, RankSystem {

    using SafeMath for uint256;

    uint256 constant private DIRECT_FEE = 10;
    uint256 private minimumSelfBuyForDirectBonus = 0.05 ether;

    event MinimumSelfBuyForDirectBonusUpdate(uint256 amount);


    function getMinimumSelfBuyForDirectBonus() public view returns(uint256) {
        return minimumSelfBuyForDirectBonus;
    }


    function setMinimumSelfBuyForDirectBonus(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MultiLevelTree: must have company manager role to set minimum self buy for direct bonus");
        minimumSelfBuyForDirectBonus = amount;

        emit MinimumSelfBuyForDirectBonusUpdate(amount);
    }


    function getRequirementsToRankUp(address account) public view returns(uint256, uint256, uint256) {
        require(rankOf(account) + 1 < getRanksCount(), "Calculator: you've already achieved highest rank");
        Rank memory reqRank = getRankDetails(rankOf(account) + 1);
        uint256 selfBuy = selfBuyOf(account);
        uint256 turnover = turnoverOf(account);
        uint256 maxChildTurnover = maxChildTurnoverOf(account);
        uint256 reqRankSplitTurnover = SafeMath.div(SafeMath.mul(reqRank.turnover, reqRank.splitRulePercent), 100);
        uint256 reqSelfBuy = (selfBuy < reqRank.selfBuy) ? (reqRank.selfBuy - selfBuy) : 0;
        uint256 reqTurnover = (turnover < reqRank.turnover) ? (reqRank.turnover - turnover) : 0;
        uint256 reqTurnoverSplit = (reqRankSplitTurnover < maxChildTurnover) ? (maxChildTurnover - reqRankSplitTurnover) : 0;

        return (reqSelfBuy, reqTurnover, reqTurnoverSplit);
    }


    function updateMaxChildTurnoverForSponsor(address account) internal {
        if (turnoverOf(account) + selfBuyOf(account) > maxChildTurnoverOf(sponsorOf(account))) {
            setMaxChildTurnoverFor(sponsorOf(account), turnoverOf(account) + selfBuyOf(account));
        }
    }


    function payIndirectBonusStartingFrom(address account, uint256 amountOfEthereum) internal returns(uint256) {
        address curAccount = account;
        uint256 maxRankUnder = rankOf(curAccount);
        uint256 totalIndirectBonus = 0;

        while (curAccount != address(this)) {
            uint256 curRank = rankOf(curAccount);
            if (curRank > maxRankUnder && curAccount != account) {
                uint256 indirectBonus = calculateIndirectBonus(amountOfEthereum, curRank, maxRankUnder);
                addIndirectBonusTo(curAccount, indirectBonus);
                totalIndirectBonus = totalIndirectBonus.add(indirectBonus);
                maxRankUnder = curRank;
            }
            curAccount = sponsorOf(curAccount);
        }
        return totalIndirectBonus;
    }


    function updateTurnoversAndRanksStartingFrom(address account, uint256 amountOfEthereum) internal {
        address curAccount = account;
        while (curAccount != address(this)) {
            if (curAccount != account) increaseTurnoverOf(curAccount, amountOfEthereum);
            updateMaxChildTurnoverForSponsor(curAccount);
            tryToUpdateRank(curAccount);
            curAccount = sponsorOf(curAccount);
        }
    }


    function tryToUpdateRank(address account) internal {
        for (uint i = 0; i < getRanksCount(); i++) {
            Rank memory curRank = getRankDetails(i);
            if (i < rankOf(account)) {
                continue;
            }
            if (turnoverOf(account) >= curRank.turnover && selfBuyOf(account) >= curRank.selfBuy) {
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
        uint256 percentDifference = getRankDetails(rank1).percent - getRankDetails(rank2).percent;
        return SafeMath.div(SafeMath.mul(amount, percentDifference), 100);
    }

    function isEligibleForDirectBonus(address sponsor) internal view returns(bool) {
        return (sponsor != address(this) && selfBuyOf(sponsor) >= minimumSelfBuyForDirectBonus);
    }
}
