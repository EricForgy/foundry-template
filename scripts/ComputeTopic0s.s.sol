// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

contract ComputeTopic0sScript is Script {
    function run() external pure {
        string[] memory sigs;
        sigs = new string[](11);
        sigs[0] = "YieldDistributed(uint256,uint256)";
        sigs[1] = "NAVUpdated(address,uint256,uint256)";
        sigs[2] = "CoolingOffPeriodUpdated(uint256,uint256)";
        sigs[3] = "FeeCollectorUpdated(address,address)";
        sigs[4] = "PriceOracleUpdated(address,address)";
        sigs[5] = "OtherERC20Withdrawn(address,address,uint256)";
        sigs[6] = "DepositMade(address,address,uint256)";
        sigs[7] = "YieldFeeUpdated(uint256)";
        sigs[8] = "Deposit(address,address,uint256,uint256)";
        sigs[9] = "Withdraw(address,address,address,uint256,uint256)";
        sigs[10] = "Transfer(address,address,uint256)";

        for (uint256 i = 0; i < sigs.length; i++) {
            bytes32 topic0 = keccak256(bytes(sigs[i]));
            console2.log(sigs[i]);
            console2.logBytes32(topic0);
            console2.log("");
        }
    }
}
