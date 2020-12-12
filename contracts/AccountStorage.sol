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

    bool private _accountsMigrated = false;

    EnumerableSet.AddressSet private _accounts;
    mapping (address => AccountData) private _accountsData;

    bytes32 public constant MIGRATION_MANAGER_ROLE = keccak256("MIGRATION_MANAGER_ROLE");

    event AccountCreation(address indexed account, address indexed sponsor);
    event AccountMigrationFinished();


    modifier isRegistered() {
        require(_accountsMigrated, "AccountStorage: account data isn't migrated yet, try later");
        require(hasAccount(msg.sender), "AccountStorage: account must be registered first");
        _;
    }


    constructor() {
        address contractAddress = address(this);
        AccountData memory accountData = AccountData({
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
        _accountsData[contractAddress] = accountData;
    }


    function migrateAccount(address account, address sponsor) public {
        require(hasRole(MIGRATION_MANAGER_ROLE, msg.sender), "AccountStorage: must have migration manager role to migrate data");
        require(!_accountsMigrated, "AccountStorage: account data migration method is no more available");

        if (sponsor == address(0)) {
            sponsor = address(this);
        }
        AccountData memory accountData = AccountData({
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
        _accountsData[account] = accountData;
        _accounts.add(account);
        emit AccountCreation(account, sponsor);
    }


    function migrateAccountsInBatch(address[] memory addresses) public {
        require(hasRole(MIGRATION_MANAGER_ROLE, msg.sender), "AccountStorage: must have migration manager role to migrate data");
        require(addresses.length % 2 == 0, "AccountStorage: you must pass addesses in pairs");
        require(!_accountsMigrated, "AccountStorage: account data migration method is no more available");

        for (uint i = 0; i < addresses.length; i += 2) {
            address curAddress = addresses[i];
            address curSponsorAddress = addresses[i + 1];
            if (curSponsorAddress == address(0)) {
                curSponsorAddress = address(this);
            }
            AccountData memory accountData = AccountData({
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
            _accountsData[curAddress] = accountData;
            _accounts.add(curAddress);
            emit AccountCreation(curAddress, curSponsorAddress);
        }
    }


    function isDataMigrated() public view returns(bool) {
        return _accountsMigrated;
    }


    function finishAccountMigration() public {
        require(hasRole(MIGRATION_MANAGER_ROLE, msg.sender), "AccountStorage: must have migration manager role to migrate data");
        require(!_accountsMigrated, "AccountStorage: account data migration method is no more available");

        _accountsMigrated = true;
        emit AccountMigrationFinished();
    }


    function createAccount(address sponsor) public returns(bool) {
        require(_accountsMigrated, "AccountStorage: account data isn't migrated yet, try later");

        address account = msg.sender;

        if (sponsor == address(0)) {
            sponsor = address(this);
        }
        if (sponsor != address(this)) {
            require(_accounts.contains(sponsor), "AccountStorage: there's no such sponsor, consider joining with existing sponsor account or contract itself");
        }
        if (!hasAccount(account)) {
            AccountData memory accountData = AccountData({
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
            _accountsData[account] = accountData;
            _accounts.add(account);

            emit AccountCreation(account, sponsor);
            return true;
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


    function increaseSelfBuyOf(address account, uint256 amount) internal {
        _accountsData[account].selfBuy =_accountsData[account].selfBuy.add(amount);
    }


    function increaseTurnoverOf(address account, uint256 amount) internal {
        _accountsData[account].turnover = _accountsData[account].turnover.add(amount);
    }


    function increaseBalanceOf(address account, uint256 amount) internal {
        _accountsData[account].balance = _accountsData[account].balance.add(amount);
    }


    function decreaseBalanceOf(address account, uint256 amount) internal {
        _accountsData[account].balance = _accountsData[account].balance.sub(amount, "AccountStorage: amount exceeds balance");
    }


    function addDirectBonusTo(address account, uint256 amount) internal {
        _accountsData[account].directBonus = _accountsData[account].directBonus.add(amount);
    }


    function addIndirectBonusTo(address account, uint256 amount) internal {
        _accountsData[account].indirectBonus = _accountsData[account].indirectBonus.add(amount);
    }


    function addFounderBonusTo(address account, uint256 amount) internal {
        _accountsData[account].founderBonus = _accountsData[account].founderBonus.add(amount);
    }


    function addCryptoRewardBonusTo(address account, uint256 amount) internal {
        _accountsData[account].cryptoRewardBonus = _accountsData[account].cryptoRewardBonus.add(amount);
    }


    function addWithdrawnAmountTo(address account, uint256 amount) internal {
        _accountsData[account].withdrawnAmount = _accountsData[account].withdrawnAmount.add(amount);
    }


    function addReinvestedAmountTo(address account, uint256 amount) internal {
        _accountsData[account].reinvestedAmount = _accountsData[account].reinvestedAmount.add(amount);
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
