pragma solidity 0.8.20;
// SPDX-License-Identifier: MIT

import "./YourToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vendor is Ownable {
    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);
    event Withdraw(address owner, uint256 amount);

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    function buyTokens() external payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        uint256 amountToBuy = msg.value * tokensPerEth;

        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Vendor has insufficient tokens");

        yourToken.transfer(msg.sender, amountToBuy);

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No ETH to withdraw");

        payable(owner()).transfer(contractBalance);

        emit Withdraw(owner(), contractBalance);
    }

    function sellTokens(uint256 _amount) external {
        require(_amount > 0, "Specify an amount greater than 0");

        uint256 ethAmount = _amount / tokensPerEth;
        require(address(this).balance >= ethAmount, "Vendor has insufficient ETH");

        bool sent = yourToken.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Token transfer failed");

        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "ETH transfer failed");

        emit SellTokens(msg.sender, _amount, ethAmount);
    }

    receive() external payable {}
}
