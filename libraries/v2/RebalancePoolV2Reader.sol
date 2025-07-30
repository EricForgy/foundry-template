// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StorageSlotLib} from "../StorageSlotLib.sol";
import "forge-std/Vm.sol";

library RebalancePoolV2Reader {
    using StorageSlotLib for Vm;

    struct LastDeposit {
        uint256 timestamp;
        uint256 amount;
        address depositor;
    }

    function writeJson(
        Vm vm,
        LastDeposit memory d
    ) internal pure returns (string memory) {
        return
            string.concat(
                "{",
                '"timestamp":',
                vm.toString(d.timestamp),
                ",",
                '"amount":',
                vm.toString(d.amount),
                ",",
                '"depositor":"',
                vm.toString(d.depositor),
                '"',
                "}"
            );
    }

    function name(Vm vm, address pool) internal view returns (string memory) {
        return vm.loadString(pool, 54);
    }

    function symbol(Vm vm, address pool) internal view returns (string memory) {
        return vm.loadString(pool, 55);
    }

    function totalSupply(Vm vm, address pool) internal view returns (uint256) {
        return vm.loadUint256(pool, 53);
    }

    function decimals(Vm vm, address pool) internal view returns (uint8) {
        return vm.loadUint8(pool, 364);
    }

    function protocolAddress(
        Vm vm,
        address pool
    ) internal view returns (address) {
        return vm.loadAddress(pool, 351);
    }

    function treasuryAddress(
        Vm vm,
        address pool
    ) internal view returns (address) {
        return vm.loadAddress(pool, 352);
    }

    function aTokenAddress(
        Vm vm,
        address pool
    ) internal view returns (address) {
        return vm.loadAddress(pool, 353);
    }

    function aToken(Vm vm, address pool) internal view returns (address) {
        return vm.loadAddress(pool, 354);
    }

    function yieldFeePercentage(
        Vm vm,
        address pool
    ) internal view returns (uint256) {
        return vm.loadUint256(pool, 355);
    }

    function lastTotalAssets(
        Vm vm,
        address pool
    ) internal view returns (uint256) {
        return vm.loadUint256(pool, 356);
    }

    function coolingPeriod(
        Vm vm,
        address pool
    ) internal view returns (uint256) {
        return vm.loadUint256(pool, 359);
    }

    function balanceOf(
        Vm vm,
        address pool,
        address user
    ) internal view returns (uint256) {
        bytes32 slot = keccak256(abi.encode(user, uint256(51)));
        return vm.loadUint256(pool, uint256(slot));
    }

    function lastDeposits(
        Vm vm,
        address pool,
        address user
    ) internal view returns (LastDeposit memory d) {
        bytes32 base = keccak256(abi.encode(user, uint256(360)));
        d.timestamp = uint256(vm.load(pool, base));
        d.amount = uint256(vm.load(pool, bytes32(uint256(base) + 1)));
        d.depositor = address(
            uint160(uint256(vm.load(pool, bytes32(uint256(base) + 2))))
        );
    }

    function lastNavUpdate(
        Vm vm,
        address pool,
        address user
    ) internal view returns (uint256) {
        bytes32 slot = keccak256(abi.encode(user, uint256(361)));
        return vm.loadUint256(pool, uint256(slot));
    }

    function additionalTokens(
        Vm vm,
        address pool
    ) internal view returns (address[] memory tokens) {
        uint256 len = vm.loadUint256(pool, 362);
        tokens = new address[](len);
        bytes32 base = keccak256(abi.encode(uint256(362)));
        for (uint256 i = 0; i < len; i++) {
            tokens[i] = vm.loadAddress(pool, uint256(base) + i);
        }
    }

    function isAdditionalToken(
        Vm vm,
        address pool,
        address token
    ) internal view returns (bool) {
        bytes32 slot = keccak256(abi.encode(token, uint256(363)));
        return vm.loadUint256(pool, uint256(slot)) != 0;
    }
}
