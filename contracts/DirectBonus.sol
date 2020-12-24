// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AccountStorage.sol";


abstract contract DirectBonus is AccountStorage {

    using SafeMath for uint256;

    uint256 constant private DIRECT_FEE = 10;
    uint256 private minimumSelfBuyForDirectBonus = 0.05 ether;

    event MinimumSelfBuyForDirectBonusUpdate(uint256 amount);


    function getMinimumSelfBuyForDirectBonus() public view returns(uint256) {
        return minimumSelfBuyForDirectBonus;
    }


    function setMinimumSelfBuyForDirectBonus(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MultiLevelTree: must have company manager role to set minimum self buy for direct bonus");
        minimumSelfBuyForDirectBonus = amount;

        emit MinimumSelfBuyForDirectBonusUpdate(amount);
    }


    function calculateDirectBonus(uint256 amount) internal pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, DIRECT_FEE), 100);
    }


    function isEligibleForDirectBonus(address sponsor) internal view returns(bool) {
        return (sponsor != address(this) && selfBuyOf(sponsor) >= minimumSelfBuyForDirectBonus);
    }
}
