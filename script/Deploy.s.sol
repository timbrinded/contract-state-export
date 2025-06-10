// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console} from "forge-std/Script.sol";
import {TrackedState} from "./TrackedState.sol";
import {SampleContract} from "../src/SampleContract.sol";
import {Counter} from "../src/Counter.sol";
import {TimboTest} from "../src/TimboTest.sol";

contract DeployScript is TrackedState {
    function run() external withStateDiff {
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
    }
}
