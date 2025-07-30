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

struct DailyPrice {
    uint256 chainId;
    address contractAddress;
    string day;
    uint256 blockNumber;
    uint256 price;
}

struct DailyFirstBlock {
    uint256 chain_id;
    string day;
    uint256 first_block;
}

struct Config {
    bool isVerbose;
    string chain;
    uint256 chainId;
    string rpc;
    uint256 forkId;
    string inputPath;
    string outputPath;
    string line;
    uint256 txNumber;
    uint256 txCount;
    uint256 txStop;
    address[] contracts;
    uint256[] firstBlocks;
    bool[] isYT;
}

contract ReplayDailyPricesScript is Script {
    function run() public {
        Config memory c;
        c.isVerbose = true;
        // c.chainId = 43114;
        if (c.chainId == 43114) {
            c.chain = "avalanche";
            c.contracts = new address[](5);
            c.contracts[0] = 0x698C34Bad17193AF7E1B4eb07d1309ff6C5e715e; // xAVAX
            c.contracts[1] = 0x737d122B69A732cDB7CE126C1e044c2bfB2fbfA1; // PT-rsAVAX
            c.contracts[2] = 0x2Fb74DCAC32c49030D34649F0794F517f69B733A; // YT-rsAVAX
            c.contracts[3] = 0xD46765985fb0E8AD889FD5eE3Db62722c4ecf58f; // PT-savUSD
            c.contracts[4] = 0x1326a1b025BC099197654FE027A6B2361Fe4899c; // YT-savUSD

            c.firstBlocks = new uint256[](c.contracts.length);
            c.firstBlocks[0] = 46938469; // xAVAX
            c.firstBlocks[1] = 56626964; // PT-rsAVAX
            c.firstBlocks[2] = 56626968; // YT-rsAVAX
            c.firstBlocks[3] = 57506295; // PT-savUSD
            c.firstBlocks[4] = 57506299; // YT-savUSD

            c.isYT = new bool[](c.contracts.length);
            c.isYT[2] = true; // YT-rsAVAX
            c.isYT[4] = true; // YT-savUSD
        } else {
            c.chain = "sonic";
            // c.contracts = new address[](10);
            // c.contracts[0] = 0xFCA91fEEe65DB34448A83a74f4f8970b5dddfa7c; // PT-stS
            // c.contracts[1] = 0x0fa31f0d5a574F083E0be272a6CF807270352b3f; // YT-stS
            // c.contracts[2] = 0xbe1B1dd422d94f9c1784FB9356ef83A29E1A8cFa; // PT-wOS
            // c.contracts[3] = 0xe16Bb6061B3567ee86285ab7780187cB39aCC55E; // YT-wOS
            // c.contracts[4] = 0x11d686EF994648Ead6180c722F122169058389ee; // PT-scUSD
            // c.contracts[5] = 0xd2901D474b351bC6eE7b119f9c920863B0F781b2; // YT-scUSD
            // c.contracts[6] = 0x8e1E17343B8e4F5e1baA868500163212e00366cc; // y-wstkscUSD
            // c.contracts[7] = 0xE8dcBc94a1A852E7F53713a0E927eF16D980b278; // p-wstkscUSD
            // c.contracts[8] = 0x21391b75943CeDC939487dD3bf1e16eDf44f3968; // sncUSD
            // c.contracts[9] = 0x2267bc04754A81989f681dCc65834073d088128b; // xS

            c.contracts = new address[](1);
            c.contracts[0] = 0x21391b75943CeDC939487dD3bf1e16eDf44f3968; // sncUSD

            c.firstBlocks = new uint256[](c.contracts.length);
            c.firstBlocks[0] = 37479591; // sncUSD
            // c.firstBlocks[0] = 7681400; // PT-stS
            // c.firstBlocks[1] = 7681410; // YT-stS
            // c.firstBlocks[2] = 7682716; // PT-wOS
            // c.firstBlocks[3] = 7682723; // YT-wOS
            // c.firstBlocks[4] = 9829534; // PT-scUSD
            // c.firstBlocks[5] = 9829555; // YT-scUSD
            // c.firstBlocks[6] = 36639775; // y-wstkscUSD
            // c.firstBlocks[7] = 36639775; // p-wstkscUSD
            // c.firstBlocks[8] = 37479591; // sncUSD
            // c.firstBlocks[9] = 37479591; // xS

            c.isYT = new bool[](c.contracts.length);
            c.isYT[0] = true; // sncUSD
                // c.isYT[1] = true; // YT-stS
                // c.isYT[3] = true; // YT-wOS
                // c.isYT[5] = true; // YT-scUSD
                // c.isYT[6] = true; // y-wstkscUSD
                // c.isYT[8] = true; // sncUSD
        }
        c.rpc = vm.rpcUrl(c.chain);
        c.forkId = vm.createSelectFork(c.rpc);
        c.inputPath =
            string.concat(vm.projectRoot(), "/scripts/data/daily_prices/", c.chain, "/daily_first_blocks.ndjson");
        c.outputPath = string.concat(vm.projectRoot(), "/scripts/data/daily_prices/", c.chain, "/daily_prices.ndjson");
        c.txNumber = 220; // Overall transaction counter
        c.txCount = 10000;
        c.txStop = c.txNumber + c.txCount; // Stop after txCount transactions

        if (c.isVerbose) vm.writeLine("debug.txt", "NEW RUN");

        // Skip lines up to txNumber
        for (uint256 i; i < c.txNumber; i++) {
            c.line = vm.readLine(c.inputPath);
            if (bytes(c.line).length == 0) {
                console.log("Reached end of file before txNumber", c.txNumber);
                return;
            }
        }
        if (c.isVerbose) vm.writeLine("debug.txt", c.line);

        // Process lines
        while (true) {
            if (bytes(c.line).length == 0 || c.txNumber >= c.txStop) break;

            for (uint256 i; i < c.contracts.length; i++) {
                DailyPrice memory d;
                d.blockNumber = vm.parseJsonUint(c.line, "$.first_block");
                if (d.blockNumber < c.firstBlocks[i]) {
                    if (c.isVerbose) {
                        vm.writeLine(
                            "debug.txt",
                            string.concat(
                                "Skipping contract ",
                                vm.toString(c.contracts[i]),
                                " at block ",
                                vm.toString(d.blockNumber),
                                " (first block: ",
                                vm.toString(c.firstBlocks[i]),
                                ")"
                            )
                        );
                    }
                } else {
                    d.chainId = vm.parseJsonUint(c.line, "$.chain_id");
                    d.contractAddress = c.contracts[i];
                    d.day = vm.parseJsonString(c.line, "$.day");

                    IPrice priceContract = IPrice(d.contractAddress);

                    // if (isVerbose) {
                    //     vm.writeLine("debug.txt", string.concat("txHash:", vm.toString(d.blockNumber)));
                    //     vm.writeLine("debug.txt", string.concat("blockNumber:", vm.toString(d.blockNumber)));
                    // }

                    vm.rollFork(c.forkId, d.blockNumber);

                    // if (isVerbose) {
                    //     vm.writeLine("debug.txt", string.concat("totalAssets:", vm.toString(priceContract.totalAssets())));
                    //     vm.writeLine("debug.txt", string.concat("totalSupply:", vm.toString(priceContract.totalSupply())));
                    // }

                    if (c.isVerbose) {
                        vm.writeLine("debug.txt", string.concat("blockNumber:", vm.toString(vm.getBlockNumber())));
                    }

                    if (c.isYT[i]) {
                        // d.price = priceContract.getNavPerShare();

                        try priceContract.getNavPerShare() returns (uint256 p) {
                            if (p == 0) {
                                vm.writeLine(
                                    "debug.txt", string.concat("Price is zero for", vm.toString(d.contractAddress))
                                );
                                // optionally: skip or fallback
                            } else {
                                d.price = p;
                            }
                        } catch {
                            vm.writeLine(
                                "debug.txt",
                                string.concat("Call to getNavPerShare() failed for", vm.toString(d.contractAddress))
                            );
                            // optionally: price = type(uint256).max; // or skip
                        }
                    } else {
                        // d.price = priceContract.nav();

                        try priceContract.nav() returns (uint256 p) {
                            if (p == 0) {
                                vm.writeLine(
                                    "debug.txt", string.concat("Price is zero for", vm.toString(d.contractAddress))
                                );
                                // optionally: skip or fallback
                            } else {
                                d.price = p;
                            }
                        } catch {
                            vm.writeLine(
                                "debug.txt", string.concat("Call to nav() failed for", vm.toString(d.contractAddress))
                            );
                            // optionally: price = type(uint256).max; // or skip
                        }
                    }

                    if (c.isVerbose) {
                        vm.writeLine("debug.txt", string.concat("price:", vm.toString(d.price)));
                    }

                    string memory txJson = string.concat(
                        "{",
                        '"chain_id":',
                        vm.toString(d.chainId),
                        ",",
                        '"contract_address":"',
                        vm.toString(d.contractAddress),
                        '",',
                        '"day":"',
                        d.day,
                        '",',
                        '"block_number":',
                        vm.toString(d.blockNumber),
                        ",",
                        '"price":',
                        vm.toString(d.price),
                        "}"
                    );

                    vm.writeLine(c.outputPath, txJson);
                }
            }
            c.txNumber++;
            c.line = vm.readLine(c.inputPath);
        }
        vm.closeFile(c.inputPath);
        vm.closeFile(c.outputPath);
    }
}
