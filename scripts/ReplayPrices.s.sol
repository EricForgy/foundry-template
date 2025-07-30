// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

interface IPrice {
    function nav() external view returns (uint256);
    function getNavPerShare() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

struct Transfer {
    uint256 blockNumber;
    uint256 chainId;
    uint256 index;
    uint256 txIndex;
    uint256 amount;
    address contractAddress;
    address receiver;
    address sender;
    string txHash;
    string blockTime;
}

contract ReplayPricesScript is Script {
    function run() public {
        bool isVerbose = true;
        // Set up your fork
        string memory rpc = vm.rpcUrl("avalanche");
        uint256 forkId = vm.createSelectFork(rpc);

        string memory chain = "avalanche";
        string memory token = "rsAVAX-YT";
        string memory input_path =
            string.concat(vm.projectRoot(), "/scripts/data/transfers/", chain, "/", token, "/transfers.ndjson");
        string memory output_path =
            string.concat(vm.projectRoot(), "/scripts/data/transfers/", chain, "/", token, "/prices.ndjson");

        string memory line;
        uint256 txNumber = 689; // Overall transaction counter
        uint256 txCount = 10000;
        uint256 txStop = txNumber + txCount; // Stop after txCount transactions
        uint256 txCounter = 1;

        Transfer memory transfer;

        // Skip lines up to txNumber
        while (txCounter <= txNumber) {
            line = vm.readLine(input_path);
            if (bytes(line).length == 0) {
                console.log("Reached end of file before txNumber", txNumber);
                return;
            }
            txCounter++;
        }

        if (isVerbose) vm.writeLine("debug.txt", "NEW RUN");

        // Process lines
        while (true) {
            if (isVerbose) vm.writeLine("debug.txt", line);
            if (bytes(line).length == 0 || txNumber >= txStop) break;

            // {
            //     "block_number": 56629361,
            //     "chain_id": 43114,
            //     "index": 42,
            //     "tx_index": 5,
            //     "amount": 143065975045772720,
            //     "contract_address": "0x2fb74dcac32c49030d34649f0794f517f69b733a",
            //     "receiver": "0x3272f8f59e2d60cbac50d906b443a05a0776af82",
            //     "sender": "0x0000000000000000000000000000000000000000",
            //     "tx_hash": "0xc7dc94a9ac33a830129abf743f3ceaae42d5894bb811dba9b4b39e4ae69324f4",
            //     "block_time": "2025-01-31T19:13:07+00:00"
            // }

            transfer.blockNumber = vm.parseJsonUint(line, "$.block_number");
            transfer.chainId = vm.parseJsonUint(line, "$.chain_id");
            transfer.index = vm.parseJsonUint(line, "$.index");
            transfer.txIndex = vm.parseJsonUint(line, "$.tx_index");
            transfer.amount = vm.parseJsonUint(line, "$.amount");
            transfer.contractAddress = vm.parseJsonAddress(line, "$.contract_address");
            transfer.receiver = vm.parseJsonAddress(line, "$.receiver");
            transfer.sender = vm.parseJsonAddress(line, "$.sender");
            transfer.txHash = vm.parseJsonString(line, "$.tx_hash");
            transfer.blockTime = vm.parseJsonString(line, "$.block_time");

            IPrice priceContract = IPrice(transfer.contractAddress);

            if (isVerbose) vm.writeLine("debug.txt", string.concat("txHash:", transfer.txHash));
            if (isVerbose) vm.writeLine("debug.txt", string.concat("blockNumber:", vm.toString(transfer.blockNumber)));

            // vm.rollFork(forkId, transfer.blockNumber);
            vm.rollFork(forkId, vm.parseBytes32(transfer.txHash));

            if (isVerbose) {
                vm.writeLine("debug.txt", string.concat("totalAssets:", vm.toString(priceContract.totalAssets())));
            }
            if (isVerbose) {
                vm.writeLine("debug.txt", string.concat("totalSupply:", vm.toString(priceContract.totalSupply())));
            }

            if (isVerbose) vm.writeLine("debug.txt", string.concat("blockNumber:", vm.toString(vm.getBlockNumber())));

            // uint256 price = priceContract.nav();
            uint256 price = priceContract.getNavPerShare();
            if (isVerbose) {
                vm.writeLine("debug.txt", string.concat("price:", vm.toString(price)));
            }

            string memory txJson = string.concat(
                "{",
                '"block_number":',
                vm.toString(transfer.blockNumber),
                ",",
                '"chain_id":',
                vm.toString(transfer.chainId),
                ",",
                '"index":',
                vm.toString(transfer.index),
                ",",
                '"tx_index":',
                vm.toString(transfer.txIndex),
                ",",
                '"amount":',
                vm.toString(transfer.amount),
                ",",
                '"price":',
                vm.toString(price),
                ",",
                '"contract_address":"',
                vm.toString(transfer.contractAddress),
                '",',
                '"receiver":"',
                vm.toString(transfer.receiver),
                '",',
                '"sender":"',
                vm.toString(transfer.sender),
                '",',
                '"tx_hash":"',
                transfer.txHash,
                '",',
                '"block_time":"',
                transfer.blockTime,
                '"}'
            );

            vm.writeLine(output_path, txJson);

            txNumber++;
            line = vm.readLine(input_path);
        }

        vm.closeFile(input_path);
        vm.closeFile(output_path);
    }
}
