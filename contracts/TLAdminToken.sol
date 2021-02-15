pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TLAdminToken is ERC20 {
    constructor() public ERC20("TLAdminToken", "TLAD") {}
}
