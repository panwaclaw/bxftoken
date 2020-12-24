// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AccountStorage.sol";
import "./Price.sol";


abstract contract Staking is AccountStorage, Price {
    using SafeMath for uint256;

    uint256 private _stakingProfitPerShare;

    uint256 constant private MAGNITUDE = 2 ** 64;
    uint256 constant private STAKING_FEE = 8;


    function stakingBonusOf(address account) public override view returns(uint256) {
        return (uint256) ((int256)(_stakingProfitPerShare * balanceOf(account)) - stakingValueOf(account)) / MAGNITUDE;
    }


    function calculateStakingFee(uint256 amount) internal pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, STAKING_FEE), 100);
    }


    function increaseStakingProfitPerShare(uint256 stakingBonus) internal {
        _stakingProfitPerShare += (stakingBonus * MAGNITUDE / totalSupply());
    }


    function processStakingOnBuy(address account, uint256 amountOfTokens, uint256 stakingBonus) internal {
        uint256 stakingFee = stakingBonus * MAGNITUDE;

        if (totalSupply() > 0) {
            increaseTotalSupply(amountOfTokens);
            increaseStakingProfitPerShare(stakingBonus);
            stakingFee = amountOfTokens * (stakingBonus * MAGNITUDE / totalSupply());
        } else {
            setTotalSupply(amountOfTokens);
        }

        int256 stakingPayout = (int256) (_stakingProfitPerShare * amountOfTokens - stakingFee);
        increaseStakingValueFor(account, stakingPayout);
    }


    function processStakingOnSell(address account, uint256 amountOfTokens) internal returns(uint256) {
        uint256 ethereum = tokensToEthereum(amountOfTokens);
        uint256 stakingFee = calculateStakingFee(ethereum);
        uint256 taxedEthereum = SafeMath.sub(ethereum, stakingFee);

        int256 stakingValueUpdate = (int256) (_stakingProfitPerShare * amountOfTokens);
        decreaseStakingValueFor(account, stakingValueUpdate);

        if (totalSupply() > 0) {
            increaseStakingProfitPerShare(stakingFee);
        }
        return taxedEthereum;
    }


    function processDistributionOnTransfer(address sender, uint256 amountOfTokens, address recipient, uint256 taxedTokens) internal {
        uint256 stakedBonus = tokensToEthereum(SafeMath.sub(amountOfTokens, taxedTokens));

        decreaseStakingValueFor(sender, (int256) (_stakingProfitPerShare * amountOfTokens));
        increaseStakingValueFor(recipient, (int256) (_stakingProfitPerShare * taxedTokens));

        increaseStakingProfitPerShare(stakedBonus);
    }

}
