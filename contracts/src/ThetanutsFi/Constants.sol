// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ThetanutsConstants {
  uint256 internal constant FORK_BLOCK = 25_323_328;
  address internal constant PLAYER = 0x30498e4466789E534c72e03B52A16c978655b41e;

  /// @dev indexUSDC — accounting contract; holds all TN-IDX-USDC-PUT supply at fork block
  address internal constant INDEX_ACCOUNT = 0x075dA7e9EFEA6813aB0B2680423df75150120d12;
  /// @dev TN-IDX-USDC-PUT ERC20; mint / claim / flash-loan asset
  address internal constant INDEX_TOKEN = 0xC2C3AE0a7b405058558C9b4a63b373486CB86Ac7;
  address internal constant LENDING_ROUTER = 0x2Ca7641B841a79Cc70220cE838d0b9f8197accDA;
  address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  address internal constant VAULT_BTCUSD = 0x3BA337F3167eA35910E6979D5BC3b0AeE60E7d59;
  address internal constant VAULT_ETHUSD = 0xE1c93dE547cc85CBD568295f6CC322B1dbBCf8Ae;
  address internal constant VAULT_AVAXUSD = 0x248038fDb6F00f4B636812CA6A7F06b81a195AB8;
  address internal constant VAULT_BNBUSD = 0xE5e8caA04C4b9E1C9bd944A2a78a48b05c3ef3AF;
  address internal constant VAULT_MATICUSD = 0xAD57221ae9897DA08656aaaBd5B1D4673d4eDE71;

  /// @dev 链上攻击使用 claim 后 remaining = 3
  uint256 internal constant TARGET_REMAINING_SUPPLY = 3;
  uint256 internal constant INDEX_TOTAL_SUPPLY_AT_FORK = 153_054_600_572;
  uint256 internal constant EXPECTED_BORROW_AMOUNT = 153_054_600_569;
  uint256 internal constant EXPECTED_USDC_PROFIT = 105_471_499_078;

  uint256 internal constant MAX_MINT_ITERATIONS = 256;
}
