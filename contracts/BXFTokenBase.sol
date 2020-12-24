// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Company.sol";
import "./Staking.sol";
import "./Founder.sol";
import "./Sale.sol";


abstract contract BXFTokenBase is Staking, Company, Sale, DirectBonus {
    using SafeMath for uint256;


    function calculateEtherOnSell(address senderAccount, uint256 amountOfTokens) public isRegistered(senderAccount) view returns(uint256) {
        uint256 ethereum = tokensToEthereum(amountOfTokens);
        uint256 stakingFee = calculateStakingFee(ethereum);
        return SafeMath.sub(ethereum, stakingFee);
    }


    function purchaseTokens(address senderAccount, uint256 amountOfEthereum) internal canInvest(amountOfEthereum) returns(uint256, uint256) {
        uint256 taxedEthereum = amountOfEthereum;

        uint256 companyFee = calculateCompanyFee(amountOfEthereum);
        uint256 directBonus = calculateDirectBonus(amountOfEthereum);
        uint256 stakingFee = calculateStakingFee(amountOfEthereum);

        taxedEthereum = taxedEthereum.sub(companyFee);
        increaseCompanyBalance(companyFee);

        address account = senderAccount;
        address sponsor = sponsorOf(account);
        increaseSelfBuyOf(account, amountOfEthereum);

        if (isEligibleForDirectBonus(sponsor)) {
            addDirectBonusTo(sponsor, directBonus);
            taxedEthereum = taxedEthereum.sub(directBonus);
        }

        taxedEthereum = taxedEthereum.sub(stakingFee);

        uint256 amountOfTokens = ethereumToTokens(taxedEthereum);

        processStakingOnBuy(senderAccount, amountOfTokens, stakingFee);
        increaseBalanceOf(senderAccount, amountOfTokens);

        return (taxedEthereum, amountOfTokens);
    }
}
