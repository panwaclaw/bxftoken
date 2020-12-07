// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";


contract AccountStorage is AccessControl {

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

    bool private _migrated = false;

    EnumerableSet.AddressSet private _accounts;
    mapping (address => AccountData) private _accountsData;

    event AccountCreation(address indexed account, address indexed sponsor);
    event MigrationFinished();


    modifier isRegistered() {
        require(_migrated, "BXFToken: account data isn't migrated yet, try later");
        require(hasAccount(msg.sender), "BXFToken: account must be registered by manager first");
        _;
    }


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
    }


    function migrateAccount(address account, address sponsor) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BXFToken: must have admin role to migrate data");
        require(!_migrated, "BXFToken: data migration process is no more available");

        if (sponsor == address(0)) {
            sponsor = address(this);
        }
        _accountsData[account] = AccountData({
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
        _accounts.add(account);
        emit AccountCreation(account, sponsor);
    }


    function migrateAccountsInBatch(address[] memory addresses) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BXFToken: must have admin role to migrate data");
        require(addresses.length % 2 == 0, "BXFToken: you must pass addesses in pairs");
        require(!_migrated, "BXFToken: data migration process is no more available");

        for (uint i = 0; i < addresses.length; i += 2) {
            address curAddress = addresses[i];
            address curSponsorAddress = addresses[i + 1];
            if (curSponsorAddress == address(0)) {
                curSponsorAddress = address(this);
            }
            _accountsData[curAddress] = AccountData({
                sponsor: curSponsorAddress,
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
            _accounts.add(curAddress);
            emit AccountCreation(curAddress, curSponsorAddress);
        }
    }


    function isMigrated() public view returns(bool) {
        return _migrated;
    }


    function finishMigration() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BXFToken: must have admin role to migrate data");
        require(!_migrated, "BXFToken: data migration process is no more available");

        _migrated = true;
        emit MigrationFinished();
    }


    function createAccount(address sponsor) public returns(bool) {
        require(_migrated, "BXFToken: account data isn't migrated yet, try later");

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


    function getAccountsCount() public view returns(uint256) {
        return _accounts.length();
    }


    function hasAccount(address account) public view returns(bool) {
        return _accounts.contains(account);
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


    function maxChildTurnoverOf(address account) internal view returns(uint256) {
        return _accountsData[account].maxChildTurnover;
    }


    function setMaxChildTurnoverFor(address account, uint256 amount) internal {
        _accountsData[account].maxChildTurnover = amount;
    }


    function setRankFor(address account, uint256 rank) internal {
        _accountsData[account].rank = rank;
    }
}
