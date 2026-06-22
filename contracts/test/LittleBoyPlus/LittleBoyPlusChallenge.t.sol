// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {
    LittleBoyPlusConstants as C
} from "../../src/LittleBoyPlus/Constants.sol";
import {AttackLittleBoyPlus} from "./AttackLittleBoyPlus.sol";

contract LittleBoyPlusChallenge is Test {
    function setUp() public {
        uint256 forkId = vm.createFork(
            vm.envString("BSC_RPC_URL"),
            C.FORK_BLOCK
        );
        vm.selectFork(forkId);
    }

    function testAttack() public {
        uint256 playerBnbBefore = C.PLAYER.balance;

        AttackLittleBoyPlus attack = new AttackLittleBoyPlus();
        vm.prank(C.PLAYER);
        attack.attack();

        uint256 profitUsdt = attack.lastProfitUsdt();
        uint256 profitBnb = C.PLAYER.balance - playerBnbBefore;

        emit log_named_uint("net profit USDT (18d)", profitUsdt);
        emit log_named_uint("net profit BNB (18d)", profitBnb);

        assertGt(profitUsdt, 0);
        assertGt(profitBnb, 0);
        assertApproxEqAbs(profitUsdt, C.EXPECTED_USDT_PROFIT, 5_000e18);
        assertApproxEqAbs(profitBnb, C.EXPECTED_WBNB_PROFIT, 5e18);
    }
}

// forge test --match-contract LittleBoyPlusChallenge -vv
