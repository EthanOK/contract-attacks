# Hardhat Integrate Foundry Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

## install

```shell
npm install && forge install
```

## review attack event

| 攻击时间   |                         项目                          |  损失金额  |                            原因 |
| :--------- | :---------------------------------------------------: | :--------: | ------------------------------: |
| 2024.07.16 |  [LI.FI Protocol](./attack-event/LI_FI_Protocol.md)   | $2,276,295 | 底层 call 调用 + 参数校验不严格 |
| 2024.07.23 | [Spectra Protocol](./attack-event/SpectraProtocol.md) |  $73, 325  | 底层 call 调用 + 参数校验不严格 |
