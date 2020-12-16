// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./MultiLevelTree.sol";


abstract contract CryptoReward is MultiLevelTree {
    bytes32 public constant CRYPTOREWARD_MANAGER_ROLE = keccak256("CRYPTOREWARD_MANAGER_ROLE");

    event PaidCryptoReward(address indexed account, uint256 ethereumPaid);

    function payCryptoReward(address account) public payable {
        require(hasRole(CRYPTOREWARD_MANAGER_ROLE, msg.sender), "CryptoReward: must have CryptoReward manager role");
        addCryptoRewardBonusTo(account, msg.value);

        emit PaidCryptoReward(account, msg.value);
    }
}
