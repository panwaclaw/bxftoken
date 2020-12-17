// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MultiLevelTree.sol";
import "./StandardToken.sol";


abstract contract Distributable is MultiLevelTree {
    using SafeMath for uint256;

    uint256 private _profitPerShare;

    uint256 constant private INITIAL_TOKEN_PRICE = 0.0000001 ether;
    uint256 constant private INCREMENT_TOKEN_PRICE = 0.00000001 ether;
    uint256 constant private MAGNITUDE = 2 ** 64;
    uint256 constant private DISTRIBUTION_FEE = 7;


    function buyPrice() public view returns(uint256)
    {
        if (totalSupply() == 0){
            return INITIAL_TOKEN_PRICE + INCREMENT_TOKEN_PRICE;
        } else {
            uint256 ethereum = tokensToEthereum(1 ether);
            uint256 distributedAmount = calculateDistributedAmount(ethereum);
            uint256 taxedEthereum = SafeMath.add(ethereum, distributedAmount);
            return taxedEthereum;
        }
    }


    function sellPrice() public view returns(uint256) {
        if (totalSupply() == 0) {
            return INITIAL_TOKEN_PRICE - INCREMENT_TOKEN_PRICE;
        } else {
            uint256 ethereum = tokensToEthereum(1 ether);
            uint256 distributedAmount = calculateDistributedAmount(ethereum);
            uint256 taxedEthereum = SafeMath.sub(ethereum, distributedAmount);
            return taxedEthereum;
        }
    }


    function distributionBonusOf(address account) public override view returns(uint256) {
        return (uint256) ((int256)(_profitPerShare * balanceOf(account)) - getDistributionBonusValueOf(account)) / MAGNITUDE;
    }


    function totalBonusOf(address account) public override view returns(uint256) {
        return directBonusOf(account) + indirectBonusOf(account) + founderBonusOf(account) + cryptoRewardBonusOf(account)
        + distributionBonusOf(account) - withdrawnAmountOf(account) - reinvestedAmountOf(account);
    }


    function calculateDistributedAmount(uint256 amount) internal pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, DISTRIBUTION_FEE), 100);
    }


    function increaseProfitPerShare(uint256 distributedBonus) internal {
        _profitPerShare += (distributedBonus * MAGNITUDE / totalSupply());
    }


    function processDistributionOnBuy(address account, uint256 amountOfTokens, uint256 distributedBonus) internal {
        uint256 distributionFee = distributedBonus * MAGNITUDE;

        if (totalSupply() > 0) {
            increaseTotalSupply(amountOfTokens);
            increaseProfitPerShare(distributedBonus);
            distributionFee = amountOfTokens * (distributedBonus * MAGNITUDE / totalSupply());
        } else {
            setTotalSupply(amountOfTokens);
        }

        int256 distributionPayout = (int256) (_profitPerShare * amountOfTokens - distributionFee);
        increaseDistributionBonusValueFor(account, distributionPayout);
    }


    function processDistributionOnSell(address account, uint256 amountOfTokens) internal returns(uint256) {
        uint256 ethereum = tokensToEthereum(amountOfTokens);
        uint256 distributedBonus = calculateDistributedAmount(ethereum);
        uint256 taxedEthereum = SafeMath.sub(ethereum, distributedBonus);

        int256 distributedBonusUpdate = (int256) (_profitPerShare * amountOfTokens);
        decreaseDistributionBonusValueFor(account, distributedBonusUpdate);

        if (totalSupply() > 0) {
            increaseProfitPerShare(distributedBonus);
        }
        return taxedEthereum;
    }


    function processDistributionOnTransfer(address sender, uint256 amountOfTokens, address recipient, uint256 taxedTokens) internal {
        uint256 distributedBonus = tokensToEthereum(SafeMath.sub(amountOfTokens, taxedTokens));

        decreaseDistributionBonusValueFor(sender, (int256) (_profitPerShare * amountOfTokens));
        increaseDistributionBonusValueFor(recipient, (int256) (_profitPerShare * taxedTokens));

        increaseProfitPerShare(distributedBonus);
    }


    function ethereumToTokens(uint256 _ethereum) internal view returns(uint256) {
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
            (((INCREMENT_TOKEN_PRICE)**2)*(totalSupply()**2))
            +
            (2*(INCREMENT_TOKEN_PRICE)*_tokenPriceInitial*totalSupply())
        )
            ), _tokenPriceInitial
        )
        )/(INCREMENT_TOKEN_PRICE)
        )-(totalSupply())
        ;

        return _tokensReceived;
    }


    function tokensToEthereum(uint256 _tokens) internal view returns(uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (totalSupply() + 1e18);
        uint256 _etherReceived =
        (
        // underflow attempts BTFO
        SafeMath.add(
            (
            (
            (
            INITIAL_TOKEN_PRICE + (INCREMENT_TOKEN_PRICE * (_tokenSupply / 1e18))
            ) - INCREMENT_TOKEN_PRICE
            ) * (tokens_ - 1e18)
            ), (INCREMENT_TOKEN_PRICE * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
        )
        /1e18);
        return _etherReceived;
    }


    function sqrt(uint x) internal pure returns(uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
