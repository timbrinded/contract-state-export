// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {SampleContract} from "../src/SampleContract.sol";
import {Counter} from "../src/Counter.sol";
import {TimboTest} from "../src/TimboTest.sol";

contract DeployScript is Script {
    function run() external {
        vm.startStateDiffRecording();
        uint256 deployerPrivateKey = 0xbcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31;

        vm.startBroadcast(deployerPrivateKey);

        SampleContract sample = new SampleContract();

        Counter counter = new Counter();
        counter.setNumber(100);
        sample.incrementCounter();
        sample.setBalance(0xE25583099BA105D9ec0A67f5Ae86D90e50036425, 500);
        sample.addAddress(0x614561D2d143621E126e87831AEF287678B442b8);
        sample.setUser(0xf93Ee4Cf8c6c40b329b0c0626F28333c132CF241, "Alice", 25, true);
        sample.setNestedMapping(1, 0x802dCbE1B1A97554B4F50DB5119E37E8e7336417, true);

        TimboTest timboTest = new TimboTest();
        timboTest.decrement();

        vm.stopBroadcast();

        console.log("Deployed contract at:", address(sample));
        console.log("TimboTest deployed at:", address(timboTest));

        Vm.AccountAccess[] memory records = vm.stopAndReturnStateDiff();
        console.log("\n=== STATE DIFF RECORDING ===");
        console.log("Total state changes recorded:", records.length);

        string memory output = _buildSimplifiedJson(records);

        vm.writeJson(output, "./state-diff.json");
    }

    function _buildSimplifiedJson(Vm.AccountAccess[] memory records) internal returns (string memory) {
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
                for (uint256 j = records.length - 1; ; j--) {
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
}
