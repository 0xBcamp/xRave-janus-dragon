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
    

    
    
    // // state variables for PvVRF
    // struct ContractGame {
    //     uint8 playerMove;
    //     address player;
    //     bool fulfilled; // whether the request has been successfully fulfilled
    //     bool exists; // whether a requestId exists
    //     uint256[] randomWords;
    //     uint256 vrfMove;
    //     address winner;
    // }

    // // requestId --> GameStatus  @note is there a better way to track games?
    // mapping(uint256 => ContractGame) public contractGameRequestId; 

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


}

