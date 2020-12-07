// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;


contract AccessControlRoles {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
}
