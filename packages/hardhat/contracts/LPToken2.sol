pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// learn more: https://docs.openzeppelin.com/contracts/4.x/erc20

contract LPToken2 is ERC20 {
  constructor() ERC20("LP Token 2", "LPT2") {
    _mint( msg.sender , 1000 * 10 ** 18);
  }
}
