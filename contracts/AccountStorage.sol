// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./StandardToken.sol";


abstract contract AccountStorage is StandardToken {

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


    struct MigrationData {
        address account;
        address sponsor;
        uint256 tokensToMint;
    }


    bool private _accountsMigrated = false;

    EnumerableSet.AddressSet private _accounts;
    mapping (address => AccountData) private _accountsData;

    bytes32 public constant MIGRATION_MANAGER_ROLE = keccak256("MIGRATION_MANAGER_ROLE");

    event AccountCreation(address indexed account, address indexed sponsor);
    event AccountMigrationFinished();
    event FounderBonus(address indexed account, address indexed fromAccount, uint256 amountOfEthereum);
    event DirectBonus(address indexed account, address indexed fromAccount, uint256 amountOfEthereum);
    event IndirectBonus(address indexed account, address indexed fromAccount, uint256 amountOfEthereum);


    modifier isRegistered(address account) {
        require(_accountsMigrated, "AccountStorage: account data isn't migrated yet, try later");
        require(hasAccount(account), "AccountStorage: account must be registered first");
        _;
    }


    modifier hasEnoughBalance(uint256 amount) {
        require(amount <= balanceOf(msg.sender), "AccountStorage: insufficient account balance");
        _;
    }


    modifier hasEnoughAvailableEther(uint256 amount) {
        uint256 totalBonus = totalBonusOf(msg.sender);
        require(totalBonus > 0, "AccountStorage: you don't have any available ether");
        require(amount <= totalBonus, "AccountStorage: you don't have enough available ether to perform operation");
        _;
    }


    constructor() {
        addAccountData(address(this), address(0));
    }


    function migrateAccount(address account, address sponsor, uint256 tokensToMint) public {
        MigrationData[] memory data = new MigrationData[](1);
        data[0] = MigrationData(account, sponsor, tokensToMint);
        migrateAccountsInBatch(data);
    }


    function migrateAccountsInBatch(MigrationData[] memory data) public {
        require(hasRole(MIGRATION_MANAGER_ROLE, msg.sender), "AccountStorage: must have migration manager role to migrate data");
        require(data.length % 3 == 0, "AccountStorage: you must pass addesses in tuples of 3 elements");
        require(!_accountsMigrated, "AccountStorage: account data migration method is no more available");

        for (uint i = 0; i < data.length; i += 1) {
            address curAddress = data[i].account;
            address curSponsorAddress = data[i].sponsor;
            uint256 tokensToMint = data[i].tokensToMint;
            if (curSponsorAddress == address(0)) {
                curSponsorAddress = address(this);
            }
            addAccountData(curAddress, curSponsorAddress);
            _accounts.add(curAddress);
            increaseTotalSupply(tokensToMint);
            increaseBalanceOf(curAddress, tokensToMint);
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
            addAccountData(account, sponsor);
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


    function balanceOf(address account) public override view returns(uint256) {
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


    function distributionBonusOf(address account) public virtual view returns(uint256);


    function totalBonusOf(address account) public view returns(uint256) {
        return directBonusOf(account) + indirectBonusOf(account) + founderBonusOf(account) + cryptoRewardBonusOf(account)
            + distributionBonusOf(account) - withdrawnAmountOf(account) - reinvestedAmountOf(account);
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
        emit DirectBonus(account, msg.sender, amount);
    }


    function addIndirectBonusTo(address account, uint256 amount) internal {
        _accountsData[account].indirectBonus = _accountsData[account].indirectBonus.add(amount);
        emit IndirectBonus(account, msg.sender, amount);
    }


    function addFounderBonusTo(address account, uint256 amount) internal {
        _accountsData[account].founderBonus = _accountsData[account].founderBonus.add(amount);
        emit FounderBonus(account, msg.sender, amount);
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

    function addAccountData(address account, address sponsor) private {
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
    }
}
