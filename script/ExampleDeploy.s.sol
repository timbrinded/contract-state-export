// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console} from "forge-std/Script.sol";
import {TrackedState} from "./TrackedState.sol";
import {Counter} from "../src/Counter.sol";

contract ExampleDeployScript is TrackedState {
    function run() external withStateDiff {
        setStateDiffFilename("./timbo.json");
        
        vm.startBroadcast();
        
        Counter counter1 = new Counter();
        counter1.setNumber(42);
        
        Counter counter2 = new Counter();
        counter2.setNumber(100);
        
        vm.stopBroadcast();
        
        console.log("Counter 1 deployed at:", address(counter1));
        console.log("Counter 2 deployed at:", address(counter2));
    }
  
}