// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {console2} from "../../lib/forge-std/src/console2.sol";
import {Tournament} from "../../contracts/Tournament.sol"; // 
import {Vyper_contract} from "../../contracts/Vyper_contract.sol"; // Mock Yearn LP
import {UniswapV2Pair} from "../../contracts/UniswapV2Pair.sol"; // Mock Uniswap LP
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";// Mock VRF Coordinator

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
    UniswapV2Pair public mockUniLP;
    Vyper_contract public mockYLP;
    VRFCoordinatorV2Mock public mockVRF;

    // Define parameters for Tournament constructor
    address poolIncentivized = address(mockYLP);
    uint256 LPTokenAmount = 1e18; // 1 LP Token
    uint256 startTime =  block.timestamp + 1 seconds; // Start one day from now
    uint256 endTime = startTime + 7 days; // End one week after start

    // Set up "wallets"
    address owner = makeAddr("owner");
    address player1 = makeAddr("player1");
    address player2 = makeAddr("player2");

    function setUp() public {
        //vrf variables
        bytes32 gasLane = bytes32(0); // Mock gas lane
        uint32 callbackGasLimit = 2000000; // Set a callback gas limit
        uint64 subId;
        
        vm.deal(owner, 2 ether);
        vm.startPrank(owner);

        // Deploy Mock Contracts
        mockUniLP = new UniswapV2Pair();
        mockYLP = new Vyper_contract();

        // Transfer LP tokens to players
        mockYLP.transfer(player1, 10e18);
        mockYLP.transfer(player2, 10e18);
        mockUniLP.transfer(player1, 10e18);
        mockUniLP.transfer(player2, 10e18);


        //from mock vrf 
        //constructor(uint96 _baseFee, uint96 _gasPriceLink) 
        mockVRF = new VRFCoordinatorV2Mock(10, 1);

        // create subscription ID
        subId = mockVRF.createSubscription();
        // fund subscription
        mockVRF.fundSubscription(subId, 1000000000000000000);

        string memory name = "Test Tournament";
        // Deploy Tournament contract
        tournament = new Tournament(
            owner, name, poolIncentivized, LPTokenAmount, 
            startTime, endTime, subId, gasLane, 
            callbackGasLimit, address(mockVRF)
        );

        // add toournament as consumer of VRF
        mockVRF.addConsumer(subId, address(tournament));

        vm.stopPrank();

    }

    function testSetUp() public {
        assertEq(tournament.owner(), owner);
        assertEq(tournament.name(), "Test Tournament");
        //assertEq(tournament.poolIncentivized(), address(mockYLP));
        assertEq(tournament.LPTokenAmount(), 1e18);
        assertEq(tournament.startTime(), startTime);
        assertEq(tournament.endTime(), endTime);
        //assertEq(tournament.subId(), 1);
        //assertEq(tournament.gasLane(), bytes32(0));
        //assertEq(tournament.callbackGasLimit(), 2000000);
        //assertEq(tournament.vrfCoordinator(), address(mockVRF));
        assertEq(mockYLP.balanceOf(player1), 10e18);
        assertEq(mockYLP.balanceOf(player2), 10e18);
        assertEq(mockUniLP.balanceOf(player1), 10e18);
        assertEq(mockUniLP.balanceOf(player2), 10e18);
    }

    function testPlayAganistContractAlwyasReturnsLessThan3(uint256 _fuzzNumber) public {
        vm.warp(startTime + 1 seconds);
        
        vm.prank(player1);
        uint256 requestId = tournament.playAgainstContract(1);

        // fulfill random words
        // prank VRF because only VRF can call this function
        //vm.prank(address(mockVRF));
        //mockVRF.fulfillRandomWords(requestId, address(tournament));

        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = _fuzzNumber; // the actual number you want to use as return from VRF

        mockVRF.fulfillRandomWordsWithOverride(requestId, address(tournament), randomWords);


        vm.roll(10);
        (, , , , , uint256 vrfMove, ) = tournament.getGame(requestId);
        console2.log("VRF Move: ", vrfMove);    

        //assertApproxEqAbs(uint256 a, uint256 2, uint256 2)
        assertTrue(vrfMove <= 2, "VRF move is not valid");

    }

    function testPlayAganistPlayer() public {
        uint8 currentMove;
        address currentPlayer;

        //test unregistered player
        vm.prank(player1);
        vm.expectRevert();
        tournament.playAgainstPlayer(1);

        vm.startPrank(player1);
        //approve LP tokens
        mockYLP.approve(address(tournament), 10e18);

        // Check player1's token balance before approving
        // uint256 player1Balance = mockYLP.balanceOf(player1);
        // console2.log("Player1 Balance: ", player1Balance);

        // deposit to enter
        tournament.stakeLPToken();
        // test can't play w/ 0 move
        vm.expectRevert();
        tournament.playAgainstPlayer(0);

        //assertEq(currentMove, 1);
        //assertEq(currentPlayer, player1);
    }


}

