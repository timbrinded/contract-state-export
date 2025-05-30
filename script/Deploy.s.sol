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
        // Using the first pre-funded account from Kurtosis
        uint256 deployerPrivateKey = 0xbcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31;

        vm.startBroadcast(deployerPrivateKey);

        SampleContract sample = new SampleContract();

        Counter counter = new Counter();
        counter.setNumber(100);
        // Perform some transactions to populate state
        sample.incrementCounter();
        sample.setBalance(0xE25583099BA105D9ec0A67f5Ae86D90e50036425, 500);
        sample.addAddress(0x614561D2d143621E126e87831AEF287678B442b8);
        sample.setUser(0xf93Ee4Cf8c6c40b329b0c0626F28333c132CF241, "Alice", 25, true);
        sample.setNestedMapping(1, 0x802dCbE1B1A97554B4F50DB5119E37E8e7336417, true);

        // Deploy the TimboTest contract
        TimboTest timboTest = new TimboTest();
        timboTest.decrement();

        vm.stopBroadcast();

        // Log the deployed contract address
        console.log("Deployed contract at:", address(sample));
        console.log("TimboTest deployed at:", address(timboTest));

        // Get and log state diffs
        Vm.AccountAccess[] memory records = vm.stopAndReturnStateDiff();
        console.log("\n=== STATE DIFF RECORDING ===");
        console.log("Total state changes recorded:", records.length);

        // Build simplified JSON with contract data
        string memory output = _buildSimplifiedJson(records);

        // Write JSON to console since file writes are restricted
        console.log("\n=== STATE DIFF JSON START ===");
        console.log(output);
        console.log("=== STATE DIFF JSON END ===");
    }

    function _buildSimplifiedJson(Vm.AccountAccess[] memory records) internal pure returns (string memory) {
        // -------------------------------------------------- collect unique CREATEs
        address[] memory addrs = new address[](records.length);
        uint256 n;
        for (uint256 i = 0; i < records.length; i++) {
            if (uint256(records[i].kind) != 4) continue; // not a CREATE
            address a = records[i].account;
            bool seen;
            for (uint256 j = 0; j < n; j++) {
                if (addrs[j] == a) {
                    seen = true;
                    break;
                }
            }
            if (!seen) addrs[n++] = a;
        }

        // ------------------------------------------------ build JSON manually
        string memory json = "[";

        for (uint256 i = 0; i < n; i++) {
            if (i > 0) json = string.concat(json, ",");

            address c = addrs[i];
            json = string.concat(json, '{"address":"', vm.toString(c), '",');

            // Find deployment code
            bytes memory code;
            for (uint256 j = 0; j < records.length; j++) {
                if (records[j].account == c && uint256(records[j].kind) == 4) {
                    code = records[j].deployedCode;
                    break;
                }
            }
            json = string.concat(json, '"code":"', vm.toString(code), '",');

            // Build storage object
            json = string.concat(json, '"storage":{');
            bytes32[] memory done = new bytes32[](100);
            uint256 doneCnt;
            bool firstSlot = true;

            // Process storage accesses in reverse order to get final values
            for (uint256 j = records.length; j > 0; j--) {
                Vm.AccountAccess memory r = records[j - 1];
                if (r.account != c) continue;

                for (uint256 s = 0; s < r.storageAccesses.length; s++) {
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

                    if (!firstSlot) json = string.concat(json, ",");
                    json = string.concat(json, '"', vm.toString(a.slot), '":"', vm.toString(a.newValue), '"');
                    done[doneCnt++] = a.slot;
                    firstSlot = false;
                }
            }

            json = string.concat(json, "}}");
        }

        json = string.concat(json, "]");
        return json;
    }
}
