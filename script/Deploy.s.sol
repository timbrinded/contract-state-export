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
        string memory json = _buildSimplifiedJson(records);
        
        // Output JSON to console
        console.log("\n=== STATE DIFF JSON START ===");
        console.log(json);
        console.log("=== STATE DIFF JSON END ===");
    }
    
    function _buildSimplifiedJson(Vm.AccountAccess[] memory records) internal pure returns (string memory) {
        // Track unique contracts and their final storage
        address[] memory contracts = new address[](records.length);
        uint contractCount = 0;
        
        // First pass: identify unique contracts that were deployed
        for (uint i = 0; i < records.length; i++) {
            // Kind 4 is Create
            if (uint(records[i].kind) == 4) {
                bool found = false;
                for (uint j = 0; j < contractCount; j++) {
                    if (contracts[j] == records[i].account) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    contracts[contractCount] = records[i].account;
                    contractCount++;
                }
            }
        }
        
        // Build JSON
        string memory json = "[";
        for (uint i = 0; i < contractCount; i++) {
            if (i > 0) json = string.concat(json, ",");
            json = string.concat(json, _serializeContract(contracts[i], records));
        }
        json = string.concat(json, "]");
        
        return json;
    }
    
    function _serializeContract(address contractAddr, Vm.AccountAccess[] memory records) internal pure returns (string memory) {
        string memory result = "{";
        result = string.concat(result, '"address":"', vm.toString(contractAddr), '",');
        
        // Find the deployment record to get the code
        bytes memory deployedCode;
        for (uint i = 0; i < records.length; i++) {
            if (records[i].account == contractAddr && uint(records[i].kind) == 4) {
                deployedCode = records[i].deployedCode;
                break;
            }
        }
        
        result = string.concat(result, '"code":"0x', vm.toString(deployedCode), '",');
        
        // Collect all unique storage slots and their final values
        result = string.concat(result, '"storage":{');
        
        // Track processed slots to avoid duplicates
        bytes32[] memory processedSlots = new bytes32[](100);
        uint slotCount = 0;
        bool firstSlot = true;
        
        // Process all storage accesses for this contract in reverse order to get final values
        for (uint i = records.length; i > 0; i--) {
            uint idx = i - 1;
            if (records[idx].account == contractAddr) {
                for (uint j = 0; j < records[idx].storageAccesses.length; j++) {
                    Vm.StorageAccess memory access = records[idx].storageAccesses[j];
                    if (access.isWrite && !access.reverted) {
                        // Check if we've already processed this slot
                        bool alreadyProcessed = false;
                        for (uint k = 0; k < slotCount; k++) {
                            if (processedSlots[k] == access.slot) {
                                alreadyProcessed = true;
                                break;
                            }
                        }
                        
                        if (!alreadyProcessed && access.newValue != bytes32(0)) {
                            if (!firstSlot) result = string.concat(result, ",");
                            result = string.concat(result, '"', vm.toString(access.slot), '":"', vm.toString(access.newValue), '"');
                            processedSlots[slotCount] = access.slot;
                            slotCount++;
                            firstSlot = false;
                        }
                    }
                }
            }
        }
        
        result = string.concat(result, "}}");
        return result;
    }
}