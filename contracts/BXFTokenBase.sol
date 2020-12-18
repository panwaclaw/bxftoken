// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Company.sol";
import "./Distributable.sol";
import "./Founder.sol";
import "./Sale.sol";


abstract contract BXFTokenBase is Distributable, Founder, Company, Sale {
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


    function calculateSpendingsOnBuy(address senderAccount, uint256 amountOfEthereum) public view returns(BuySpendings memory) {
        BuySpendings memory spendings = SpendingsInfo({
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
}
