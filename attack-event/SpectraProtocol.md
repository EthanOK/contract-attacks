# Spectra Protocol 项目

## 攻击交易：

> https://etherscan.io/tx/0x491cf8b2a5753fdbf3096b42e0a16bc109b957dc112d6537b1ed306e483d0744

## 交易调用栈:

> Transaction Track: [Phalcon](https://app.blocksec.com/explorer/tx/eth/0x491cf8b2a5753fdbf3096b42e0a16bc109b957dc112d6537b1ed306e483d0744)

## foundry 模拟攻击:

> [AttackSpectraAMProxy](../contracts/test/AttackSpectraAMProxy.t.sol)

[漏洞位置](https://etherscan.io/address/0x51bdbfcd7656e2c25ad1bc8037f70572b7142ecc#code#F7#L338):

`kyberRouter.call{value: msg.value}(targetData)`

```solidity
  function _dispatch(bytes1 _commandType, bytes calldata _inputs) internal {
        uint256 command = uint8(_commandType & Commands.COMMAND_TYPE_MASK);

        if (command == Commands.TRANSFER_FROM) {
            (address token, uint256 value) = abi.decode(_inputs, (address, uint256));
            IERC20(token).safeTransferFrom(msgSender, address(this), value);
        } else if (command == Commands.KYBER_SWAP) {
            (
                address kyberRouter,
                address tokenIn,
                uint256 amountIn,
                address tokenOut,
                ,
                bytes memory targetData
            ) = abi.decode(_inputs, (address, address, uint256, address, uint256, bytes));
            if (tokenOut == Constants.ETH) {
                revert AddressError();
            }
            if (tokenIn == Constants.ETH) {
                if (msg.value != amountIn) {
                    revert AmountError();
                }
                (bool success, ) = kyberRouter.call{value: msg.value}(targetData);
                if (!success) {
                    revert CallFailed();
                }
            } else {
                amountIn = _resolveTokenValue(tokenIn, amountIn);
                IERC20(tokenIn).forceApprove(kyberRouter, amountIn);
                (bool success, ) = kyberRouter.call(targetData);
                if (!success) {
                    revert CallFailed();
                }
                IERC20(tokenIn).forceApprove(kyberRouter, 0);
            }
        } else {
            revert InvalidCommandType(command);
        }
    }
```

## 原因：参数校验不严格；底层 call 调用。

用户授权给协议合约额度较大，攻击者调用协议合约，协议合约底层调用 transferFrom 转移用户 Token。

# 控制权
