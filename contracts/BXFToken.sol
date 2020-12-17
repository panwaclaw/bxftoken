// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./Company.sol";
import "./CryptoReward.sol";
import "./Distributable.sol";
import "./Founder.sol";
import "./Sale.sol";


contract BXFToken is Distributable, CryptoReward, Founder, Company, Sale {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    
    event Buy(address indexed account, uint256 incomingEthereum, uint256 tokensMinted);
    event Sell(address indexed account, uint256 tokensBurned, uint256 ethereumEarned);
    event Reinvestment(address indexed account, uint256 ethereumReinvested, uint256 tokensMinted);
    event Withdraw(address indexed account, uint256 ethereumWithdrawn);
    event Transfer(address indexed from, address indexed to, uint256 value);


    constructor(string memory name, string memory symbol) StandardToken(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    fallback() external payable isRegistered {
        purchaseTokens(msg.sender, msg.value);
    }


    function buy() public payable isRegistered {
        purchaseTokens(msg.sender, msg.value);
    }


    function sell(uint256 amountOfTokens) public isRegistered hasEnoughBalance(amountOfTokens) {
        address account = msg.sender;

        decreaseTotalSupply(amountOfTokens);
        decreaseBalanceOf(account, amountOfTokens);

        if (isFounder(account)) dropFounder(account);

        uint256 taxedEthereum = processDistributionOnSell(account, amountOfTokens);

        msg.sender.transfer(taxedEthereum);

        emit Sell(account, amountOfTokens, taxedEthereum);
    }


    function withdraw(uint256 amountToWithdraw) public isRegistered hasEnoughAvailableEther(amountToWithdraw) {
        require(amountToWithdraw <= address(this).balance, "BXFToken: insufficient contract balance");

        address account = msg.sender;
        addWithdrawnAmountTo(account, amountToWithdraw);
        msg.sender.transfer(amountToWithdraw);

        emit Withdraw(account, amountToWithdraw);
    }


    function reinvest(uint256 amountToReinvest) public isRegistered hasEnoughAvailableEther(amountToReinvest) {
        address account = msg.sender;

        addReinvestedAmountTo(account, amountToReinvest);
        uint256 amountOfTokens = purchaseTokens(account, amountToReinvest);

        emit Reinvestment(account, amountToReinvest, amountOfTokens);
    }


    function exit() public isRegistered {
        address account = msg.sender;
        if (balanceOf(account) > 0) {
            sell(balanceOf(account));
        }
        withdraw(totalBonusOf(account));
    }


    function purchaseTokens(address senderAccount, uint256 amountOfEthereum) internal canInvest(amountOfEthereum) returns(uint256) {
        uint256 taxedEthereum = amountOfEthereum;

        uint256 companyFee = calculateCompanyFee(amountOfEthereum);
        uint256 directBonus = calculateDirectBonus(amountOfEthereum);
        uint256 founderBonus = calculateFounderBonus(amountOfEthereum);
        uint256 distributedBonus = calculateDistributedAmount(amountOfEthereum);

        taxedEthereum = taxedEthereum.sub(companyFee);
        increaseCompanyBalance(companyFee);

        if (getFoundersCount() > 0) {
            taxedEthereum = taxedEthereum.sub(founderBonus);
            payToFounders(founderBonus);
        }

        address account = senderAccount;
        address sponsor = sponsorOf(account);
        increaseSelfBuyOf(account, amountOfEthereum);

        if (isEligibleForDirectBonus(sponsor)) {
            addDirectBonusTo(sponsor, directBonus);
            taxedEthereum = taxedEthereum.sub(directBonus);
        }

        uint256 maxRankUnder = rankOf(account);
        while (account != address(this)) {
            uint256 curRank = rankOf(account);
            if (curRank > maxRankUnder && account != senderAccount) {
                uint256 indirectBonus = calculateIndirectBonus(amountOfEthereum, curRank, maxRankUnder);
                taxedEthereum = taxedEthereum.sub(indirectBonus);
                addIndirectBonusTo(account, indirectBonus);

                maxRankUnder = curRank;

            }

            account = sponsorOf(account);
        }

        account = senderAccount;
        while (account != address(this)) {
            if (account != senderAccount) increaseTurnoverOf(account, amountOfEthereum);
            updateMaxChildTurnoverForSponsor(account);
            tryToUpdateRank(account);
            account = sponsorOf(account);
        }

        taxedEthereum = taxedEthereum.sub(distributedBonus);

        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);

        processDistributionOnBuy(senderAccount, amountOfTokens, distributedBonus);
        increaseBalanceOf(senderAccount, amountOfTokens);

        emit Buy(senderAccount, taxedEthereum, amountOfTokens);

        return amountOfTokens;
    }


    function transfer(address recipient, uint256 amount) public override hasEnoughBalance(amount) returns(bool) {
        address sender = msg.sender;

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 distributionFee = calculateDistributedAmount(amount);
        uint256 taxedTokens = SafeMath.sub(amount, distributionFee);

        decreaseTotalSupply(distributionFee);

        decreaseBalanceOf(sender, amount);
        increaseBalanceOf(recipient, taxedTokens);

        processDistributionOnTransfer(sender, amount, recipient, taxedTokens);

        emit Transfer(sender, recipient, taxedTokens);
        return true;
    }
}
