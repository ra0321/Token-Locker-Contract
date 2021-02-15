pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract HodlTokensForYouContract {
    event Hodl(address indexed hodler, address token, uint256 amount, uint256 timeLimit);

    event PanicWithdraw(address indexed hodler, address token, uint256 amount, uint256 timediff);

    event Withdrawal(address indexed hodler, address token, uint256 amount);

    struct Hodler {
        address hodlerAddress;
        mapping(address => Token) tokens;
    }

    struct Token {
        bytes32 symbol;
        uint256 balance;
        address tokenAddress;
        uint256 timeLimit;
    }

    uint256 panicWithdrawalFee = 15;

    mapping(address => Hodler) public hodlers;

    function hodlDeposit(
        address token,
        bytes1 tokenSymbol,
        uint256 amount,
        uint256 timeLimit
    ) public {
        Hodler storage hodler = hodlers[msg.sender];
        hodler.hodlerAddress = msg.sender;

        hodlers[msg.sender].tokens[token] = Token(tokenSymbol, amount, token, timeLimit);

        ERC20(token).transferFrom(msg.sender, address(this), amount);
        Hodl(msg.sender, token, amount, timeLimit);
    }

    function withdraw(address token) public {
        Hodler storage hodler = hodlers[msg.sender];
        require(block.timestamp > hodler.tokens[token].timeLimit, "Unlock time not reached yet.");

        uint256 amount = hodler.tokens[token].balance;
        hodler.tokens[token].balance = 0;
        ERC20(token).transfer(msg.sender, amount);

        Withdrawal(msg.sender, token, amount);
    }

    //TODO add amount param to allow user to pick how much he wants to withdraw
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
}
