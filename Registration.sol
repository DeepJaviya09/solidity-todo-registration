// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import "hardhat/console.sol";

contract Registration {
    address[] public registeredAddresses;
    uint256 public totalRegisteredUsers;

    mapping (address=>bool) isUserRegistered;

    event UserRegistered(address indexed user);

    function register() public {
        require(!isUserRegistered[msg.sender], "Already registered");

        registeredAddresses.push(msg.sender);
        totalRegisteredUsers++;
        isUserRegistered[msg.sender] = true;
        emit UserRegistered(msg.sender);
    }

    function checkRegistration (address _addr) public view returns (bool) {
        return isUserRegistered[_addr];
    }
}

contract Todo {
    Registration public registrationContract;

    // Enum for Priority
    enum Priority { Low, Medium, High }

    // Enum for Status
    enum Status { Incomplete, Complete }

    // Struct for Todo item
    struct TodoItem {
        bytes32 id;
        string title;
        string description;
        Status status;
        Priority priority;
    }

    // Mapping from user address to their todos
    mapping(address => TodoItem[]) public userTodos;

    // Events for debugging and logging
    event TodoCreated(bytes32 indexed id, string title, string description, Status status, Priority priority);
    event TodoUpdated(bytes32 indexed id, string title, string description, Status status, Priority priority);
    event RegistrationContractSet(address indexed registrationContract);

    // Modifier to check if user is registered
    event LogAddress(address indexed user);

    modifier onlyRegisteredUser() {
        require(address(registrationContract) != address(0), "Registration contract not set");
        console.log(msg.sender);
        require(registrationContract.checkRegistration(msg.sender), "User not registered");
        _;
    }

    // Set the registration contract address
    function setRegistrationContract(address _registrationContractAddress) public {
        registrationContract = Registration(_registrationContractAddress);
        emit RegistrationContractSet(_registrationContractAddress);
    }

    // Create a new todo item
    function createTodo(string memory _title, string memory _description, Priority _priority) public onlyRegisteredUser {
        bytes32 todoId = keccak256(abi.encodePacked(msg.sender, block.timestamp, _title));
        TodoItem memory newTodo = TodoItem({
            id: todoId,
            title: _title,
            description: _description,
            status: Status.Incomplete,
            priority: _priority
        });

        userTodos[msg.sender].push(newTodo);

        emit TodoCreated(todoId, _title, _description, Status.Incomplete, _priority);
    }

    function updateTodo(bytes32 _id, string memory _title, string memory _description, Status _status, Priority _priority) public onlyRegisteredUser {
        TodoItem[] storage todos = userTodos[msg.sender];
        bool found = false;

        for (uint256 i = 0; i < todos.length; i++) {
            if (todos[i].id == _id) {
                todos[i].title = _title;
                todos[i].description = _description;
                todos[i].status = _status;
                todos[i].priority = _priority;
                found = true;

                emit TodoUpdated(_id, _title, _description, _status, _priority);
                break;
            }
        }

        require(found, "Todo item not found");
    }

    // Get todos for a specific user
    function getTodosByUser(address _user) public view returns (TodoItem[] memory) {
        return userTodos[_user];
    }
}
