# 合约攻击复现与分析（Hardhat + Foundry）

本仓库用于整理**合约攻击事件分析**与**PoC/复现用例**，并提供一套统一的本地开发与测试工作流（Hardhat + Foundry 混合工程）。

## 快速开始

### 环境要求

- Node.js（建议 LTS）
- Foundry（`forge` / `cast`）

### 安装依赖

```shell
npm install
forge install
```

> 如果 `forge install` 因为网络/子模块问题失败，也可以先跑 Hardhat 测试；Foundry 侧的测试需要 `contracts/lib` 依赖完整。

## 常用命令

本项目在 `package.json` 里封装了常用脚本，推荐优先使用：

```shell
# 清理 Hardhat + Foundry 构建产物
npm run clean

# 同时编译 Hardhat + Foundry
npm run compile

# 仅 Hardhat 测试
npm run test:hh

# 仅 Foundry 测试（更详细日志）
npm run test:ff

# 全量测试（Hardhat + Foundry）
npm test

# Hardhat 本地节点
npm run node
```

## 目录结构

```text
attack-event/          攻击事件分析文档（Markdown）
contracts/src/         复现/分析相关合约源码（Foundry src）
contracts/test/        Foundry 测试与 PoC（forge test）
contracts/script/      Foundry 脚本（forge script）
test/                 Hardhat 测试（hardhat test）
scripts/              Hardhat 脚本（hardhat run）
utils/                辅助脚本（如读取交易/合约信息等）
```

## 攻击事件索引

| 攻击时间 | 项目 | 链 | 损失金额 | 攻击交易 | 复现/PoC | 根因 |
| :--: | :-- | :--: | :--: | :-- | :-- | :-- |
| 2024.07.16 | [LI.FI Protocol](./attack-event/LI_FI_Protocol.md) | Ethereum | $2,276,295 | `0xd82fe84e63b1aa52e1ce540582ee0895ba4a71ec5e7a632a3faa1aff3e763873` | `contracts/test/LiFiDiamond/LiFiDiamondChallenge.t.sol` | 底层 `call` 调用 + 参数校验不严格（可被构造 `transferFrom`） |
| 2024.07.23 | [Spectra Protocol](./attack-event/SpectraProtocol.md) | Ethereum | $73,325 | `0x491cf8b2a5753fdbf3096b42e0a16bc109b957dc112d6537b1ed306e483d0744` | `contracts/test/Spectra/AttackSpectraAMProxy.sol` | 底层 `call` 调用 + 参数校验不严格（可被构造任意路由调用） |
| 2026.06.15 | [Thetanuts Finance](./attack-event/ThetanutsFinance.md) | Ethereum | ~$2.1M | `0xbba9f138fe39503bfd1aa62932dbd6ab35d37d23d48e4b7bf2988a9d5dc39fec` | （分析为主，PoC 待补） | low-supply 边界下整数除法舍入错误（零成本 `mint` + `claim`/`initWithdraw` 兑现） |

## 如何新增一个事件/PoC

- **文档**：在 `attack-event/` 新建 `xxx.md`，建议包含：
  - 事件概览（时间/损失/链/合约地址）
  - 根因分析（关键调用链、权限/校验缺失点）
  - 修复建议（最小修复、附加防护、回归测试点）
- **复现**：
  - 合约放在 `contracts/src/<EventName>/...`
  - 测试/PoC 放在 `contracts/test/<EventName>/...`，通过 `forge test -vvv` 可复现
  - 如需 Hardhat 环境辅助，可在 `test/` 或 `scripts/` 添加对应用例

## 配置说明

- **Solidity 版本**：`0.8.20`（Hardhat 与 Foundry 保持一致）
- **Foundry 配置**：见 `foundry.toml`（默认 `contracts/src`、`contracts/test` 等）
- **环境变量**：参考 `.env.demo`（如需要自行复制为 `.env`）

## 免责声明

本仓库内容仅用于**安全研究、学习与复现**目的。请勿将 PoC/技巧用于任何未授权的系统或链上资产操作；由此产生的任何后果由使用者自行承担。
