// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./Company.sol";
import "./Founder.sol";
import "./CryptoReward.sol";
import "./Distributable.sol";


contract BXFToken is Distributable, CryptoReward, Founder, Company {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    
    event Buy(address indexed account, uint256 incomingEthereum, uint256 tokensMinted);
    event Sell(address indexed account, uint256 tokensBurned, uint256 ethereumEarned);
    event Reinvestment(address indexed account, uint256 ethereumReinvested, uint256 tokensMinted);
    event Withdraw(address indexed account, uint256 ethereumWithdrawn);
    event Transfer(address indexed from, address indexed to, uint256 value);


    constructor(string memory name, string memory symbol) StandardToken(name, symbol)  {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    fallback() external payable isRegistered {
        purchaseTokens(msg.value);
    }


    function buy() public payable isRegistered {
        purchaseTokens(msg.value);
    }

    function returnAddressThis() public view returns(address) {
        return address(this);
    }

    function sell(uint256 amountOfTokens) public isRegistered {
        require(amountOfTokens <= balanceOf(msg.sender));

        decreaseTotalSupply(amountOfTokens);
        decreaseBalanceOf(msg.sender, amountOfTokens);

        if (isFounder(msg.sender)) dropFounder(msg.sender);

        uint256 taxedEthereum = processDistributionOnSell(amountOfTokens);


        emit Sell(msg.sender, amountOfTokens, taxedEthereum);
    }


    function withdraw() public isRegistered {
        require(totalBonusOf(msg.sender) > 0, "BXFToken: you don't have anything to withdraw");

        uint256 amountToWithdraw = totalBonusOf(msg.sender);

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

        uint256 companyFee = calculateCompanyFee(amountOfEthereum);
        uint256 directBonus = calculateDirectBonus(amountOfEthereum);
        uint256 founderBonus = calculateFounderBonus(amountOfEthereum);
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

        if (isEligibleForDirectBonus(sponsor)) {
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
            if (account != msg.sender) increaseTurnoverOf(account, amountOfEthereum);
            updateMaxChildTurnoverForSponsor(account);
            tryToUpdateRank(account);
            account = sponsorOf(account);
        }

        taxedEthereum.sub(distributedBonus);

        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);

        processDistributionOnBuy(amountOfTokens, distributedBonus);
        increaseBalanceOf(msg.sender, amountOfTokens);

        emit Buy(msg.sender, taxedEthereum, amountOfTokens);

        return amountOfTokens;
    }


    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BXFToken: transfer from the zero address");
        require(recipient != address(0), "BXFToken: transfer to the zero address");
        require(amount <= balanceOf(sender));

        _beforeTokenTransfer(sender, recipient, amount);

        if (totalBonusOf(sender) > 0) withdraw();

        uint256 distributionFee = calculateDistributedAmount(amount);
        uint256 taxedTokens = SafeMath.sub(amount, distributionFee);
        uint256 distributedBonus = tokensToEthereum(distributionFee);

        decreaseTotalSupply(distributionFee);

        decreaseBalanceOf(sender, amount);
        increaseBalanceOf(recipient, taxedTokens);

        decreaseDistributionBonusValueFor(sender, (int256) (getProfitPerShare() * amount));
        increaseDistributionBonusValueFor(recipient, (int256) (getProfitPerShare() * taxedTokens));
        
        increaseProfitPerShare(distributedBonus);

        emit Transfer(sender, recipient, taxedTokens);
    }
}
