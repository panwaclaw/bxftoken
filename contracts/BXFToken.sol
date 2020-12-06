// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./Company.sol";
import "./Founder.sol";
import "./CryptoReward.sol";
import "./Distributable.sol";


contract BXFToken is Distributable, CryptoReward, Founder, Company {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;


    uint256 constant internal COMPANY_FEE = 30;
    uint256 constant internal FOUNDER_FEE = 1;
    uint256 constant internal DIRECT_FEE = 10;

    uint256 internal minimumSelfBuyForDirectBonus = 0.05 ether;

    
    event Buy(address indexed account, uint256 incomingEthereum, uint256 tokensMinted);
    event Sell(address indexed account, uint256 tokensBurned, uint256 ethereumEarned);
    event Reinvestment(address indexed account, uint256 ethereumReinvested, uint256 tokensMinted);
    event Withdraw(address indexed account, uint256 ethereumWithdrawn);
    event Transfer(address indexed from, address indexed to, uint256 value);


    constructor(string memory name, string memory symbol) StandardToken(name, symbol)  {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function setMinimumSelfBuyForDirectBonus(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BXFToken: must have admin role to add founder");
        minimumSelfBuyForDirectBonus = amount;
    }


    fallback() external payable isRegistered {
        purchaseTokens(msg.value);
    }


    function buy() public payable isRegistered {
        purchaseTokens(msg.value);
    }


    function sell(uint256 amountOfTokens) public isRegistered {
        require(amountOfTokens <= balanceOf(msg.sender));
        uint256 ethereum = tokensToEthereum(amountOfTokens);
        uint256 distributedBonus = calculateDistributedAmount(ethereum);
        uint256 taxedEthereum = SafeMath.sub(ethereum, distributedBonus);

        decreaseTotalSupply(amountOfTokens);
        decreaseBalanceOf(msg.sender, amountOfTokens);

        if (isFounder(msg.sender)) {
            dropFounder(msg.sender);
        }

        int256 distributedBonusUpdate = (int256) (getProfitPerShare() * amountOfTokens + (taxedEthereum * MAGNITUDE));
        decreaseDistributionBonusValueFor(msg.sender, distributedBonusUpdate);

        if (totalSupply() > 0) {
            increaseProfitPerShare(distributedBonus);
        }

        emit Sell(msg.sender, amountOfTokens, taxedEthereum);
    }


    function withdraw() public isRegistered {
        require(totalBonusOf(msg.sender) > 0, "BXFToken: you don't have anything to withdraw");

        uint256 amountToWithdraw = totalBonusOf(msg.sender);

        increaseDistributionBonusValueFor(msg.sender, (int256) (distributionBonusOf(msg.sender) * MAGNITUDE));
        addWithdrawnAmountTo(msg.sender, amountToWithdraw);

        msg.sender.transfer(amountToWithdraw);

        emit Withdraw(msg.sender, amountToWithdraw);
    }


    function reinvest() public isRegistered {
        require(totalBonusOf(msg.sender) > 0, "BXFToken: you don't have anything to reinvest");

        uint256 amountToReinvest = totalBonusOf(msg.sender);

        addReinvestedAmountTo(msg.sender, amountToReinvest);

        uint256 amountOfTokens = purchaseTokens(amountToReinvest);

        emit Reinvestment(msg.sender, amountToReinvest, amountOfTokens);
    }


    function exit() public isRegistered {
        uint256 _tokens = balanceOf(msg.sender);
        if (_tokens > 0) {
            sell(_tokens);
        }
        withdraw();
    }


    function purchaseTokens(uint256 amountOfEthereum) internal returns(uint256) {
        uint256 taxedEthereum = amountOfEthereum;
        uint256 companyFee = SafeMath.div(SafeMath.mul(amountOfEthereum, COMPANY_FEE), 100);
        uint256 directBonus = SafeMath.div(SafeMath.mul(amountOfEthereum, DIRECT_FEE), 100);
        uint256 founderBonus = SafeMath.div(SafeMath.mul(amountOfEthereum, FOUNDER_FEE), 100);
        uint256 distributedBonus = calculateDistributedAmount(amountOfEthereum);

        taxedEthereum.sub(companyFee);
        increaseCompanyBalance(companyFee);

        if (getFoundersCount() > 0) {
            taxedEthereum.sub(founderBonus);
            payToFounders(founderBonus);
        }

        address account = msg.sender;
        address sponsor = sponsorOf(account);
        increaseSelfBuyOf(account, amountOfEthereum);
        if (sponsor != address(this) && selfBuyOf(sponsor) > minimumSelfBuyForDirectBonus) {
            addDirectBonusTo(sponsor, directBonus);
            taxedEthereum.sub(directBonus);
        }

        uint256 maxRankUnder = rankOf(account);
        while (account != address(this)) {
            if (rankOf(account) - maxRankUnder > 0 && account != msg.sender) {
                uint256 accountRank = rankOf(account);
                uint256 indirectBonus = calculateIndirectBonus(amountOfEthereum, accountRank, maxRankUnder);
                taxedEthereum.sub(indirectBonus);
                addIndirectBonusTo(account, indirectBonus);
            }
            account = sponsorOf(account);
        }

        account = msg.sender;
        while (account != address(this)) {
            updateMaxChildTurnoverForSponsor(account);

            if (account != msg.sender) {
                increaseTurnoverOf(account, amountOfEthereum);
            }

            tryToUpdateRank(account);

            account = sponsorOf(account);
        }

        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);

        uint256 distributionFee = distributedBonus * MAGNITUDE;

        if (totalSupply() > 0) {
            increaseTotalSupply(amountOfTokens);
            increaseProfitPerShare(distributedBonus);
            distributionFee = amountOfTokens * (distributedBonus * MAGNITUDE / totalSupply());
        } else {
            setTotalSupply(amountOfTokens);
        }
        increaseBalanceOf(msg.sender, amountOfTokens);

        int256 distributionPayout = (int256) (getProfitPerShare() * amountOfTokens - distributionFee);
        increaseDistributionBonusValueFor(msg.sender, distributionPayout);

        emit Buy(msg.sender, taxedEthereum, amountOfTokens);

        return amountOfTokens;
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
        require(amount <= balanceOf(sender));

        _beforeTokenTransfer(sender, recipient, amount);

        // withdraw all outstanding dividends first
        if (totalBonusOf(sender) > 0) withdraw();

        uint256 distributionFee = calculateDistributedAmount(amount);
        uint256 taxedTokens = SafeMath.sub(amount, distributionFee);
        uint256 distributedBonus = tokensToEthereum(distributionFee);

        // burn the fee tokens
        decreaseTotalSupply(distributionFee);

        // exchange tokens
        decreaseBalanceOf(sender, amount);
        increaseBalanceOf(recipient, taxedTokens);

        // update dividend trackers
        decreaseDistributionBonusValueFor(sender, (int256) (getProfitPerShare() * amount));
        increaseDistributionBonusValueFor(recipient, (int256) (getProfitPerShare() * taxedTokens));
        
        // disperse dividends among holders
        increaseProfitPerShare(distributedBonus);

        // fire event
        emit Transfer(sender, recipient, taxedTokens);
    }
}
