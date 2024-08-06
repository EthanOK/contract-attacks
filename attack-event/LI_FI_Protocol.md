# LI.FI Protocol 聚合协议

## 攻击交易：

> https://etherscan.io/tx/0xd82fe84e63b1aa52e1ce540582ee0895ba4a71ec5e7a632a3faa1aff3e763873

## 交易调用栈:

> Transaction Track: [Tenderly](https://dashboard.tenderly.co/tx/mainnet/0xd82fe84e63b1aa52e1ce540582ee0895ba4a71ec5e7a632a3faa1aff3e763873)

## foundry 模拟攻击:

> [AttackLiFiDiamond](../contracts/test/LiFiDiamond/LiFiDiamondChallenge.t.sol)

[漏洞位置](https://etherscan.io/address/0xf28A352377663cA134bd27B582b1a9A4dad7e534#code#F3#L60):

`_swap.callTo.call{value: nativeValue}(_swap.callData)`

```solidity
function swap(bytes32 transactionId, SwapData calldata _swap) internal {
        if (!LibAsset.isContract(_swap.callTo)) revert InvalidContract();
        uint256 fromAmount = _swap.fromAmount;
        if (fromAmount == 0) revert NoSwapFromZeroBalance();
        uint256 nativeValue = LibAsset.isNativeAsset(_swap.sendingAssetId)
            ? _swap.fromAmount
            : 0;
        if (nativeValue == 0) {
            LibAsset.maxApproveERC20(
                IERC20(_swap.sendingAssetId),
                _swap.approveTo,
                _swap.fromAmount
            );
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = _swap.callTo.call{
            value: nativeValue
        }(_swap.callData);
        if (!success) {
            LibUtil.revertWith(res);
        }
    }
```

## 原因：参数校验不严格；底层 call 调用。

用户授权给协议合约额度较大，攻击者调用协议合约，协议合约底层调用 transferFrom 转移用户 Token。
