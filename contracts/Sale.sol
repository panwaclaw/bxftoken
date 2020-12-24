// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "./Founder.sol";


abstract contract Sale is Founder {
    using SafeMath for uint256;

    uint private _saleStartBlockNumber = 0;
    bytes32 public constant SALE_MANAGER_ROLE = keccak256("SALE_MANAGER_ROLE");

    event SaleStarted(uint atBlockNumber, uint atTimestamp);

    modifier canInvest(uint256 amount) {
        require(selfBuyOf(msg.sender) + amount <= getInvestmentCap() + founderBonusCapFor(msg.sender), "Sale: you can't invest more than current investment cap");
        _;
    }


    function getInvestmentCap() public view returns(uint256) {
        if (_saleStartBlockNumber == 0)
            return 0 ether;
        uint256 currentBlockNumberFromSaleStart = block.number - _saleStartBlockNumber;
        if (currentBlockNumberFromSaleStart <= 1250000)
            return 31680000 * (currentBlockNumberFromSaleStart**2) + 1 ether;
        if (currentBlockNumberFromSaleStart <= 2500000)
            return 100 ether - 31680000 * (currentBlockNumberFromSaleStart - 2500000)**2;
        return 100 ether;
    }


    function startSale() public {
        require(hasRole(SALE_MANAGER_ROLE, msg.sender), "Sale: must have sale manager role");
        require(_saleStartBlockNumber == 0, "Sale: start sale method is no more available");

        _saleStartBlockNumber = block.number;

        emit SaleStarted(block.number, block.timestamp);
    }

    function moveSaleForwardBy(uint256 blocks) public {
        require(hasRole(SALE_MANAGER_ROLE, msg.sender), "Sale: must have sale manager role");
        require(_saleStartBlockNumber > 0, "Sale: sale forward move method is not available yet, start sale first");

        _saleStartBlockNumber = _saleStartBlockNumber.sub(blocks);
    }
}
