pragma solidity ^0.8.10;

contract Auth {
    mapping(address => bool) public wards;

    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = true;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = false;
        emit Deny(usr);
    }

    modifier auth() {
        require(wards[msg.sender], "not-authorized");
        _;
    }
}
