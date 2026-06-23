# 发布元信息（粘贴到 https://learnblockchain.cn/article/create 表单）

**标题：** Little Boy Plus 攻击复盘：`_update(0)` 仍 harvest 与 Pancake Pair 储备套利

**专栏 / 专题：** 链上安全深潜

**分类：** 安全

**标签：** Little Boy Plus, BSC, DeFi, 智能合约安全, PancakeSwap, AMM, Fork PoC, Foundry

**摘要（≤250 字，填在编辑器摘要框）：**

2026-06-17，BSC Little Boy Plus 单笔攻击（约 377k USDT）。根因：LBPHashrate 零金额 _update 仍 harvest，第三方可代 Pair 触发 mintReward，Pair LBP balance 与 reserves 脱节；另以 skim 设 lastTransfer 放大 buffer 后 swap 套利。辨析 LBP/hLBP 与 skim ablation，附 BSC fork PoC。

**封面：** 上传 `assets/column-cover-lian-shang-anquan-shenqian-1920x1080.png`（或专题统一封面）

**原文链接（可选）：** GitHub `attack-event/LittleBoyPlus.md`

---

# 正文（从下一行起复制到 Markdown 编辑器）

> **链上安全深潜** · 主网攻击 · 根因 · Fork 复现  
> PoC：https://github.com/EthanOK/contract-attacks/tree/master/contracts/test/LittleBoyPlus

---

## 交易概览

| 项目 | 内容 |
|------|------|
| 交易 | `0x55856d9fda4c5be5193561c7d775e823c3d6e499da44aab9da963daf61c50b0c` |
| 链 | BNB Smart Chain |
| 区块 | `104727184`（Position #61） |
| 时间 | 2026-06-17 08:35:38 UTC |
| BscScan | https://bscscan.com/tx/0x55856d9fda4c5be5193561c7d775e823c3d6e499da44aab9da963daf61c50b0c |
| Phalcon | https://app.blocksec.com/phalcon/explorer/tx/bsc/0x55856d9fda4c5be5193561c7d775e823c3d6e499da44aab9da963daf61c50b0c |
| SlowMist | https://x.com/SlowMist_Team/status/2067424733747122259 |

2026 年 6 月 17 日，攻击者对 BSC 上 **Little Boy Plus（LBP）** 生态发起单笔原子交易。根因是 **`LBPHashrate._update()` 在零金额转账时仍执行 `_harvest()`**，任意地址可 `transferFrom(pair, …, 0)` 代 Pair 触发 `LBP.mintReward`，向 Pancake Pair 铸造 **LBP（token1）** 且不更新 `getReserves()`，造成 **balance ≠ reserves**，再通过 `pair.swap` 抽走 USDT。

| 指标 | 数值 |
|------|------|
| 估计损失 | ~377,642 USDT / ~610.55 BNB（SlowMist） |
| 攻击者留存 | ~605.55 BNB（扣 5 BNB MEV 贿赂后） |
| 资金放大 | Moolah ~777 万 U + Infinity Vault ~3408 万 U（同 tx 借还） |
| Gas | 4,809,427 / 4,969,843（96.77%） |

**重要澄清：** 根因 **不是** OpenZeppelin「零金额跳过 allowance」。即使强制检查 allowance，`amount=0` 时条件为 `allowance >= 0`，对任意 `uint256` **恒成立**，无法拦住该调用。

---

## LBP 与 hLBP（必先分清）

生态里有两个 ERC20，trace 里极易混成一团：

| | **LBP**（Little Boy Plus） | **hLBP**（LBPHashrate） |
|--|---------------------------|-------------------------|
| 地址 | `0x88886f0f…` | `0x5e3cbc82…` |
| 角色 | 受害 Pair **token1**；`swap` 买卖对象 | **算力代币**；`notifyCredit` / `_harvest` 所在合约 |
| 铸到 Pair 地址 | `mintReward` → **LBP** balance↑，**可 drain** | `notifyCredit` → **hLBP** balance↑，**不参与 AMM 定价** |

**套现（drain）看的是 Pair 上 LBP 的 `balanceOf − getReserves()`，不是 hLBP 余额。**

关键地址：

| 角色 | 地址 |
|------|------|
| 受害 Pair（LBP/USDT） | `0x00e3Ea08fD8CBaD955Ec5d2292Ad637670c31524` |
| Infinity Vault | `0x238a358808379702088667322f80aC48bAd5e6c4` |
| 攻击合约 | `0x5449ded887576f43Fc339851e942eBc1E6F8118b` |

---

## 漏洞根因

漏洞位于 **`LBPHashrate._update()`**（`0x5e3cbc82…`）：

```solidity
hLBP.transferFrom(pair, DEAD, 0)
  → _update(from=pair, to=DEAD, value=0)   // 零金额仍进钩子
  → _harvest(pair)
  → LBP.mintReward(pair, reward)           // 铸 LBP 到 Pair，reserves 不变
```

| 缺陷点 | 实际行为 |
|--------|----------|
| `_update` 对 `value == 0` | **仍调用 `_harvest(from)`** |
| 触发准入 | **任意地址** 可代 Pair 调用 `transferFrom(pair, …, 0)` |
| `mintReward` 后 | Pair **LBP balance↑**，`getReserves()` **不变** → 可套利 |

LBP 合约 Layer 2.5 只挡 `LBP.transferFrom(pair, 0)`，**挡不住** hLBP 合约侧的同构调用。

PancakeSwap V2 定价依赖 **reserves**，`swap` 结算用 **实际 balance**。`mintReward` 注入 LBP 后：

```
reserves 仍按旧比例（LBP 侧偏低）
实际 balance 已大幅增加（LBP 侧偏高）
→ 攻击者用 LBP 按失真价格 swap 出大量 USDT
```

---

## 攻击流程（PoC 对齐）

链上原始 tx 含 Moolah 闪电贷与若干小单 swap；fork PoC 验证 **省略 Moolah 与小单后利润一致**，核心链如下：

```
① Infinity Vault.take(~3408 万 USDT)
② flushPol()
③ 15M USDT swap 买 LBP（扭曲 reserves）
④ 注入 LBP + ~579 万 USDT（balance > reserves）
⑤ pair.skim(pair)          ← lastTransfer = Pair（枢纽）
⑥ pair.mint(攻击者)        ← 产生 lpDelta
⑦ LBP.transfer(0)          ← notifyCredit(Pair) → ~1073 万 hLBP buffer
⑧ hLBP.transferFrom(pair, 0) ← harvest → mintReward → LBP 盈余
⑨ pre-drain + pair.swap    ← drain USDT
⑩ 还 Vault + USDT→WBNB→BNB
```

### 两个「零金额」触发器（勿混）

| 调用 | 铸什么 | 作用 |
|------|--------|------|
| `LBP.transfer(攻击者, 0)` | **hLBP** → Pair 地址 | buffer 放大；依赖 **⑤ skim** 使 `lastTransfer=Pair` |
| `hLBP.transferFrom(pair, DEAD, 0)` | **LBP** → Pair（token1） | **harvest 根因**；直接制造可 drain 的 LBP 盈余 |

### `lastTransfer` 时间线（fork 实测）

```
注入 LBP/USDT 后     lastTransfer = 0x0
skim(Pair)           lastTransfer = Pair
mint(攻击者)         lastTransfer = Pair
transfer(0) settle   lastTransfer = 0x0
```

Phalcon 中 `notifyCredit(user=Pair)` 的 `user`，来自 settle 时读到的 **`lastTransfer`（已为 Pair）**，不是 Cake-LP 持有人（攻击者）。

### skim 为何不可省略（ablation）

| 场景 | 结果 |
|------|------|
| **有 skim** | ✅ 净利 **~369,624 USDT** / **~597.87 BNB** |
| **无 skim** | ❌ 还 Vault ~3408 万 U 时 revert（`transfer amount exceeds balance`） |

无 skim 时 harvest + drain 仍会跑，主 swap 约 **~2035 万 USDT**，但不足以还 Vault。`skim(pair)` 的标准语义是扫出 `balance − reserve` 超额代币；攻击者设 `to=pair` 是为了触发 **from=pair** 的 LBP `_update`，把 `lastTransfer` staging 为 Pair，从而打通 buffer 放大链——**对完整套利必需**，非装饰性调用。

### 闪电贷角色

链上同时使用 Moolah（~777 万 U）与 Infinity Vault（~3408 万 U）。操纵进池 USDT 约 **2079 万**（1500 万 swap + ~579 万注入），Vault 单路已可覆盖。**Moolah 在 PoC 中移除后利润不变**，属资金放大习惯，非漏洞硬性依赖。

---

## 与 BY Token 对比

| 维度 | BY Token | Little Boy Plus |
|------|----------|-----------------|
| 失衡来源 | `triggerAutoBurn` + `sync` | `mintReward` 铸入 LBP |
| 触发入口 | 无权限 `triggerAutoBurn` | `hLBP.transferFrom(pair, 0)` |
| 变现 | WBNB `swap` | USDT `swap` → BNB |

共同点：Pair **balance ≠ reserves** 后 `swap` 套利；触发路径完全不同。

---

## Fork PoC 复现

```bash
# .env 配置 archive BSC_RPC_URL
# foundry.toml 需 evm_version = cancun（Infinity Vault transient storage）
forge test --match-contract LittleBoyPlusChallenge -vv
```

| 指标 | PoC（fork `104727183`） | 链上 |
|------|------------------------|------|
| 净赚 USDT（还 Vault 后） | **~369,624** | ~377,642 |
| 变现 BNB | **~597.87** | ~610.55（扣 MEV 后 ~605.55） |

- 攻击合约：`contracts/test/LittleBoyPlus/AttackLittleBoyPlus.sol`
- 无 `deal` 作弊；利润全部来自 exploit

---

## 修复建议

1. `_update()` 对 `value == 0` 不应执行 `_harvest` / settle
2. 禁止第三方以 Pair 为 `from` 代触发 harvest
3. `mintReward` 不向 Pair 直铸 LBP，或铸后强制 `pair.sync()`
4. `skim(to=pair)` 不应将 `lastTransfer` 设为 Pair；应校验 staging 用户为真实加池者
5. hLBP 与 LBP 合约须对称修补（Layer 2.5 仅挡本合约 `transferFrom` 不够）

---

## 参考资料

- [BscScan 攻击交易](https://bscscan.com/tx/0x55856d9fda4c5be5193561c7d775e823c3d6e499da44aab9da963daf61c50b0c)
- [BlockSec Phalcon](https://app.blocksec.com/phalcon/explorer/tx/bsc/0x55856d9fda4c5be5193561c7d775e823c3d6e499da44aab9da963daf61c50b0c)
- [SlowMist TI Alert](https://x.com/SlowMist_Team/status/2067424733747122259)
- [LBPHashrate 合约](https://bscscan.com/address/0x5e3cbc82d020be91a989eb747934104e9ab585fe)

---

> **一句话：** Vault 借 USDT 操纵 LBP/USDT Pair → `skim(pair)` 设 `lastTransfer` → buffer 铸 hLBP → `hLBP.transferFrom(pair,0)` harvest 铸 LBP 却不更新 reserves → `swap` drain USDT 还 Vault，单笔 tx 变现约 **377k USDT**。

**完整版（Phalcon 逐步表、链上原始 tx 对比、资金流图）：** https://github.com/EthanOK/contract-attacks/blob/master/attack-event/LittleBoyPlus.md
