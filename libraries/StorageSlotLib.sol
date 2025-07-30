// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Vm.sol";

library StorageSlotLib {
    function loadString(Vm vm, address target, uint256 slot) internal view returns (string memory value) {
        bytes32 raw = loadSlot(vm, target, slot);
        value = string(abi.encodePacked(raw));
    }

    function loadUint8(Vm vm, address target, uint256 slot) internal view returns (uint8 value) {
        bytes32 raw = loadSlot(vm, target, slot);
        return uint8(uint256(raw));
    }

    function loadUint256(Vm vm, address target, uint256 slot) internal view returns (uint256 value) {
        bytes32 raw = loadSlot(vm, target, slot);
        return uint256(raw);
    }

    function loadAddress(Vm vm, address target, uint256 slot) internal view returns (address value) {
        bytes32 raw = loadSlot(vm, target, slot);
        return address(uint160(uint256(raw)));
    }

    function loadBool(Vm vm, address target, uint256 slot, uint256 offset) internal view returns (bool value) {
        require(offset < 32, "Offset out of bounds");
        bytes32 raw = loadSlot(vm, target, slot);
        uint8 bit = uint8(uint256(raw) >> (offset * 8)); // Shift by byte
        return bit != 0;
    }

    function loadSlot(Vm vm, address target, uint256 slot) internal view returns (bytes32 value) {
        return vm.load(target, bytes32(slot));
    }
}
