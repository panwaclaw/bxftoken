// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessControlRoles.sol";
import "./MultiLevelTreeAccountStorage.sol";


contract CryptoReward is MultiLevelTreeAccountStorage, AccessControlRoles {
    event PaidCryptoReward(address indexed account, uint256 ethereumPaid);

    function payCryptoReward(address account) public payable {
        require(hasRole(MANAGER_ROLE, msg.sender), "BXFToken: must have manager role");
        addCryptoRewardBonusTo(account, msg.value);

        emit PaidCryptoReward(account, msg.value);
    }
}
