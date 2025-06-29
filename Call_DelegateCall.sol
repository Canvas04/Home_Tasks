// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract DataManager {
    struct User {
        string name;
        uint256 age;
    }

    mapping(address => User) public users;
    address public datalogicContract;

    constructor(address _datalogicContract) {
        datalogicContract = _datalogicContract;
    }

    function setUser(
        address _userAddress,
        string memory _name,
        uint256 _age
    ) external {
        (bool success, ) = datalogicContract.delegatecall(
            abi.encodeWithSelector(
                DataLogic.setUserData.selector,
                _userAddress,
                _name,
                _age
            )
        );

        require(success, "SetUserData Failed");
    }

    function clearUserData(address _userAddress) external {
        (bool success, ) = datalogicContract.delegatecall(
            abi.encodeWithSelector(
                DataLogic.clearUserData.selector,
                _userAddress
            )
        );

        require(success, "ClearUserData Failed");
    }

    function getUserData(address _userAddress) external {
        (bool success, ) = datalogicContract.call(
            abi.encodeWithSelector(DataLogic.getUserData.selector, _userAddress)
        );

        require(success, "getUserData Failed");
    }

    function setNewDataManager(address _userAddress) external {
        (bool success, ) = datalogicContract.call(
            abi.encodeWithSelector(
                DataLogic.setNewUserDataManager.selector,
                _userAddress
            )
        );

        require(success, "getUserData Failed");
    }

    function setNewLogicContract(address _datalogicContract) external {
        datalogicContract = _datalogicContract;
    }
}

contract DataLogic {
    address public owner;
    struct User {
        string name;
        uint256 age;
    }

    event UserDataChanged(address, string, uint256);

    mapping(address => User) public users;

    function setUserData(
        address _userAddress,
        string memory _name,
        uint256 _age
    ) external {
        users[_userAddress] = User(_name, _age);

        emit UserDataChanged(_userAddress,_name,_age);
    }

    function clearUserData(address _userAddress) external {
        delete users[_userAddress];
    }

    function getUserData(address _userAddress)
        external
        view
        returns (User memory)
    {
        return users[_userAddress];
    }

    function setNewUserDataManager(address _owner) external {
        owner = _owner;
    }
}
