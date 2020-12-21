// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BXFTokenBase.sol";


contract BXFToken is BXFTokenBase {

    using SafeMath for uint256;
    
    event Buy(address indexed account, uint256 incomingEthereum, uint256 tokensMinted);
    event Sell(address indexed account, uint256 tokensBurned, uint256 ethereumEarned);
    event Reinvestment(address indexed account, uint256 ethereumReinvested, uint256 tokensMinted);
    event Withdraw(address indexed account, uint256 ethereumWithdrawn);
    event Transfer(address indexed from, address indexed to, uint256 value);


    constructor(string memory name, string memory symbol) StandardToken(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    fallback() external payable {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BXFToken: you're not allowed to do this");
    }


    function buy() public payable isRegistered(msg.sender) {
        (uint256 taxedEthereum, uint256 amountOfTokens) = purchaseTokens(msg.sender, msg.value);
        emit Buy(msg.sender, taxedEthereum, amountOfTokens);
    }


    function sell(uint256 amountOfTokens) public isRegistered(msg.sender) hasEnoughBalance(amountOfTokens) {
        address account = msg.sender;

        decreaseTotalSupply(amountOfTokens);
        decreaseBalanceOf(account, amountOfTokens);

        if (isFounder(account)) dropFounder(account);

        uint256 taxedEthereum = processDistributionOnSell(account, amountOfTokens);

        msg.sender.transfer(taxedEthereum);

        emit Sell(account, amountOfTokens, taxedEthereum);
    }


    function withdraw(uint256 amountToWithdraw) public isRegistered(msg.sender) hasEnoughAvailableEther(amountToWithdraw) {
        require(amountToWithdraw <= address(this).balance, "BXFToken: insufficient contract balance");

        address account = msg.sender;
        addWithdrawnAmountTo(account, amountToWithdraw);
        msg.sender.transfer(amountToWithdraw);

        emit Withdraw(account, amountToWithdraw);
    }


    function reinvest(uint256 amountToReinvest) public isRegistered(msg.sender) hasEnoughAvailableEther(amountToReinvest) {
        address account = msg.sender;

        addReinvestedAmountTo(account, amountToReinvest);
        (uint256 taxedEthereum, uint256 amountOfTokens) = purchaseTokens(account, amountToReinvest);

        emit Reinvestment(account, amountToReinvest, amountOfTokens);
    }


    function exit() public isRegistered(msg.sender) {
        address account = msg.sender;
        if (balanceOf(account) > 0) {
            sell(balanceOf(account));
        }
        withdraw(totalBonusOf(account));
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
