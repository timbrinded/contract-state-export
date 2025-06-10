// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

abstract contract TrackedState is Script {
    bool public recordStateDiff = true;
    string public stateDiffFilename = "./state-diff.json";

    modifier withStateDiff() {
        if (recordStateDiff) {
            vm.startStateDiffRecording();
        }
        _;
        if (recordStateDiff) {
            Vm.AccountAccess[] memory records = vm.stopAndReturnStateDiff();
            console.log("\n=== STATE DIFF RECORDING ===");
            console.log("Total state changes recorded:", records.length);

            exportStateDiff(vm, records, stateDiffFilename);
            console.log("State diff exported to:", stateDiffFilename);
        }
    }

    function setStateDiffFilename(string memory filename) public {
        stateDiffFilename = filename;
    }

    function disableStateDiff() public {
        recordStateDiff = false;
    }

    function buildSimplifiedJson(Vm vm, Vm.AccountAccess[] memory records) internal returns (string memory) {
        if (records.length == 0) {
            return vm.serializeString("contracts", "empty", "[]");
        }

        uint256 deploymentCount;
        for (uint256 i = 0; i < records.length; i++) {
            if (uint256(records[i].kind) == 4) deploymentCount++;
        }

        if (deploymentCount == 0) {
            return vm.serializeString("contracts", "empty", "[]");
        }

        address[] memory addrs = new address[](deploymentCount);
        bytes[] memory codes = new bytes[](deploymentCount);
        uint256 n;

        for (uint256 i = 0; i < records.length; i++) {
            if (uint256(records[i].kind) != 4) continue;
            address a = records[i].account;
            bool seen;
            for (uint256 j = 0; j < n; j++) {
                if (addrs[j] == a) {
                    seen = true;
                    break;
                }
            }
            if (!seen) {
                addrs[n] = a;
                codes[n] = records[i].deployedCode;
                n++;
            }
        }

        string memory jsonKey = "contracts";
        string memory finalJson = "";

        for (uint256 i = 0; i < n; i++) {
            address c = addrs[i];
            string memory contractKey = string.concat("contract_", vm.toString(i));

            vm.serializeAddress(contractKey, "address", c);
            vm.serializeBytes(contractKey, "code", codes[i]);

            string memory storageKey = string.concat(contractKey, "_storage");

            uint256 maxSlots = 200;
            bytes32[] memory done = new bytes32[](maxSlots);
            uint256 doneCnt;
            string memory storageJson = "";

            if (records.length > 0) {
                for (uint256 j = records.length - 1;; j--) {
                    Vm.AccountAccess memory r = records[j];
                    if (r.account != c) {
                        if (j == 0) break;
                        continue;
                    }

                    for (uint256 s = 0; s < r.storageAccesses.length; s++) {
                        if (doneCnt >= maxSlots) break;

                        Vm.StorageAccess memory a = r.storageAccesses[s];
                        if (!a.isWrite || a.reverted || a.newValue == bytes32(0)) continue;

                        bool dup;
                        for (uint256 d = 0; d < doneCnt; d++) {
                            if (done[d] == a.slot) {
                                dup = true;
                                break;
                            }
                        }
                        if (dup) continue;

                        storageJson = vm.serializeBytes32(storageKey, vm.toString(a.slot), a.newValue);
                        done[doneCnt++] = a.slot;
                    }

                    if (j == 0) break;
                }
            }

            string memory contractJson = vm.serializeString(contractKey, "storage", storageJson);

            if (i == n - 1) {
                finalJson = vm.serializeString(jsonKey, vm.toString(i), contractJson);
            } else {
                vm.serializeString(jsonKey, vm.toString(i), contractJson);
            }
        }

        return finalJson;
    }

    function exportStateDiff(Vm vm, Vm.AccountAccess[] memory records, string memory filename) internal {
        string memory json = buildSimplifiedJson(vm, records);
        vm.writeJson(json, filename);
    }
}
