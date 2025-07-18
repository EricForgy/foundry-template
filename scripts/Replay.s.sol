// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import "./IJackRebalancePool.sol";
import {RebalancePoolStorageReader as Reader} from "../contracts/utils/RebalancePoolStorageReader.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IsAVAX {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract ReplayScript is Script {
    string rpc;
    uint256 forkId;
    IJackRebalancePool rp;
    address treasury;
    address market;
    address aToken;
    address xToken;
    address baseToken;
    address sAVAX;
    bytes32 txHashFirstDeposit;
    bytes32 txHashFirstReward;
    address user;
    address userFirst;
    address userMostActive;

    string txhashPath;

    bytes32[] public txHashes;

    function run() public {
        // Set up your fork
        rpc = vm.envString("RPC_URL");
        // rpc = "https://api.avax.network/ext/bc/C/rpc";
        // rpc = "https://site1.moralis-nodes.com/avalanche/1be6a26ede1245e0b7c90fe33115a012";
        forkId = vm.createSelectFork(rpc);

        // Optional: protocol-specific setup
        rp = IJackRebalancePool(0x0363a3deBe776de575C36F524b7877dB7dd461Db);
        treasury = 0xDC325ad34C762C19FaAB37d439fbf219715f9D58;
        market = 0xbB640E3Ae4fdd0f9B6d71B3d9F992E12f741b697;
        aToken = 0xaBe7a9dFDA35230ff60D1590a929aE0644c47DC1;
        xToken = 0x698C34Bad17193AF7E1B4eb07d1309ff6C5e715e;
        baseToken = 0x7aa5c727270C7e1642af898E0EA5b85a094C17a1;
        sAVAX = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
        txHashFirstDeposit = 0x4372a0106c4dec103e3ec3fc7a05a4cdc609c20e6ac0f6bc03cd1e9613bbc9f8;
        txHashFirstReward = 0x4d68abba2cc316477376969e62df2b8c220a1e9b4a7cd065f863cbf735e1fd13;
        userFirst = 0xF1102711b8df5EA6f934cb42F618ed040d0d5da6; // First user
        userMostActive = 0x16Fb7860Bd5e34E0021396fD79d7561eb4409023; // Most active user

        // txHashPath = "/tests/data/tx_hashes.json"; // All tx hashes
        txhashPath = "/tests/data/most_active_user_tx_hashes.json";

        // Load the JSON file
        string memory path = string.concat(vm.projectRoot(), txhashPath);
        string memory json = vm.readFile(path);
        // console.log("Loaded JSON bytes:", bytes(json).length);

        // Parse the array at $.tx_hashes
        bytes memory raw = vm.parseJson(json, "$.tx_hashes");
        txHashes = abi.decode(raw, (bytes32[]));
        console.log("Loaded %s tx hashes", txHashes.length);

        path = string.concat(
            vm.projectRoot(),
            "/tests/data/tx_hashes_users.ndjson"
        );

        string memory line;
        bytes32 txHash;
        bytes32 oldTxHash;
        uint256 txNumber = 5699; // Overall transaction counter
        uint256 txCount = 10000;
        uint256 txStop = txNumber + txCount; // Stop after txCount transactions
        uint256 txCounter = 1;

        // Skip lines up to txNumber
        while (txCounter <= txNumber) {
            line = vm.readLine(path);
            if (bytes(line).length == 0) {
                console.log("Reached end of file before txNumber", txNumber);
                return;
            }
            txHash = bytes32(vm.parseJson(line, "$.tx_hash"));
            if (txHash == oldTxHash) continue;
            oldTxHash = txHash;
            txCounter++;
        }

        // Process lines
        oldTxHash = bytes32(0); // Reset
        while (true) {
            if (bytes(line).length == 0 || txNumber >= txStop) break;

            txHash = bytes32(vm.parseJson(line, "$.tx_hash"));
            if (txHash == oldTxHash) {
                line = vm.readLine(path);
                continue;
            }
            user = vm.parseJsonAddress(line, "$.user");

            vm.rollFork(forkId, txHash);

            Reader.StateCache memory preCache = Reader.writeStateCache(
                vm,
                address(rp),
                user
            );
            vm.transact(forkId, txHash);
            Reader.StateCache memory postCache = Reader.writeStateCache(
                vm,
                address(rp),
                user
            );

            string memory txJson = string.concat(
                "{",
                '"tx_number":',
                vm.toString(txNumber),
                ",",
                '"tx_hash":"',
                vm.toString(txHash),
                '",',
                '"user":"',
                vm.toString(address(user)),
                '",',
                '"chain_id":43114,',
                '"pre_state":',
                preCache.stateJson,
                ",",
                '"post_state":',
                postCache.stateJson,
                "}"
            );

            vm.writeLine("output.ndjson", txJson);

            oldTxHash = txHash;
            txNumber++;
            line = vm.readLine(path);
        }

        vm.closeFile(path);
    }
}
