// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SampleContract {
    // State variables to demonstrate various storage patterns
    uint256 public counter = 42;
    mapping(address => uint256) public balances;
    mapping(uint256 => mapping(address => bool)) public nestedMapping;
    address[] public addresses;
    
    struct User {
        string name;
        uint256 age;
        bool active;
    }
    
    mapping(address => User) public users;
    
    // Events
    event CounterIncremented(uint256 newValue);
    event BalanceUpdated(address indexed user, uint256 newBalance);
    
    constructor() {
        // Initialize some state
        balances[msg.sender] = 1000;
        addresses.push(msg.sender);
        users[msg.sender] = User("Admin", 30, true);
    }
    
    function incrementCounter() public {
        counter++;
        emit CounterIncremented(counter);
    }
    
    function setBalance(address user, uint256 amount) public {
        balances[user] = amount;
        emit BalanceUpdated(user, amount);
    }
    
    function addAddress(address addr) public {
        addresses.push(addr);
    }
    
    function setUser(address addr, string memory name, uint256 age, bool active) public {
        users[addr] = User(name, age, active);
    }
    
    function setNestedMapping(uint256 id, address addr, bool value) public {
        nestedMapping[id][addr] = value;
    }
    
    function getAddressCount() public view returns (uint256) {
        return addresses.length;
    }
}