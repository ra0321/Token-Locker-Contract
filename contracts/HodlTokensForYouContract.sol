pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract HodlTokensForYouContract {

    event Hodl(address indexed hodler, address token, uint amount, uint timeLimit);

    event PanicSell(address indexed hodler, address token, uint amount, uint timediff);

    event Withdrawal(address indexed hodler, address token, uint amount);

    struct Hodler {
        address hodlerAddress;
        mapping(address => Token) tokens;
    }

    struct Token {
        bytes32 symbol;
        uint tokenBalance;
        address tokenAddress;
        uint timeLimit;
    }

    mapping(address => Hodler) public hodlers;

    function hodlDeposit(address token, byte tokenSymbol, uint256 amount, uint256 timeLimit) public {

        Hodler storage hodler = hodlers[msg.sender];
        hodler.hodlerAddress = msg.sender;

        hodlers[msg.sender].tokens[token] = Token(tokenSymbol, amount, token, timeLimit);

        ERC20(token).transferFrom(msg.sender, address(this), amount);
        Hodl(msg.sender, token, amount, timeLimit);

    }

    function withdraw(address token) public {
        Hodler storage hodler = hodlers[msg.sender];
        require(block.timestamp > hodler.tokens[token].timeLimit);

        uint amount = hodler.tokens[token].tokenBalance;
        hodler.tokens[token].tokenBalance = 0;
        ERC20(token).transfer(msg.sender, amount);

        Withdrawal(msg.sender, token, amount);
    }

    function panicSell(address token) public {
        //This function should have a fee for quicker withdrawing without waiting
        Hodler storage hodler = hodlers[msg.sender];
        hodler.hodlerAddress = msg.sender;

        uint amount = hodler.tokens[token].tokenBalance;
        hodler.tokens[token].tokenBalance = 0;
        ERC20(token).transfer(msg.sender, amount);

        PanicSell(msg.sender, token, amount, hodler.tokens[token].timeLimit - block.timestamp);
    }

}
