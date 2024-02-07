pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// learn more: https://docs.openzeppelin.com/contracts/4.x/erc20

contract UniswapV2Pair is ERC20 {
  constructor() ERC20("Uniswap V2", "UNI-V2") {
    _mint( msg.sender , 1000 ether);
  }

  // totalSupply is sqrt( res0 * res 1 ) at start
  uint112 reserve0 = 1000 ether;
  uint112 reserve1 = 1000 ether;

  function getReserves() public view returns (uint112, uint112, uint32) {
    uint32 time = uint32(block.timestamp) - 60;
    return (reserve0, reserve1, time);
  }

  function setTotalSupply(uint _supply) public {
    if(_supply > totalSupply()) {
        uint mint = _supply - totalSupply();
        _mint( msg.sender , mint);
    } else {
        uint burn = totalSupply() - _supply;
        _burn( msg.sender , burn);
    }
  }

  function setReserves(uint112 _reserve0, uint112 _reserve1) public {
    reserve0 = _reserve0;
    reserve1 = _reserve1;
  }

}
