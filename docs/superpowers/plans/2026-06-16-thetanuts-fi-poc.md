# Thetanuts Finance Fork PoC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fork mainnet at block `25323328` and reproduce the Thetanuts Finance legacy vault exploit with chain-aligned USDC profit.

**Architecture:** Single `AttackThetanutsFi` contract under prank of attacker EOA; Aave-style `flashLoan` on `LENDING_ROUTER`; `claim` + algorithmic `mint` on `INDEX_TOKEN` (`TN-IDX-USDC-PUT`); `initWithdraw` on BTC/ETH vaults.

**Tech Stack:** Foundry, OpenZeppelin IERC20/SafeERC20, Ethereum mainnet fork via `ETH_RPC_URL`

**Design spec:** [docs/superpowers/specs/2026-06-16-thetanuts-fi-poc-design.md](../specs/2026-06-16-thetanuts-fi-poc-design.md)

---

## Key on-chain discoveries

- `INDEX_TOKEN` (`0xC2C3AE...`) = TN-IDX-USDC-PUT ERC20; `mint` / `claim` target
- `INDEX_ACCOUNT` (`0x075d...`) = indexUSDC; holds all INDEX_TOKEN supply at fork block
- `borrowAmount = totalSupply() - 3` → `153_054_600_569`
- Vault token addresses extracted from attacker bytecode (AVAX ends in `...AB8`)

## Tasks

- [x] Create interfaces + `Constants.sol`
- [x] Implement `AttackThetanutsFi.sol`
- [x] Implement `ThetanutsFiChallenge.t.sol` with prank PLAYER
- [x] Run `forge test --match-contract ThetanutsFiChallenge -vvv`
- [x] Update README PoC path

## Verification

```shell
forge test --match-contract ThetanutsFiChallenge -vvv
```

Expected: `testAttack` passes; PLAYER USDC = `105_471_499_078`.
