// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {Tournament} from "../../contracts/Tournament.sol"; // 
import {Vyper_contract} from "../../contracts/Vyper_contract.sol"; // Mock Yearn LP
import {UniswapV2Pair} from "../../contracts/UniswapV2Pair.sol"; // Mock Uniswap LP
import {MockVRFCoordinator} from "../../contracts/mocks/MockVRFCoordinator.sol"; // Mock VRF Coordinator

/**
 *  // Mocks a call to an address, returning specified data. -- can use this to mock the VRF Coordinator
    //
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    
    function mockCall(address, bytes calldata, bytes calldata) external;
 */

contract TournamentTest is Test {
    Tournament public tournament;
    MockUniERC20 public mockUniLP;
    MockYERC20 public mockYLP;
    MockVRFCoordinator public mockVrfCoordinator;

    function setUp() public {
        // Deploy Mock Contracts
        mockUniLP = new MockUniERC20();
        mockYLP = new MockYERC20();
        mockVrfCoordinator = new MockVRFCoordinator();

        // Define parameters for Tournament constructor
        address owner = address(this); // Use the test contract as the owner for simplicity
        string memory name = "Test Tournament";
        address poolIncentivized = address(mockLP);
        uint256 LPTokenAmount = 1e18; // 1 LP Token
        uint256 startTime = block.timestamp + 1 days; // Start one day from now
        uint256 endTime = startTime + 7 days; // End one week after start
        uint64 subscriptionId = 1; // Mock subscription ID
        bytes32 gasLane = bytes32(0); // Mock gas lane
        uint32 callbackGasLimit = 2000000; // Set a callback gas limit
        address vrfCoordinatorV2 = address(mockVrfCoordinator); // Use mock VRF Coordinator

        // Deploy Tournament contract
        tournament = new Tournament(
            owner, name, poolIncentivized, LPTokenAmount, 
            startTime, endTime, subscriptionId, gasLane, 
            callbackGasLimit, vrfCoordinatorV2
        );
    }

    // Test functions go here
}

