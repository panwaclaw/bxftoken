// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;


import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract BXFToken is Context, AccessControl, Pausable {
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

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    EnumerableSet.AddressSet internal _registeredAccounts;
    EnumerableSet.AddressSet internal _founderAccounts;
    mapping (address => AccountData) internal _accountsData;
    uint256 private _totalSupply = 0;
    uint256 internal _profitPerShare;

    uint256 public _companyBalance = 0;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 constant internal INITIAL_TOKEN_PRICE = 0.0000001 ether;
    uint256 constant internal INCREMENT_TOKEN_PRICE = 0.00000001 ether;
    uint256 constant internal COMPANY_FEE = 30;
    uint256 constant internal FOUNDER_FEE = 1;
    uint256 constant internal DIRECT_FEE = 10;
    uint256 constant internal DISTRIBUTION_FEE = 7;
    uint256 constant internal MAGNITUDE = 2 ** 64;

    uint256 internal minimumSelfBuyForDirectBonus = 0.05 ether;


    Rank[] internal AFFILIATE_RANKS;

    
    event Buy(address indexed account, uint256 incomingEthereum, uint256 tokensMinted);
    event Sell(address indexed account, uint256 tokensBurned, uint256 ethereumEarned);
    event Reinvestment(address indexed account, uint256 ethereumReinvested, uint256 tokensMinted);
    event Withdraw(address indexed account, uint256 ethereumWithdrawn);
    event CryptoReward(address indexed account, uint256 ethereumPaid);
    event CompanyWithdraw(address indexed account, uint256 amount);
    event AccountRegistration(address indexed account, address indexed sponsor);
    event Transfer(address indexed from, address indexed to, uint256 value);


    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;

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

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
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

    function hasRegistered(address account) public view returns(bool) {
        return _registeredAccounts.contains(account);
    }
    
    
    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view returns (uint256) {
        return _accountsData[account].balance;
    }


    function isFounder(address account) public view returns(bool) {
        return _founderAccounts.contains(account);
    }


    function addFounder(address account) public returns(bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "EthPire: must have admin role to add founder");
        return _founderAccounts.add(account);
    }


    function removeFounder(address account) public returns(bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "EthPire: must have admin role to remove founder");
        return _founderAccounts.remove(account);
    }
    
    
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


    function payCryptoReward(address account) public payable {
        require(hasRole(MANAGER_ROLE, msg.sender), "BXFToken: must have manager role");
        _accountsData[account].cryptoRewardBonus.add(msg.value);

        emit CryptoReward(account, msg.value);
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


    function distributionBonusOf(address account) public view returns(uint256) {
        AccountData memory accountData = _accountsData[account];
        return (uint256) ((int256)(_profitPerShare * accountData.balance) - accountData.distributionBonus) / MAGNITUDE;
    }


    function withdrawnAmountOf(address account) public view returns(uint256) {
        return _accountsData[account].withdrawnAmount;
    }


    function reinvestedAmountOf(address account) public view returns(uint256) {
        return _accountsData[account].reinvestedAmount;
    }


    function totalBonusOf(address account) public view returns(uint256) {
        return directBonusOf(account) + indirectBonusOf(account) + founderBonusOf(account) + cryptoRewardBonusOf(account)
               + distributionBonusOf(account) - withdrawnAmountOf(account) - reinvestedAmountOf(account);
    }

    function setMinimumSelfBuyForDirectBonus(uint256 amount) public {
        minimumSelfBuyForDirectBonus = amount;
    }

    function hasAccount(address account) public view returns(bool) {
        return _registeredAccounts.contains(account);
    }

    function registerAccount(address sponsor) public returns(bool) {
        if (sponsor == address(0)) {
            sponsor = address(this);
        }
        if (sponsor != address(this)) {
            require(_registeredAccounts.contains(sponsor), "BXFToken: there's no such sponsor, consider joining with existing sponsor account or contract itself");
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
            _registeredAccounts.add(msg.sender);

            emit AccountRegistration(msg.sender, sponsor);
        }
        return false;
    }

    fallback() external payable isRegistered {
        purchaseTokens(msg.value);
    }

    function buy() public payable isRegistered {
        purchaseTokens(msg.value);
    }

    function sell(uint256 amountOfTokens) public isRegistered {
        AccountData storage accountData = _accountsData[msg.sender];
        require(amountOfTokens <= accountData.balance);
        uint256 ethereum = tokensToEthereum_(amountOfTokens);
        uint256 distributedBonus = SafeMath.div(SafeMath.mul(ethereum, DISTRIBUTION_FEE), 100);
        uint256 taxedEthereum = SafeMath.sub(ethereum, distributedBonus);

        _totalSupply.sub(amountOfTokens);
        accountData.balance.sub(amountOfTokens);

        if (isFounder(msg.sender)) {
            _founderAccounts.remove(msg.sender);
        }

        int256 distributedBonusUpdate = (int256) (_profitPerShare * amountOfTokens + (taxedEthereum * MAGNITUDE));
        accountData.distributionBonus -= distributedBonusUpdate;

        if (_totalSupply > 0) {
            // update the amount of dividends per token
            _profitPerShare.add((distributedBonus * MAGNITUDE) / _totalSupply);
        }

        emit Sell(msg.sender, amountOfTokens, taxedEthereum);
    }


    function withdraw() public isRegistered {
        require(totalBonusOf(msg.sender) > 0, "BXFToken: you don't have anything to withdraw");

        AccountData storage accountData = _accountsData[msg.sender];
        uint256 amountToWithdraw = totalBonusOf(msg.sender);

        accountData.distributionBonus += (int256) (distributionBonusOf(msg.sender) * MAGNITUDE);
        accountData.withdrawnAmount += amountToWithdraw;

        msg.sender.transfer(amountToWithdraw);

        emit Withdraw(msg.sender, amountToWithdraw);
    }


    function reinvest() public isRegistered {
        require(totalBonusOf(msg.sender) > 0, "BXFToken: you don't have anything to reinvest");

        AccountData storage accountData = _accountsData[msg.sender];
        uint256 amountToReinvest = totalBonusOf(msg.sender);

        accountData.reinvestedAmount += amountToReinvest;

        uint256 amountOfTokens = purchaseTokens(amountToReinvest);

        emit Reinvestment(msg.sender, amountToReinvest, amountOfTokens);
    }


    function exit() public isRegistered {
        uint256 _tokens = _accountsData[msg.sender].balance;
        if (_tokens > 0) {
            sell(_tokens);
        }
        withdraw();
    }


    function buyPrice() public view returns(uint256)
    {

        if (_totalSupply == 0){
            return INITIAL_TOKEN_PRICE + INCREMENT_TOKEN_PRICE;
        } else {
            uint256 ethereum = tokensToEthereum_(10 ** 18);
            uint256 distributedAmount = SafeMath.div(SafeMath.mul(ethereum, DISTRIBUTION_FEE), 100);
            uint256 taxedEthereum = SafeMath.add(ethereum, distributedAmount);
            return taxedEthereum;
        }
    }


    function sellPrice() public view returns(uint256) {
        if (_totalSupply == 0) {
            return INITIAL_TOKEN_PRICE - INCREMENT_TOKEN_PRICE;
        } else {
            uint256 ethereum = tokensToEthereum_(10 ** 18);
            uint256 totalFees = DISTRIBUTION_FEE;
            uint256 taxedAmount = SafeMath.div(SafeMath.mul(ethereum, totalFees), 100);
            uint256 taxedEthereum = SafeMath.sub(ethereum, taxedAmount);
            return taxedEthereum;
        }
    }


    function purchaseTokens(uint256 amountOfEthereum) internal returns(uint256) {
        uint256 taxedEthereum = amountOfEthereum;
        uint256 companyFee = SafeMath.div(SafeMath.mul(amountOfEthereum, COMPANY_FEE), 100);
        uint256 directBonus = SafeMath.div(SafeMath.mul(amountOfEthereum, DIRECT_FEE), 100);
        uint256 founderBonus = SafeMath.div(SafeMath.mul(amountOfEthereum, FOUNDER_FEE), 100);
        uint256 distributedBonus = SafeMath.div(SafeMath.mul(amountOfEthereum, DISTRIBUTION_FEE), 100);

        taxedEthereum.sub(companyFee);
        _companyBalance.add(companyFee);

        if (_founderAccounts.length() > 0) {
            taxedEthereum.sub(founderBonus);
            payoutToFounders(founderBonus);
        }

        address account = msg.sender;
        address sponsor = _accountsData[account].sponsor;
        _accountsData[account].selfBuy.add(amountOfEthereum);
        if (sponsor != address(this) && _accountsData[sponsor].selfBuy > minimumSelfBuyForDirectBonus) {
            _accountsData[sponsor].directBonus.add(directBonus);
            taxedEthereum.sub(directBonus);
        }

        uint256 maxRankUnder = _accountsData[account].rank;
        while (account != address(this)) {
            if (_accountsData[account].rank - maxRankUnder > 0 && account != msg.sender) {
                uint256 accountRank = _accountsData[account].rank;
                uint256 percentDifference = AFFILIATE_RANKS[accountRank].percent - AFFILIATE_RANKS[maxRankUnder].percent;
                uint256 indirectBonus = SafeMath.div(SafeMath.mul(amountOfEthereum, percentDifference), 100);
                taxedEthereum.sub(indirectBonus);
                _accountsData[account].indirectBonus.add(indirectBonus);
            }
            account = _accountsData[account].sponsor;
        }

        account = msg.sender;
        while (account != address(this)) {
            AccountData storage accountData = _accountsData[account];
            AccountData storage sponsorData = _accountsData[accountData.sponsor];
            if (accountData.turnover + accountData.selfBuy > sponsorData.maxChildTurnover) {
                sponsorData.maxChildTurnover = accountData.turnover + accountData.selfBuy;
            }
            if (account != msg.sender) {
                accountData.turnover += amountOfEthereum;
            }

            for (uint i = 0; i < AFFILIATE_RANKS.length; i++) {
                Rank memory curRank = AFFILIATE_RANKS[i];
                if (i < accountData.rank) {
                    continue;
                }
                if (accountData.turnover > curRank.turnover && accountData.selfBuy > curRank.selfBuy) {
                    if (accountData.maxChildTurnover <= SafeMath.div(SafeMath.mul(accountData.turnover, curRank.splitRulePercent), 100)) {
                        accountData.rank = i;
                    }
                }
            }
            account = accountData.sponsor;
        }

        uint256 amountOfTokens = ethereumToTokens_(taxedEthereum);

        uint256 distributionFee = distributedBonus * MAGNITUDE;

        if (_totalSupply > 0) {
            _totalSupply.add(amountOfTokens);
            _profitPerShare += distributedBonus * MAGNITUDE / _totalSupply;
            distributionFee = amountOfTokens * (distributedBonus * MAGNITUDE / _totalSupply);
        } else {
            _totalSupply = amountOfTokens;
        }
        _accountsData[msg.sender].balance.add(amountOfTokens);

        int256 distributionPayout = (int256) (_profitPerShare * amountOfTokens - distributionFee);
        _accountsData[msg.sender].distributionBonus += distributionPayout;

        emit Buy(msg.sender, taxedEthereum, amountOfTokens);

        return amountOfTokens;
    }


    function ethereumToTokens_(uint256 _ethereum) internal view returns(uint256) {
        uint256 _tokenPriceInitial = INITIAL_TOKEN_PRICE * 1e18;
        uint256 _tokensReceived =
        (
        (
        // underflow attempts BTFO
        SafeMath.sub(
            (sqrt
        (
            (_tokenPriceInitial**2)
            +
            (2*(INCREMENT_TOKEN_PRICE * 1e18)*(_ethereum * 1e18))
            +
            (((INCREMENT_TOKEN_PRICE)**2)*(_totalSupply**2))
            +
            (2*(INCREMENT_TOKEN_PRICE)*_tokenPriceInitial*_totalSupply)
        )
            ), _tokenPriceInitial
        )
        )/(INCREMENT_TOKEN_PRICE)
        )-(_totalSupply)
        ;

        return _tokensReceived;
    }


    function tokensToEthereum_(uint256 _tokens) internal view returns(uint256) {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (_totalSupply + 1e18);
        uint256 _etherReceived =
        (
        // underflow attempts BTFO
        SafeMath.sub(
            (
              (
                (INITIAL_TOKEN_PRICE + (INCREMENT_TOKEN_PRICE * (_tokenSupply / 1e18))) - INCREMENT_TOKEN_PRICE) * (tokens_ - 1e18)
            ), (INCREMENT_TOKEN_PRICE* ((tokens_ ** 2 - tokens_) / 1e18)) / 2
        )
        /1e18);
        return _etherReceived;
    }


    function payoutToFounders(uint256 founderBonus) internal view {
        uint256 foundersCount = _founderAccounts.length();

        for (uint i = 0; i < foundersCount; i++) {
            _accountsData[_founderAccounts.at(i)].founderBonus.add(SafeMath.div(founderBonus, foundersCount));
        }
    }


    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view {
        require(!paused(), "BXFToken: token transfer while paused");
    }


    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _accountsData[sender].balance);

        _beforeTokenTransfer(sender, recipient, amount);

        // withdraw all outstanding dividends first
        if (totalBonusOf(sender) > 0) withdraw();

        uint256 distributionFee = SafeMath.div(SafeMath.mul(amount, DISTRIBUTION_FEE), 100);
        uint256 taxedTokens = SafeMath.sub(amount, distributionFee);
        uint256 distributedBonus = tokensToEthereum_(distributionFee);

        // burn the fee tokens
        _totalSupply.sub(distributionFee);

        // exchange tokens
        _accountsData[sender].balance.sub(amount, "BXFToken: transfer amount exceeds balance");
        _accountsData[recipient].balance.add(taxedTokens);

        // update dividend trackers
        _accountsData[sender].distributionBonus -= (int256) (_profitPerShare * amount);
        _accountsData[recipient].distributionBonus += (int256) (_profitPerShare * taxedTokens);

        // disperse dividends among holders
        _profitPerShare.add((distributedBonus * MAGNITUDE) / _totalSupply);

        // fire event
        emit Transfer(sender, recipient, taxedTokens);
    }
}
