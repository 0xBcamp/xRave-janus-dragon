pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// learn more: https://docs.openzeppelin.com/contracts/4.x/erc20

contract Vyper_contract is ERC20 {
  constructor(address _token) ERC20("USDT yVault", "yvUSDT") {
    _mint( msg.sender , 1000 * 10 ** 18);
    token = _token;
  }

  uint public pricePerShare = 100000;
  address public token;

  function setPricePerShare(uint _pricePerShare) public {
    pricePerShare = _pricePerShare;
  }

}
