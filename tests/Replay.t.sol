// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
// import { console } from "forge-std/console.sol";
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

// struct Action {
//     address user;
//     string action;
//     uint256 amount;
//     uint256 poolTotalBalance;
//     uint8 decimals;
//     address token;
//     string blockTime;
//     uint256 blockNumber;
//     uint256 txIndex;
//     uint256 index;
//     bytes32 txHash;
//     address contractAddress;
// }

enum ActionType {
    Unknown,
    Deposit,
    Withdraw,
    Reward,
    Claim
}

struct Action {
    bytes32 txHash;
    address user;
    // ActionType action;
    uint256 amount;
}

struct Actions {
    Action[] actions;
}

contract ReplayTest is Test {
    using Reader for Vm;

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
    // Action[] public actions;

    // function parseAction(
    //     string memory json,
    //     string memory key
    // ) internal pure returns (Action memory a) {
    //     a.user = vm.parseJsonAddress(string.concat(key, ".user"), json);
    //     a.action = vm.parseJsonString(string.concat(key, ".action"), json);
    //     a.amount = vm.parseJsonUint(string.concat(key, ".amount"), json);
    //     a.poolTotalBalance = vm.parseJsonUint(
    //         string.concat(key, ".pool_total_balance"),
    //         json
    //     );
    //     a.decimals = uint8(
    //         vm.parseJsonUint(string.concat(key, ".decimals"), json)
    //     );
    //     a.token = vm.parseJsonAddress(string.concat(key, ".token"), json);
    //     a.blockTime = vm.parseJsonString(
    //         string.concat(key, ".block_time"),
    //         json
    //     );
    //     a.blockNumber = vm.parseJsonUint(
    //         string.concat(key, ".block_number"),
    //         json
    //     );
    //     a.txIndex = vm.parseJsonUint(string.concat(key, ".tx_index"), json);
    //     a.index = vm.parseJsonUint(string.concat(key, ".index"), json);
    //     a.txHash = vm.parseJsonBytes32(string.concat(key, ".tx_hash"), json);
    //     a.contractAddress = vm.parseJsonAddress(
    //         string.concat(key, ".contract_address"),
    //         json
    //     );
    // }

    function setUp() public {
        // Set up your fork
        rpc = "https://api.avax.network/ext/bc/C/rpc";
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
    }

    function testReplayInit() public {
        vm.rollFork(forkId, txHashFirstDeposit);

        assertEq(rp.asset(), aToken, "Asset address mismatch");
        assertEq(
            rp.totalSupply(),
            0,
            "Total supply should be zero at initialization"
        );
        assertEq(
            rp.balanceOf(userMostActive),
            0,
            "Balance should be zero at initialization"
        );
        assertEq(
            rp.unlockedBalanceOf(userMostActive),
            0,
            "Unlocked balance should be zero at initialization"
        );
    }

    function testReplayFirstDeposit() public {
        vm.rollFork(forkId, txHashFirstDeposit);
        assertEq(
            rp.totalSupply(),
            0,
            "Total supply should be zero before first deposit"
        );
        vm.transact(forkId, txHashFirstDeposit);
        assertEq(
            rp.totalSupply(),
            16_725_000_000_000_000_000, // First deposit amount
            "Total supply should be updated after deposit"
        );
    }

    function testReplayFirstReward() public {
        vm.rollFork(forkId, txHashFirstReward);
        uint256 initialBalance = IERC20(baseToken).balanceOf(address(rp));
        assertEq(
            initialBalance,
            0,
            "Initial reward token balance should be zero"
        );
        vm.transact(forkId, txHashFirstReward);
        uint256 finalBalance = IERC20(baseToken).balanceOf(address(rp));
        assertGt(
            finalBalance,
            1_659_468_307_695_490_000, // First reward amount
            "Final reward token balance should equal first reward amount"
        );
    }

    function testReplayStorageRead() public {
        // vm.rollFork(forkId, txHashFirstReward);
        vm.rollFork(forkId, txHashes[1]);

        console.log("totalSupply:", rp.totalSupply());
        // console.log("balanceOf(userMostActive):", rp.balanceOf(userMostActive));
        // console.log("unlockedBalanceOf(userMostActive):", rp.unlockedBalanceOf(userMostActive));
        // console.log("claimable(userMostActive, baseToken):", rp.claimable(userMostActive, baseToken));
        // console.log("baseToken balance:", IERC20(baseToken).balanceOf(address(rp)));
        assertEq(
            vm.treasury(address(rp)),
            treasury,
            "Treasury address mismatch"
        );
        assertEq(vm.market(address(rp)), market, "Market address mismatch");
        assertEq(
            vm.baseToken(address(rp)),
            baseToken,
            "Base token address mismatch"
        );
        assertEq(vm.asset(address(rp)), aToken, "Asset address mismatch");
        assertEq(
            rp.totalSupply(),
            vm.totalSupply(address(rp)),
            "Total supply mismatch"
        );

        address[] memory extraRewardTokens = vm.extraRewards(address(rp));
        for (uint256 i = 0; i < extraRewardTokens.length; i++) {
            console.log("Extra reward token:", extraRewardTokens[i]);
        }
        assertGt(extraRewardTokens.length, 0, "No extra reward tokens found");

        Reader.EpochState memory epochState = vm.epochState(address(rp));
        console.log("Epoch:", epochState.epoch);
        console.log("Scale:", epochState.scale);
        console.log("Prod:", epochState.prod);

        Reader.UserSnapshot memory userSnapshot = vm.userSnapshot(
            address(rp),
            userMostActive
        );
        assertEq(
            rp.balanceOf(userMostActive),
            userSnapshot.initialDeposit,
            "User deposit mismatch"
        );
        console.log("User initialDeposit:", userSnapshot.initialDeposit);
        console.log(
            "User initialUnlock.amount:",
            userSnapshot.initialUnlock.amount
        );
        console.log("User epoch.epoch:", userSnapshot.epoch.epoch);
        console.log("User epoch.scale:", userSnapshot.epoch.scale);
        console.log("User epoch.prod:", userSnapshot.epoch.prod);
        console.log(
            "User baseReward.pending:",
            userSnapshot.baseReward.pending
        );
        console.log(
            "User baseReward.accRewardsPerStake:",
            userSnapshot.baseReward.accRewardsPerStake
        );
        console.log(
            "User extraRewards[baseToken].pending:",
            userSnapshot.extraRewards[0].pending
        );
        console.log(
            "User extraRewards[baseToken].accRewardsPerStake:",
            userSnapshot.extraRewards[0].accRewardsPerStake
        );
    }

    // function testReplayToNDJSON() public {
    //     string memory path = string.concat(
    //         vm.projectRoot(),
    //         "/tests/data/tx_hashes_users.ndjson"
    //     );

    //     string memory line;
    //     bytes32 txHash;
    //     bytes32 oldTxHash;
    //     uint256 txNumber = 1005; // Overall transaction counter
    //     uint256 txCount = 1000;
    //     uint256 txStop = txNumber + txCount; // Stop after txCount transactions
    //     uint256 txCounter = 1;

    //     // Skip lines up to txNumber
    //     while (txCounter <= txNumber) {
    //         line = vm.readLine(path);
    //         if (bytes(line).length == 0) {
    //             console.log("Reached end of file before txNumber", txNumber);
    //             return; // Exit if file ends before txNumber
    //         }
    //         txHash = bytes32(vm.parseJson(line, "$.tx_hash"));
    //         if (txHash == oldTxHash) continue; // Skip duplicate tx_hashes
    //         oldTxHash = txHash; // Update oldTxHash to current txHash
    //         txCounter++; // Increment transaction counter
    //     }

    //     // Process lines from txNumber to txStop
    //     oldTxHash = bytes32(0); // Reset oldTxHash for new processing
    //     while (true) {
    //         if (bytes(line).length == 0 || txNumber >= txStop) break; // End of file or exceeded txStop

    //         // Parse the line into tx_hash and user
    //         txHash = bytes32(vm.parseJson(line, "$.tx_hash"));
    //         if (txHash == oldTxHash) continue; // Skip duplicate tx_hashes
    //         user = vm.parseJsonAddress(line, "$.user");
    //         // console.log("Processing tx_hash:", vm.toString(txHash));
    //         // console.log("for user:", vm.toString(user));
    //         // console.log("at tx_number:", txNumber);

    //         uint256 chainId = 43114; // Avalanche mainnet chain ID

    //         vm.rollFork(forkId, txHash);

    //         // Capture pre-state in Cache using writeStateCache
    //         Reader.StateCache memory preCache = Reader.writeStateCache(
    //             vm,
    //             address(rp),
    //             user
    //         );

    //         // Replay the transaction
    //         vm.transact(forkId, txHash);

    //         // Capture post-state in Cache using writeStateCache
    //         Reader.StateCache memory postCache = Reader.writeStateCache(
    //             vm,
    //             address(rp),
    //             user
    //         );

    //         // Construct and write NDJSON line with user address
    //         string memory txJson = string.concat(
    //             "{",
    //             '"tx_number":',
    //             vm.toString(txNumber),
    //             ",",
    //             '"tx_hash":"',
    //             vm.toString(txHash),
    //             '",',
    //             '"user":"',
    //             vm.toString(address(user)), // Added user address
    //             '",',
    //             '"chain_id":',
    //             vm.toString(chainId),
    //             ",",
    //             '"pre_state":',
    //             preCache.stateJson,
    //             ",",
    //             '"post_state":',
    //             postCache.stateJson,
    //             "}"
    //         );

    //         vm.writeLine("output.ndjson", txJson);

    //         oldTxHash = txHash; // Update oldTxHash to current txHash
    //         txNumber++; // Increment transaction counter
    //         line = vm.readLine(path);
    //     }

    //     vm.closeFile(path); // Close the file to reset offset for future reads
    // }

    // function testReplayAllHashes() public {
    //     // for (uint256 i = 0; i < txHashes.length; i++) {
    //     uint256 istart = 250;
    //     uint256 icount = 250;
    //     for (uint256 i = istart; i < istart + icount; i++) {
    //         bytes32 txHash = txHashes[i];
    //         vm.rollFork(forkId, txHash);
    //         console.log("--------------");
    //         console.log("block_number:", vm.getBlockNumber());
    //         console.log("user_deposits (before):", rp.balanceOf(user));
    //         console.log("user_unlocked (before):", rp.unlockedBalanceOf(user));
    //         console.log("total_deposits (before):", rp.totalSupply());
    //         console.log(
    //             "total_rewards (before):",
    //             IERC20(baseToken).balanceOf(address(rp))
    //         );
    //         if (i > 0) {
    //             console.log(
    //                 "claimable_rewards (before):",
    //                 rp.claimable(user, baseToken)
    //             );
    //         }
    //         vm.transact(forkId, txHash);
    //         console.log("user_deposits (after):", rp.balanceOf(user));
    //         console.log("user_unlocked (after):", rp.unlockedBalanceOf(user));
    //         console.log("total_deposits (after):", rp.totalSupply());
    //         console.log(
    //             "total_rewards (after):",
    //             IERC20(baseToken).balanceOf(address(rp))
    //         );
    //         console.log(
    //             "claimable_rewards (after):",
    //             rp.claimable(user, baseToken)
    //         );
    //     }
    // }
}
