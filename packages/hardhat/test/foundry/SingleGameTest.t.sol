// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {SingleGame} from "../../contracts/SingleGame.sol"; // Adjust the path according to your project structure
contract SingleGameTest is Test {
    SingleGame singleGame;
    address player1 = address(1);
    address player2 = address(2);

    function setUp() public {
        // Initialize your contract here
        // For the VRF-related parameters, use mock values or deploy mock contracts if necessary
        singleGame = new SingleGame( /* parameters */ );
    }
}
