pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// learn more: https://docs.openzeppelin.com/contracts/4.x/erc20

contract UniswapV2Pair is ERC20 {
  constructor() ERC20("Uniswap V2", "UNI-V2") {
    _mint( msg.sender , 1000 * 10 ** 18);
  }

  uint public supply = 100000;
  uint reserve0 = 100000;
  uint reserve1 = 100000;

  function totalSupply() public view override returns (uint) {
    return supply;
  }

  function getReserves() public view returns (uint, uint, uint) {
    return (reserve0, reserve1, block.timestamp - 60);
  }

  function setTotalSupply(uint _totalSupply) public {
    supply = _totalSupply;    
  }

  function setReserves(uint _reserve0, uint _reserve1) public {
    reserve0 = _reserve0;
    reserve1 = _reserve1;
  }

}
