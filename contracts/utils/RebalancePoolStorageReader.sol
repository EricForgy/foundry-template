// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Vm.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

library RebalancePoolStorageReader {
    struct RewardState {
        uint256 rate;
        uint32 periodLength;
        uint48 lastUpdate;
        uint48 finishAt;
        uint256 queued;
    }

    struct EpochState {
        uint64 epoch;
        uint64 scale;
        uint128 prod;
    }

    struct UserUnlock {
        uint256 amount;
        uint256 unlockAt;
    }

    struct UserRewardSnapshot {
        uint256 pending;
        uint256 accRewardsPerStake;
    }

    struct UserSnapshot {
        uint256 initialDeposit;
        UserUnlock initialUnlock;
        EpochState epoch;
        UserRewardSnapshot baseReward;
        UserRewardSnapshot[] extraRewards; // Array for extra rewards
    }

    function writeJson(
        Vm vm,
        address[] memory a
    ) internal pure returns (string memory) {
        if (a.length == 0) {
            return "[]";
        }

        // Initialize with opening bracket
        string memory json = "[";

        // Build array elements
        for (uint256 i = 0; i < a.length; i++) {
            json = string.concat(json, '"', vm.toString(a[i]), '"');
            if (i < a.length - 1) {
                json = string.concat(json, ",");
            }
        }

        // Close the array
        json = string.concat(json, "]");
        return json;
    }

    function writeJson(
        Vm vm,
        RewardState memory r
    ) internal pure returns (string memory) {
        return
            string.concat(
                "{",
                '"rate":',
                vm.toString(r.rate),
                ",",
                '"periodLength":',
                vm.toString(r.periodLength),
                ",",
                '"lastUpdate":',
                vm.toString(r.lastUpdate),
                ",",
                '"finishAt":',
                vm.toString(r.finishAt),
                ",",
                '"queued":',
                vm.toString(r.queued),
                "}"
            );
    }

    function writeJson(
        Vm vm,
        EpochState memory e
    ) internal pure returns (string memory) {
        return
            string.concat(
                "{",
                '"epoch":',
                vm.toString(e.epoch),
                ",",
                '"scale":',
                vm.toString(e.scale),
                ",",
                '"prod":',
                vm.toString(e.prod),
                "}"
            );
    }

    function writeJson(
        Vm vm,
        UserUnlock memory u
    ) internal pure returns (string memory) {
        return
            string.concat(
                "{",
                '"amount":',
                vm.toString(u.amount),
                ",",
                '"unlockAt":',
                vm.toString(u.unlockAt),
                "}"
            );
    }

    function writeJson(
        Vm vm,
        UserRewardSnapshot memory r
    ) internal pure returns (string memory) {
        return
            string.concat(
                "{",
                '"pending":',
                vm.toString(r.pending),
                ",",
                '"accRewardsPerStake":',
                vm.toString(r.accRewardsPerStake),
                "}"
            );
    }

    function writeJson(
        Vm vm,
        UserSnapshot memory s
    ) internal pure returns (string memory) {
        return
            string.concat(
                "{",
                '"initialDeposit":',
                vm.toString(s.initialDeposit),
                ",",
                '"initialUnlock":',
                writeJson(vm, s.initialUnlock),
                ",",
                '"epoch":',
                writeJson(vm, s.epoch),
                ",",
                '"baseReward":',
                writeJson(vm, s.baseReward),
                "}"
            );
    }

    function loadUint256(
        Vm vm,
        address target,
        uint256 slot
    ) internal view returns (uint256 value) {
        bytes32 raw = _load(vm, target, slot);
        return uint256(raw);
    }

    function loadAddress(
        Vm vm,
        address target,
        uint256 slot
    ) internal view returns (address value) {
        bytes32 raw = _load(vm, target, slot);
        return address(uint160(uint256(raw)));
    }

    function loadBool(
        Vm vm,
        address target,
        uint256 slot,
        uint256 offset
    ) internal view returns (bool value) {
        require(offset < 32, "Offset out of bounds");
        bytes32 raw = _load(vm, target, slot);
        uint8 bit = uint8(uint256(raw) >> (offset * 8)); // Shift by byte
        return bit != 0;
    }

    function _load(
        Vm vm,
        address target,
        uint256 slot
    ) private view returns (bytes32 value) {
        return vm.load(target, bytes32(slot));
    }

    function initialized(Vm vm, address target) internal view returns (bool) {
        return loadBool(vm, target, 0, 0);
    }

    function initializing(Vm vm, address target) internal view returns (bool) {
        return loadBool(vm, target, 0, 1);
    }

    function owner(Vm vm, address target) internal view returns (address) {
        return loadAddress(vm, target, 51);
    }

    function treasury(Vm vm, address target) internal view returns (address) {
        return loadAddress(vm, target, 101);
    }

    function market(Vm vm, address target) internal view returns (address) {
        return loadAddress(vm, target, 102);
    }

    function baseToken(Vm vm, address target) internal view returns (address) {
        return loadAddress(vm, target, 103);
    }

    function asset(Vm vm, address target) internal view returns (address) {
        return loadAddress(vm, target, 104);
    }

    function totalSupply(
        Vm vm,
        address target
    ) internal view returns (uint256) {
        return loadUint256(vm, target, 105);
    }

    function totalUnlocking(
        Vm vm,
        address target
    ) internal view returns (uint256) {
        return loadUint256(vm, target, 106);
    }

    function liquidator(Vm vm, address target) internal view returns (address) {
        return loadAddress(vm, target, 107);
    }

    function liquidatableCollateralRatio(
        Vm vm,
        address target
    ) internal view returns (uint256) {
        return loadUint256(vm, target, 108);
    }

    function wrapper(Vm vm, address target) internal view returns (address) {
        return loadAddress(vm, target, 109);
    }

    function extraRewards(
        Vm vm,
        address target
    ) internal view returns (address[] memory addrs) {
        uint256 slot = 110;

        uint256 length = uint256(vm.load(target, bytes32(slot)));
        addrs = new address[](length);

        bytes32 base = keccak256(abi.encodePacked(uint256(slot)));

        for (uint256 i = 0; i < length; i++) {
            bytes32 elementSlot = bytes32(uint256(base) + i);
            addrs[i] = address(uint160(uint256(vm.load(target, elementSlot))));
        }
    }

    function epochState(
        Vm vm,
        address target
    ) internal view returns (EpochState memory e) {
        uint256 baseSlot = 115; // Use uint256 for clarity
        bytes32 word = _load(vm, target, baseSlot);

        e.epoch = uint64(uint256(word));
        e.scale = uint64(uint256(word) >> 64);
        e.prod = uint128(uint256(word) >> 128);
    }

    function userSnapshot(
        Vm vm,
        address target,
        address user
    ) internal view returns (UserSnapshot memory s) {
        uint256 baseSlot = uint256(keccak256(abi.encode(user, uint256(116)))); // Consistent abi.encode
        s.initialDeposit = loadUint256(vm, target, baseSlot);
        s.initialUnlock.amount = loadUint256(vm, target, baseSlot + 1);
        s.initialUnlock.unlockAt = loadUint256(vm, target, baseSlot + 2);

        bytes32 epochWord = _load(vm, target, baseSlot + 3);
        s.epoch.epoch = uint64(uint256(epochWord));
        s.epoch.scale = uint64(uint256(epochWord) >> 64);
        s.epoch.prod = uint128(uint256(epochWord) >> 128);

        s.baseReward.pending = loadUint256(vm, target, baseSlot + 4);
        s.baseReward.accRewardsPerStake = loadUint256(vm, target, baseSlot + 5);

        address[] memory extraRewardsList = extraRewards(vm, target);
        s.extraRewards = new UserRewardSnapshot[](extraRewardsList.length);
        for (uint256 i = 0; i < extraRewardsList.length; i++) {
            s.extraRewards[i] = extraRewardSnapshot(
                vm,
                target,
                user,
                extraRewardsList[i]
            );
        }
    }

    function extraRewardSnapshot(
        Vm vm,
        address target,
        address user,
        address rewardToken
    ) internal view returns (UserRewardSnapshot memory r) {
        uint256 userBaseSlot = uint256(
            keccak256(abi.encode(user, uint256(116))) // Changed to abi.encode
        );
        uint256 extraRewardsFieldOffset = 6;
        uint256 mappingSlot = uint256(
            keccak256(
                abi.encode( // Changed to abi.encode
                        rewardToken,
                        uint256(userBaseSlot + extraRewardsFieldOffset)
                    )
            )
        );

        r.pending = uint256(_load(vm, target, mappingSlot));
        r.accRewardsPerStake = uint256(_load(vm, target, mappingSlot + 1));
    }

    function readRewardState(
        Vm vm,
        address target,
        address rewardToken
    ) internal view returns (RewardState memory r) {
        bytes32 baseSlot = keccak256(
            abi.encode(rewardToken, uint256(112)) // Changed to abi.encode
        );
        bytes32 word0 = _load(vm, target, uint256(baseSlot));
        bytes32 word1 = _load(vm, target, uint256(baseSlot) + 1);

        r.rate = uint256(word0);
        r.periodLength = uint32(uint256(word1));
        r.lastUpdate = uint48(uint256(word1) >> 32);
        r.finishAt = uint48(uint256(word1) >> 80);
        r.queued = uint256(_load(vm, target, uint256(baseSlot) + 2));
    }

    // Cache struct to hold all state variables
    struct StateCache {
        uint256 totalSupply;
        uint256 totalReward;
        EpochState epoch;
        RewardState baseReward;
        UserSnapshot userSnap;
        address[] extraRewards;
        string stateJson; // To store the final JSON string
    }

    function writeStateCache(
        Vm vm,
        address target,
        address user
    ) internal view returns (StateCache memory cache) {
        address rewardToken = baseToken(vm, target);
        cache.totalSupply = totalSupply(vm, target);
        cache.epoch = epochState(vm, target);
        cache.baseReward = readRewardState(vm, target, rewardToken);
        cache.userSnap = userSnapshot(vm, target, user);
        cache.extraRewards = extraRewards(vm, target);
        cache.stateJson = string.concat(
            "{",
            '"totalDeposit":',
            vm.toString(cache.totalSupply),
            ",",
            '"totalReward":',
            vm.toString(IERC20(rewardToken).balanceOf(target)),
            ",",
            '"epoch":',
            writeJson(vm, cache.epoch),
            ",",
            '"baseReward":',
            writeJson(vm, cache.baseReward),
            ",",
            '"userSnapshot":',
            writeJson(vm, cache.userSnap),
            ",",
            '"extraRewards":',
            writeJson(vm, cache.extraRewards),
            "}"
        );

    }
}
