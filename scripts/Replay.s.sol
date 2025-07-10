// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";

contract ReplayScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
    }
}
