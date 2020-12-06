// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract MultiLevelTreeAccountStorage {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    struct AccountData {
        address sponsor;
        uint256 balance;
        uint256 selfBuy;
        uint rank;
        uint256 turnover;
        uint256 maxChildTurnover;
        uint256 directBonus;
        uint256 indirectBonus;
        uint256 founderBonus;
        uint256 cryptoRewardBonus;
        uint256 reinvestedAmount;
        uint256 withdrawnAmount;
        int256 distributionBonus;
    }

    struct Rank {
        string name;
        uint256 selfBuy;
        uint256 turnover;
        uint256 percent;
        uint256 splitRulePercent;
    }

    EnumerableSet.AddressSet private _accounts;
    mapping (address => AccountData) private _accountsData;
    Rank[] private AFFILIATE_RANKS;

    event AccountCreation(address indexed account, address indexed sponsor);


    constructor() {
        _accountsData[msg.sender] = AccountData({
        sponsor: address(0),
        balance: 0,
        rank: 0,
        selfBuy: 0,
        turnover: 0,
        maxChildTurnover: 0,
        directBonus: 0,
        indirectBonus: 0,
        founderBonus: 0,
        cryptoRewardBonus: 0,
        reinvestedAmount: 0,
        withdrawnAmount: 0,
        distributionBonus: 0
        });

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


    modifier isRegistered() {
        require(hasAccount(msg.sender), "BXFToken: account must be registered by manager first");
        _;
    }


    function hasAccount(address account) public view returns(bool) {
        return _accounts.contains(account);
    }


    function createAccount(address sponsor) public returns(bool) {
        if (sponsor == address(0)) {
            sponsor = address(this);
        }
        if (sponsor != address(this)) {
            require(_accounts.contains(sponsor), "BXFToken: there's no such sponsor, consider joining with existing sponsor account or contract itself");
        }
        if (!hasAccount(msg.sender)) {
            _accountsData[msg.sender] = AccountData({
            sponsor: sponsor,
            balance: 0,
            rank: 0,
            selfBuy: 0,
            turnover: 0,
            maxChildTurnover: 0,
            directBonus: 0,
            indirectBonus: 0,
            founderBonus: 0,
            cryptoRewardBonus: 0,
            reinvestedAmount: 0,
            withdrawnAmount: 0,
            distributionBonus: 0
            });
            _accounts.add(msg.sender);

            emit AccountCreation(msg.sender, sponsor);
        }
        return false;
    }

    function sponsorOf(address account) public view returns(address) {
        return _accountsData[account].sponsor;
    }

    function selfBuyOf(address account) public view returns(uint256) {
        return _accountsData[account].selfBuy;
    }

    function turnoverOf(address account) public view returns(uint256) {
        return _accountsData[account].turnover;
    }

    function rankOf(address account) public view returns(uint) {
        return _accountsData[account].rank;
    }

    function balanceOf(address account) public view returns(uint256) {
        return _accountsData[account].balance;
    }

    function directBonusOf(address account) public view returns(uint256) {
        return _accountsData[account].directBonus;
    }


    function indirectBonusOf(address account) public view returns(uint256) {
        return _accountsData[account].indirectBonus;
    }


    function founderBonusOf(address account) public view returns(uint256) {
        return _accountsData[account].founderBonus;
    }


    function cryptoRewardBonusOf(address account) public view returns(uint256) {
        return _accountsData[account].cryptoRewardBonus;
    }


    function withdrawnAmountOf(address account) public view returns(uint256) {
        return _accountsData[account].withdrawnAmount;
    }


    function reinvestedAmountOf(address account) public view returns(uint256) {
        return _accountsData[account].reinvestedAmount;
    }


    function increaseSelfBuyOf(address account, uint256 amount) internal view {
        _accountsData[account].selfBuy.add(amount);
    }


    function increaseTurnoverOf(address account, uint256 amount) internal view {
        _accountsData[account].turnover.add(amount);
    }


    function increaseBalanceOf(address account, uint256 amount) internal view {
        _accountsData[account].balance.add(amount);
    }


    function decreaseBalanceOf(address account, uint256 amount) internal view {
        _accountsData[account].balance.sub(amount, "BXFToken: transfer amount exceeds balance");
    }


    function addDirectBonusTo(address account, uint256 amount) internal view {
        _accountsData[account].directBonus.add(amount);
    }


    function addIndirectBonusTo(address account, uint256 amount) internal view {
        _accountsData[account].indirectBonus.add(amount);
    }


    function addFounderBonusTo(address account, uint256 amount) internal view {
        _accountsData[account].founderBonus.add(amount);
    }

    function addCryptoRewardBonusTo(address account, uint256 amount) internal view {
        _accountsData[account].cryptoRewardBonus.add(amount);
    }

    function addWithdrawnAmountTo(address account, uint256 amount) internal view{
        _accountsData[account].withdrawnAmount.add(amount);
    }

    function addReinvestedAmountTo(address account, uint256 amount) internal view {
        _accountsData[account].reinvestedAmount.add(amount);
    }

    function getDistributionBonusValueOf(address account) internal view returns(int256) {
        return _accountsData[account].distributionBonus;
    }

    function increaseDistributionBonusValueFor(address account, int256 amount) internal {
        _accountsData[account].distributionBonus += amount;
    }


    function decreaseDistributionBonusValueFor(address account, int256 amount) internal {
        _accountsData[account].distributionBonus -= amount;
    }

    function updateMaxChildTurnoverForSponsor(address account) internal {
        if (turnoverOf(account) + selfBuyOf(account) > _accountsData[sponsorOf(account)].maxChildTurnover) {
            _accountsData[sponsorOf(account)].maxChildTurnover = turnoverOf(account) + selfBuyOf(account);
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
                if (_accountsData[account].maxChildTurnover <= requiredSplitValue) {
                    _accountsData[account].rank = i;
                }
            }
        }
    }

    function calculateIndirectBonus(uint256 amount, uint rank1, uint rank2) internal view returns(uint256) {
        uint256 percentDifference = AFFILIATE_RANKS[rank1].percent - AFFILIATE_RANKS[rank2].percent;
        return SafeMath.div(SafeMath.mul(amount, percentDifference), 100);
    }


}
