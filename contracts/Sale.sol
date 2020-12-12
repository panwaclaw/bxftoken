// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "./AccountStorage.sol";


contract Sale is AccountStorage {

    uint private _saleStartBlockNumber = 0;
    bytes32 public constant SALE_MANAGER_ROLE = keccak256("SALE_MANAGER_ROLE");

    event SaleStarted(uint atBlockNumber, uint atTimestamp);

    modifier canInvest(uint256 amount) {
        require(selfBuyOf(msg.sender) + amount <= getInvestmentCap(), "Sale: you can't invest more than current investment cap");
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
}
