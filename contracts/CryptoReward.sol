// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessControlRoles.sol";
import "./MultiLevelTree.sol";


contract CryptoReward is MultiLevelTree, AccessControlRoles {
    event PaidCryptoReward(address indexed account, uint256 ethereumPaid);

    function payCryptoReward(address account) public payable {
        require(hasRole(MANAGER_ROLE, msg.sender), "BXFToken: must have manager role");
        addCryptoRewardBonusTo(account, msg.value);

        emit PaidCryptoReward(account, msg.value);
    }
}
