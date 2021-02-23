pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract HodlTokens {

    address public owner;

      constructor (address _owner) {
        owner = _owner;
    }

    uint256 panicWithdrawalFee = 15;

    event Hodl(address indexed hodler, address token, uint256 amount, uint256 timeLimit);

    event PanicWithdraw(address indexed hodler, address token, uint256 amount, uint256 timediff);

    event Withdrawal(address indexed hodler, address token, uint256 amount);

    struct Hodler {
        address hodlerAddress;
        mapping(address => Token) tokens;
    }

    struct Token {
        uint256 balance;
        address tokenAddress;
        uint256 timeLimit;
    }

    mapping(address => Hodler) public hodlers;

    function hodlDeposit(
        address token,
        uint256 amount,
        uint256 timeLimit
    ) public {
        Hodler storage hodler = hodlers[msg.sender];
        hodler.hodlerAddress = msg.sender;

        hodlers[msg.sender].tokens[token] = Token(amount, token, timeLimit);

        ERC20(token).transferFrom(msg.sender, address(this), amount);
        Hodl(msg.sender, token, amount, timeLimit);
    }

    //TODO These two functions should be the same or the malicious user could manually withdraw
    //without time passing by calling this function directly

    function withdraw(address token) public {
        Hodler storage hodler = hodlers[msg.sender];
        require(block.timestamp > hodler.tokens[token].timeLimit, "Unlock time not reached yet.");

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
        hodlers[address(this)].tokens[token].balance = feeAmount;

        ERC20(token).transfer(msg.sender, withdrawalAmount);

        PanicWithdraw(msg.sender, token, withdrawalAmount, hodler.tokens[token].timeLimit - block.timestamp);
    }

    function claimFees() public {
        //
    }

}
