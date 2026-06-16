// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IIndexToken {
    function mint(uint256 amount) external;
    function claim(uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}
