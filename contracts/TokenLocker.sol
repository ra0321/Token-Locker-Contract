pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract TokenLocker {
    address public owner;
    uint256 panicWithdrawalFee = 15;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only available to the contract owner.");
        _;
    }

    event Hodl(address indexed hodler, address token, uint256 amount, uint256 unlockTime);

    event PanicWithdraw(address indexed hodler, address token, uint256 amount, uint256 timediff);

    event Withdrawal(address indexed hodler, address token, uint256 amount);

    event FeesClaimed();

    struct Hodler {
        address hodlerAddress;
        mapping(address => Token) tokens;
    }

    struct Token {
        uint256 balance;
        address tokenAddress;
        uint256 unlockTime;
    }

    mapping(address => Hodler) public hodlers;

    function hodlDeposit(
        address token,
        uint256 amount,
        uint256 unlockTime
    ) public {
        Hodler storage hodler = hodlers[msg.sender];
        hodler.hodlerAddress = msg.sender;

        hodlers[msg.sender].tokens[token] = Token(amount, token, unlockTime);

        ERC20(token).transferFrom(msg.sender, address(this), amount);
        Hodl(msg.sender, token, amount, unlockTime);
    }

    function withdraw(address token) public {
        Hodler storage hodler = hodlers[msg.sender];
        require(block.timestamp > hodler.tokens[token].unlockTime, "Unlock time not reached yet.");

        uint256 amount = hodler.tokens[token].balance;
        hodler.tokens[token].balance = 0;
        ERC20(token).transfer(msg.sender, amount);

        Withdrawal(msg.sender, token, amount);
    }

    function panicWithdraw(address token) public {
        Hodler storage hodler = hodlers[msg.sender];
        hodler.hodlerAddress = msg.sender;

        uint256 feeAmount = (hodler.tokens[token].balance / 100) * panicWithdrawalFee;
        uint256 withdrawalAmount = hodler.tokens[token].balance - feeAmount;

        hodler.tokens[token].balance = 0;
        //Transfers fees to the contract administrator/owner
        hodlers[address(owner)].tokens[token].balance = feeAmount;

        ERC20(token).transfer(msg.sender, withdrawalAmount);

        PanicWithdraw(msg.sender, token, withdrawalAmount, hodler.tokens[token].unlockTime - block.timestamp);
    }

    function claimFees(address[] memory tokenList) public onlyOwner {
        for (uint256 i = 0; i < tokenList.length; i++) {
            uint256 amount = hodlers[owner].tokens[tokenList[i]].balance;
            if (amount > 0) {
                ERC20(tokenList[i]).transfer(owner, amount);
                hodlers[owner].tokens[tokenList[i]].balance = 0;
            }
        }
        FeesClaimed();
    }
}
