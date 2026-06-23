# 发布元信息（粘贴到 https://learnblockchain.cn/article/create 表单）

**标题：** Thetanuts Finance 遗留金库攻击复盘：low-supply 整数舍入与闪电贷套现

**专栏 / 专题：** 链上安全深潜

**分类：** 安全

**标签：** Thetanuts Finance, DeFi, 智能合约安全, 整数除法, 闪电贷, Fork PoC, Ethereum

**摘要（≤250 字，填在编辑器摘要框）：**

2026-06-15，Thetanuts Finance 遗留 Index Vault（TN-IDX-USDC-PUT）遭单笔攻击（约 $2.1M）。totalSupply 极低时 mint/claim 整数除法舍入，攻击者闪电贷内 claim 拆底层份额、循环零成本 mint 还贷，再 initWithdraw 提 USDC。本文梳理 Phalcon 调用链、利润与白帽救援，附 Ethereum fork PoC。

**封面：** 上传 `assets/column-cover-lian-shang-anquan-shenqian-1920x1080.png`（或专题统一封面）

**原文链接（可选）：** GitHub `attack-event/ThetanutsFinance.md`

---

# 正文（从下一行起复制到 Markdown 编辑器）

> **链上安全深潜** · 主网攻击 · 根因 · Fork 复现  
> PoC：https://github.com/EthanOK/contract-attacks/tree/master/contracts/test/ThetanutsFi

---

## 交易概览

| 项目 | 内容 |
|------|------|
| 交易 | `0xbba9f138fe39503bfd1aa62932dbd6ab35d37d23d48e4b7bf2988a9d5dc39fec` |
| 链 | Ethereum Mainnet |
| 区块 | `25323329`（Position #0） |
| 时间 | 2026-06-15 13:53:59 UTC |
| Etherscan | https://etherscan.io/tx/0xbba9f138fe39503bfd1aa62932dbd6ab35d37d23d48e4b7bf2988a9d5dc39fec |
| Phalcon | https://app.blocksec.com/phalcon/explorer/tx/eth/0xbba9f138fe39503bfd1aa62932dbd6ab35d37d23d48e4b7bf2988a9d5dc39fec |

2026 年 6 月 15 日，攻击者针对 **Thetanuts Finance 已废弃的遗留 Index Vault 系统** 发起单笔原子交易。攻击利用遗留合约在 **低供应量（low-supply）边界条件下整数除法舍入错误**，通过闪电贷借入 Index Token、一次性 `claim` 拆包底层 Vault 份额、循环 `mint` 零成本铸份额还贷，再对底层 Vault Token 执行 `initWithdraw` 提取 USDC。

| 指标 | 数值 |
|------|------|
| 估计总损失 | ~$2.1M（PeckShield / SlowMist） |
| 白帽追回 | ~$2M 期权代币 |
| 攻击者本 tx 留存 | ~105,471 USDC + 部分 Vault Token |
| Gas | 3,717,258 / 5,000,000 |

Thetanuts 官方确认：被攻击合约为 **多年前已迁移的 deprecated vault**，与当前产品线无关。

---

## 协议架构（三层）

```
Layer 1: Index Token（TN-IDX-USDC-PUT）
         = 一篮子底层 Put Vault 份额的打包凭证
              │ claim（拆包，仅一次）
              ▼
Layer 2: 底层 Vault Token（TN-CSCPv1-BTCUSD / ETHUSD / …）
         = 单个期权金库的份额凭证
              │ initWithdraw
              ▼
Layer 3: Backing（USDC / WBTC / WETH 等）
```

**关键地址：**

| 角色 | 地址 |
|------|------|
| Index Token | `0x075dA7e9EFEA6813aB0B2680423df75150120d12` |
| 攻击编排合约 | `0xa589c5342068b0c1fefd44d3c95354427502ac91` |
| Index 执行合约 | `0x0F9DAa9E0aDCeD4E64578B2e131930DDE54E492E` |
| 资金 helper | `0xAf3a0FdBfb0e3127247b66a042310e09c32f2299` |

---

## 漏洞根因

遗留 Index Token 的 `mint` / `claim` 使用类似会计逻辑：

```solidity
depositAmount = backing * mintAmount / totalSupply;
payout        = backing * shares / totalSupply;
```

Solidity **整数除法向下取整**。当 `totalSupply` 被压到极低，或满足 `backing × amount < totalSupply` 时：

```
depositAmount = 0  →  免费铸币
```

攻击者通过一次性 `claim` 将金库推入 **低供应量畸形状态**，使后续 `mint` 在循环中持续满足零成本铸币条件。遗留合约虽已迁移，链上仍可调用，且无有效边界检查。

---

## 攻击流程

```
① 部署攻击合约（CREATE × 2）
② 闪电贷借 TN-IDX-USDC-PUT（≈153,054 份 + fee）
③ claim 一次 → 拆包 5 种 CSCPv1 + 烧掉借来的 Index + totalSupply 畸形
④ 循环 mint（2→4→8→…）→ 应付 depositAmount = 0
⑤ 用 mint 出的 Index 还闪电贷
⑥ initWithdraw（BTC/ETH vault）→ 提取 USDC
⑦ 其余 AVAX/BNB/MATIC Vault Token 转 helper
```

### claim（仅一次）

```
TN-IDX-USDC-PUT.claim(tokenId=153,054,600,569)
  → 烧掉闪电贷借来的 Index
  → 转出 5 种 TN-CSCPv1-* 至执行合约
```

| 底层 Vault Token | claim 获得（6 dec） |
|------------------|---------------------|
| TN-CSCPv1-BTCUSD | 49,716.431047 |
| TN-CSCPv1-ETHUSD | 23,955.277333 |
| TN-CSCPv1-AVAXUSD | 6,378.688541 |
| TN-CSCPv1-BNBUSD | 17,186.382409 |
| TN-CSCPv1-MATICUSD | 10,028.704387 |

### initWithdraw 与未变现头寸

| Vault Token | 处理 | 结果 |
|-------------|------|------|
| BTCUSD | `initWithdraw` | **70,315.56 USDC** |
| ETHUSD | `initWithdraw` | **35,155.94 USDC** |
| AVAX/BNB/MATIC | `transfer` → helper | 保留 Vault Token |

本 tx 可见 USDC 合计：**105,471.499078**。

### 循环 mint 的目的

`claim` 之后指数递增 `mint(2)→mint(4)→…`，链上可见大量 `Null → Exploiter : 0.000002, 0.000004, …` 且 **应付为 0**。此阶段主要 **凑够 Index 还闪电贷**，不是主要利润来源；利润来自 claim 拆包 + initWithdraw。

---

## Phalcon 要点

**闪电贷回调内阶段：**

1. claim + 循环 mint + 还贷（Phalcon 常折叠）
2. `initWithdraw(BTCUSD)` → USDC balance 70,315,563,951
3. `initWithdraw(ETHUSD)` → USDC balance 105,471,499,078
4. `USDC.transfer(helper, 105,471,499,078)`
5. 转出 AVAX/BNB/MATIC Vault Token 至 helper

**余额变动（节选）：**

| 地址 | Token | 变动 |
|------|-------|------|
| BTCUSD vault | USDC | -70,315.56 |
| ETHUSD vault | USDC | -35,155.94 |
| helper | USDC | +105,471.50 |
| helper | AVAX/BNB/MATIC Vault | +33,593.78 合计 |

---

## 利润构成

| 来源 | 性质 |
|------|------|
| claim 拆包 5 种 CSCPv1 | 获利路径 ①（无偿拆包） |
| initWithdraw → USDC | 获利路径 ②（本 tx ~105k USDC） |
| 未变现 Vault Token 转出 | 获利路径 ③ |
| 循环 mint | **仅还贷**，非主利润 |

PeckShield 统计整次事件总损失约 **$2.1M**（含关联头寸），约 **$2M** 被白帽抢回。

---

## 白帽救援（+300 区块）

**Tx：** `0x4c0a75e27855f350c95e3dc64906b1b2f19e6649fdfd0d9374f3915067418bc1`  
[Phalcon](https://app.blocksec.com/phalcon/explorer/tx/eth/0x4c0a75e27855f350c95e3dc64906b1b2f19e6649fdfd0d9374f3915067418bc1)

白帽 **并非** 从攻击者 helper 扣回已盗 USDC，而是用 **相同技术路径**（闪电贷 → claim → mint → 还贷）批量提取 **多个遗留 Index** 的剩余暴露头寸，救回约 **$2M** 期权代币至白帽地址。攻击者本 tx 已落袋的 ~105k USDC 不在救援范围内。

---

## Fork PoC 复现

本仓库在 Ethereum archive fork（block `25323329`）复现攻击逻辑：

```bash
# .env 配置 ETH_RPC_URL（archive 节点）
forge test --match-contract ThetanutsFiChallenge -vv
```

- 合约：`contracts/test/ThetanutsFi/AttackThetanutsFi.sol`
- 测试：`contracts/test/ThetanutsFi/ThetanutsFiChallenge.t.sol`

---

## 修复建议

1. `totalSupply` 低于阈值时 `revert mint`
2. `depositAmount == 0` 时 `revert`（禁止零成本铸币）
3. 废弃合约应链上 `pause` 或迁移剩余资产，而非仅前端下线
4. `mint` / `claim` / `initWithdraw` 使用统一会计状态源

**漏洞类型：** Business Logic Flaw / Integer Division Rounding at Low Supply

---

## 参考资料

- [Etherscan 攻击交易](https://etherscan.io/tx/0xbba9f138fe39503bfd1aa62932dbd6ab35d37d23d48e4b7bf2988a9d5dc39fec)
- [BlockSec Phalcon](https://app.blocksec.com/phalcon/explorer/tx/eth/0xbba9f138fe39503bfd1aa62932dbd6ab35d37d23d48e4b7bf2988a9d5dc39fec)
- PeckShield / Blockaid / SlowMist 公开告警
- Thetanuts 官方：deprecated vault，与当前产品无关

---

> **一句话：** 闪电贷借 Index → `claim` 一次推入 low-supply 畸形态 → 循环零成本 `mint` 还贷 → `initWithdraw` 提 **105,471 USDC**，其余 Vault Token 转 helper；整笔攻击在一笔以太坊交易中完成。
