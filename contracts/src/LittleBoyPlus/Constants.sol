// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LittleBoyPlusConstants {
    uint256 internal constant FORK_BLOCK = 104_727_183;

    address internal constant PLAYER =
        0xb26DFE6b6180A30e2A2D9826867cc7e06631825a;

    address internal constant LBP = 0x88886f0fD371dfF856291bAdcEd45922bC888888;
    address internal constant HASHRATE =
        0x5E3cBc82D020be91a989Eb747934104E9AB585Fe;
    address internal constant VICTIM_PAIR =
        0x00e3Ea08fD8CBaD955Ec5d2292Ad637670c31524;
    address internal constant POL_VAULT =
        0x01c87119a0D1C3730534b8d909eFeB1911b9fdB0;
    address internal constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant ROUTER =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant PCS_INFINITY_VAULT =
        0x238a358808379702088667322f80aC48bAd5e6c4;

    address internal constant USDT_WBNB_PAIR =
        0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 internal constant SWAP_USDT_LARGE = 15_000_000e18;
    /// @dev log#58 攻击合约 → 受害 Pair（链上精确值）
    uint256 internal constant POL_INJECT_USDT =
        5_790_511_652_692_109_497_206_178;
    /// @dev transferFrom 后打回 Pair 的 LBP（链上 log#98、#137）
    uint256 internal constant PRE_DRAIN_LBP_1 = 33_234_936_188_192_519_257_374;
    uint256 internal constant PRE_DRAIN_LBP_2 = 26_587_948_950_554_015_405_900;

    uint256 internal constant VAULT_FLASH_USDT = 34_088_143_961844099311594944;

    uint256 internal constant EXPECTED_USDT_PROFIT = 369_624_459075908792798266;
    uint256 internal constant EXPECTED_WBNB_PROFIT = 597_869695323918835296;
}
