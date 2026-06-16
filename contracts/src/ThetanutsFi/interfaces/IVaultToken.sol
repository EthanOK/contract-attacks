// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVaultToken {
    function initWithdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}
