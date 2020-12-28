// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Company.sol";
import "./CryptoReward.sol";
import "./Distributable.sol";
import "./Founder.sol";
import "./Sale.sol";


abstract contract BXFTokenBase is Distributable, Company, Sale, CryptoReward {
    using SafeMath for uint256;


    struct BuySpendings {
        uint256 companyFee;
        uint256 directBonus;
        uint256 indirectBonus;
        uint256 founderBonus;
        uint256 distributedBonus;
        uint256 ethereumLeft;
        uint256 amountOfTokens;
    }


    function calculateSpendingsOnBuy(address senderAccount, uint256 amountOfEthereum) public isRegistered(senderAccount) view returns(BuySpendings memory) {
        BuySpendings memory spendings = BuySpendings({
            companyFee: calculateCompanyFee(amountOfEthereum),
            directBonus: calculateDirectBonus(amountOfEthereum),
            indirectBonus: 0,
            founderBonus: calculateFounderBonus(amountOfEthereum),
            distributedBonus: calculateDistributedAmount(amountOfEthereum),
            ethereumLeft: amountOfEthereum,
            amountOfTokens: 0
        });

        spendings.ethereumLeft = spendings.ethereumLeft.sub(spendings.companyFee);

        if (getFoundersCount() > 0) {
            spendings.ethereumLeft = spendings.ethereumLeft.sub(spendings.founderBonus);
        } else {
            spendings.founderBonus = 0;
        }

        address account = senderAccount;
        address sponsor = sponsorOf(account);

        if (isEligibleForDirectBonus(sponsor)) {
            spendings.ethereumLeft = spendings.ethereumLeft.sub(spendings.directBonus);
        } else {
            spendings.directBonus = 0;
        }

        uint256 maxRankUnder = rankOf(account);
        while (account != address(this)) {
            uint256 curRank = rankOf(account);
            if (curRank > maxRankUnder && account != senderAccount) {
                uint256 indirectBonus = calculateIndirectBonus(amountOfEthereum, curRank, maxRankUnder);
                spendings.ethereumLeft = spendings.ethereumLeft.sub(indirectBonus);
                spendings.indirectBonus = spendings.indirectBonus.add(indirectBonus);
                maxRankUnder = curRank;
            }
            account = sponsorOf(account);
        }

        spendings.ethereumLeft = spendings.ethereumLeft.sub(spendings.distributedBonus);

        spendings.amountOfTokens = ethereumToTokens(spendings.ethereumLeft);

        return spendings;
    }

    function calculateReturnedAmountOnSell(address senderAccount, uint256 amountOfTokens) public isRegistered(senderAccount) view returns(uint256) {
        uint256 ethereum = tokensToEthereum(amountOfTokens);
        uint256 distributedBonus = calculateDistributedAmount(ethereum);
        return SafeMath.sub(ethereum, distributedBonus);
    }


    function purchaseTokens(address senderAccount, uint256 amountOfEthereum) internal canInvest(amountOfEthereum) returns(uint256, uint256) {
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

        //uint256 indirectBonus = payIndirectBonusStartingFrom(senderAccount, amountOfEthereum);
        //updateTurnoversAndRanksStartingFrom(senderAccount, amountOfEthereum);
        //taxedEthereum = taxedEthereum.sub(indirectBonus);


        taxedEthereum = taxedEthereum.sub(distributedBonus);

        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);

        processDistributionOnBuy(senderAccount, amountOfTokens, distributedBonus);
        increaseBalanceOf(senderAccount, amountOfTokens);

        return (taxedEthereum, amountOfTokens);
    }
}
