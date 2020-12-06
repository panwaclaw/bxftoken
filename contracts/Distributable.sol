// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MultiLevelTreeAccountStorage.sol";
import "./StandardToken.sol";


abstract contract Distributable is MultiLevelTreeAccountStorage, StandardToken {
    using SafeMath for uint256;

    uint256 private _profitPerShare;

    uint256 constant private INITIAL_TOKEN_PRICE = 0.0000001 ether;
    uint256 constant private INCREMENT_TOKEN_PRICE = 0.00000001 ether;
    uint256 constant internal MAGNITUDE = 2 ** 64;
    uint256 constant private DISTRIBUTION_FEE = 7;


    function buyPrice() public view returns(uint256)
    {
        if (totalSupply() == 0){
            return INITIAL_TOKEN_PRICE + INCREMENT_TOKEN_PRICE;
        } else {
            uint256 ethereum = tokensToEthereum(10 ** 18);
            uint256 distributedAmount = calculateDistributedAmount(ethereum);
            uint256 taxedEthereum = SafeMath.add(ethereum, distributedAmount);
            return taxedEthereum;
        }
    }


    function sellPrice() public view returns(uint256) {
        if (totalSupply() == 0) {
            return INITIAL_TOKEN_PRICE - INCREMENT_TOKEN_PRICE;
        } else {
            uint256 ethereum = tokensToEthereum(10 ** 18);
            uint256 totalFees = DISTRIBUTION_FEE;
            uint256 taxedAmount = SafeMath.div(SafeMath.mul(ethereum, totalFees), 100);
            uint256 taxedEthereum = SafeMath.sub(ethereum, taxedAmount);
            return taxedEthereum;
        }
    }


    function distributionBonusOf(address account) public view returns(uint256) {
        return (uint256) ((int256)(_profitPerShare * balanceOf(account)) - getDistributionBonusValueOf(account)) / MAGNITUDE;
    }


    function totalBonusOf(address account) public view returns(uint256) {
        return directBonusOf(account) + indirectBonusOf(account) + founderBonusOf(account) + cryptoRewardBonusOf(account)
        + distributionBonusOf(account) - withdrawnAmountOf(account) - reinvestedAmountOf(account);
    }


    function calculateDistributedAmount(uint256 amount) internal pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, DISTRIBUTION_FEE), 100);
    }


    function getProfitPerShare() internal view returns(uint256) {
        return _profitPerShare;
    }


    function increaseProfitPerShare(uint256 distributedBonus) internal {
        _profitPerShare += (distributedBonus * MAGNITUDE / totalSupply());
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
        SafeMath.sub(
            (
            (
            (INITIAL_TOKEN_PRICE + (INCREMENT_TOKEN_PRICE * (_tokenSupply / 1e18))) - INCREMENT_TOKEN_PRICE) * (tokens_ - 1e18)
            ), (INCREMENT_TOKEN_PRICE* ((tokens_ ** 2 - tokens_) / 1e18)) / 2
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
