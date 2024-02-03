// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Test, stdStorage, StdStorage} from "../../lib/forge-std/src/Test.sol";
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
    using stdStorage for StdStorage;

    Tournament public tournament;
    UniswapV2Pair public mockUniLP;
    Vyper_contract public mockYLP;
    VRFCoordinatorV2Mock public mockVRF;

    // Define parameters for Tournament constructor
    uint256 LPTokenAmount = 1e18; // 1 LP Token
    uint256 startTime =  block.timestamp + 30 days; // Start in 30 days
    uint256 endTime = startTime + 30 days; // End one week after start

    // Set up "wallets"
    address owner = makeAddr("owner");
    address player1 = makeAddr("player1");
    address player2 = makeAddr("player2");
    address player3 = makeAddr("player3");
    address player4 = makeAddr("player4");
    address player5 = makeAddr("player5");

    /// /// /// /// ///
    // Functions to avoid repeting the same code on several tests
    /// /// /// /// ///

    function stakeForTest(address _player) public {
        vm.startPrank(_player);
        mockYLP.approve(address(tournament), LPTokenAmount);
        tournament.stakeLPToken();
        vm.stopPrank();
    }

    function stakePlayStakeForTest(uint8 _move, address _playerA, address _playerB) public {
        stakeForTest(_playerA);
        vm.startPrank(_playerA);
        tournament.playAgainstPlayer(_move);
        vm.stopPrank();
        
        stakeForTest(_playerB);
    }

    /// /// /// /// ///
    // Setup
    /// /// /// /// ///
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
        mockYLP.transfer(player3, 10e18);
        mockYLP.transfer(player4, 10e18);
        mockYLP.transfer(player5, 10e18);
        mockUniLP.transfer(player1, 10e18);
        mockUniLP.transfer(player2, 10e18);
        mockUniLP.transfer(player3, 10e18);
        mockUniLP.transfer(player4, 10e18);
        mockUniLP.transfer(player5, 10e18);

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
            owner, name, address(mockYLP), LPTokenAmount, 
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

    /// /// /// /// ///
    // Tests
    /// /// /// /// ///

    function test_isActive_before() public {
        vm.warp(startTime - 2 days);
        assertEq(tournament.isActive(), false);
    }

    function test_isActive_during() public {
        vm.warp(startTime + 2 days);
        assertEq(tournament.isActive(), true);
    }

    function test_isActive_after() public {
        vm.warp(endTime + 2 days);
        assertEq(tournament.isActive(), false);
    }

    function test_isFuture_before() public {
        vm.warp(startTime - 2 days);
        assertEq(tournament.isFuture(), true);
    }

    function test_isFuture_during() public {
        vm.warp(startTime + 2 days);
        assertEq(tournament.isFuture(), false);
    }

    function test_isFuture_after() public {
        vm.warp(endTime + 2 days);
        assertEq(tournament.isFuture(), false);
    }

    function test_isEnded_before() public {
        vm.warp(startTime - 2 days);
        assertEq(tournament.isEnded(), false);
    }

    function test_isEnded_during() public {
        vm.warp(startTime + 2 days);
        assertEq(tournament.isEnded(), false);
    }

    function test_isEnded_after() public {
        vm.warp(endTime + 2 days);
        assertEq(tournament.isEnded(), true);
    }

    function test_stakingAllowed_before() public {
        vm.warp(startTime - 2 days);
        assertEq(tournament.stakingAllowed(), true);
    }

    function test_stakingAllowed_during() public {
        vm.warp(startTime + 2 days);
        assertEq(tournament.stakingAllowed(), true);
    }

    function test_stakingAllowed_after() public {
        vm.warp(endTime + 2 days);
        assertEq(tournament.stakingAllowed(), false);
    }

    function test_getLPDecimals() public {
        assertEq(tournament.getLPDecimals(), 18);
    }

    function test_isPlayer() public {
        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        assertEq(tournament.isPlayer(player1), true);
        assertEq(tournament.isPlayer(player2), false);
    }

    function test_getNumberOfPlayers() public {
        assertEq(tournament.getNumberOfPlayers(), 0);

        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        assertEq(tournament.getNumberOfPlayers(), 1);

        vm.warp(startTime + 2 days);

        stakeForTest(player2);

        assertEq(tournament.getNumberOfPlayers(), 2);
    }

    event Staked(address indexed player, uint256 amount);

    function test_stakeLPToken_before() public {
        assertEq(mockYLP.balanceOf(player1), 10e18);

        vm.warp(startTime - 2 days);

        vm.startPrank(player1);
        mockYLP.approve(address(tournament), LPTokenAmount);

        vm.expectEmit();
        emit Staked(address(player1), LPTokenAmount);
        tournament.stakeLPToken();
        vm.stopPrank();
        
        assertEq(mockYLP.balanceOf(player1), 10e18 - LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournament)), LPTokenAmount);
    }

    function test_stakeLPToken_during() public {
        assertEq(mockYLP.balanceOf(player1), 10e18);

        vm.warp(startTime + 2 days);

        vm.startPrank(player1);
        mockYLP.approve(address(tournament), LPTokenAmount);

        vm.expectEmit();
        emit Staked(address(player1), LPTokenAmount);
        tournament.stakeLPToken();
        vm.stopPrank();
        
        assertEq(mockYLP.balanceOf(player1), 10e18 - LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournament)), LPTokenAmount);
    }

    function test_stakeLPToken_after() public {
        assertEq(mockYLP.balanceOf(player1), 10e18);

        vm.warp(endTime + 2 days);

        vm.startPrank(player1);
        mockYLP.approve(address(tournament), LPTokenAmount);

        vm.expectRevert("Staking not allowed");
        tournament.stakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), 10e18);
        assertEq(mockYLP.balanceOf(address(tournament)), 0);
    } 

    function test_stakeLPToken_twice() public {
        assertEq(mockYLP.balanceOf(player1), 10e18);

        vm.warp(startTime + 2 days);

        vm.startPrank(player1);
        mockYLP.approve(address(tournament), 2 * LPTokenAmount);

        // First staking
        tournament.stakeLPToken();

        // Second staking
        vm.expectRevert("You have already staked");
        tournament.stakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), 10e18 - LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournament)), LPTokenAmount);
    }

    function test_getPricePerShare() public {
        (uint val1, uint val2) = tournament.getPricePerShare();
        assertEq(val1, 100000);
        assertEq(val2, 0);

        mockYLP.setPricePerShare(150000);

        (val1, val2) = tournament.getPricePerShare();
        assertEq(val1, 150000);
        assertEq(val2, 0);

        mockYLP.setPricePerShare(50000);

        (val1, val2) = tournament.getPricePerShare();
        assertEq(val1, 50000);
        assertEq(val2, 0);
    }

    function test_LPTokenAmountOfPlayer_unchanged() public {
        assertEq(mockYLP.balanceOf(player1), 10e18);

        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        assertEq(tournament.LPTokenAmountOfPlayer(player1), LPTokenAmount);
    }

    function test_LPTokenAmountOfPlayer_valorized() public {
        assertEq(mockYLP.balanceOf(player1), 10e18);

        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        mockYLP.setPricePerShare(150000);

        assertEq(tournament.LPTokenAmountOfPlayer(player1), LPTokenAmount * 10 / 15);
    }

    function test_LPTokenAmountOfPlayer_devalorized() public {
        assertEq(mockYLP.balanceOf(player1), 10e18);

        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        mockYLP.setPricePerShare(50000);

        assertEq(tournament.LPTokenAmountOfPlayer(player1), LPTokenAmount);
    }

    function test_unstakeLPToken_before() public {
        vm.warp(startTime - 2 days);

        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Unstaking not allowed");
        tournament.unstakeLPToken();
        vm.stopPrank();
    }

    function test_unstakeLPToken_during() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Unstaking not allowed");
        tournament.unstakeLPToken();
        vm.stopPrank();
   }

    function test_unstakeLPToken_notPlayer() public {
        vm.warp(endTime + 2 days);
        vm.startPrank(player1);

        vm.expectRevert("You have nothing to withdraw");
        tournament.unstakeLPToken();
        vm.stopPrank();
    }

    event Unstaked(address indexed player, uint256 amount);

    function test_unstakeLPToken_after_unchanged() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        uint initPlayerBalance = mockYLP.balanceOf(player1);
        uint initContractBalance = mockYLP.balanceOf(address(tournament));

        vm.warp(endTime + 2 days);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournament.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalance + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournament)), initContractBalance - LPTokenAmount);
    }

    function test_unstakeLPToken_after_notPlayed_devalorized() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        uint initPlayerBalance = mockYLP.balanceOf(player1);
        uint initContractBalance = mockYLP.balanceOf(address(tournament));

        mockYLP.setPricePerShare(50000);
        vm.warp(endTime + 2 days);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournament.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalance + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournament)), initContractBalance - LPTokenAmount);
    }

    function test_unstakeLPToken_after_played_devalorized() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.prank(player2);
        tournament.playAgainstPlayer(2);

        uint initPlayerBalance = mockYLP.balanceOf(player1);
        uint initContractBalance = mockYLP.balanceOf(address(tournament));

        mockYLP.setPricePerShare(90000);
        vm.warp(endTime + 2 days);
        vm.startPrank(player1);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournament.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalance + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournament)), initContractBalance - LPTokenAmount);
    }

    function test_unstakeLPToken_after_played_valorized() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.prank(player2);
        tournament.playAgainstPlayer(2);

        uint initPlayerBalance = mockYLP.balanceOf(player1);
        uint initContractBalance = mockYLP.balanceOf(address(tournament));

        mockYLP.setPricePerShare(200000);
        vm.warp(endTime + 2 days);

        vm.startPrank(player1);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount / 2 + 0.45 ether);
        tournament.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalance + LPTokenAmount / 2 + 0.45 ether);
        assertEq(mockYLP.balanceOf(address(tournament)), initContractBalance - (LPTokenAmount / 2 + 0.45 ether));

        vm.startPrank(player2);
        vm.expectEmit();
        emit Unstaked(address(player2), LPTokenAmount / 2 + 0.225 ether);
        tournament.unstakeLPToken();
        vm.stopPrank();
    }

    function test_unstakeLPToken_twice() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        uint initPlayerBalance = mockYLP.balanceOf(player1);
        uint initContractBalance = mockYLP.balanceOf(address(tournament));

        vm.warp(endTime + 2 days);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournament.unstakeLPToken();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalance + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournament)), initContractBalance - LPTokenAmount);

        vm.expectRevert("You have nothing to withdraw");
        tournament.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalance + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournament)), initContractBalance - LPTokenAmount);
    }

    function testPlayAgainstContractAlwaysReturnsLessThan3(uint256 _fuzzNumber) public {
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

    function test_PlayAgainstPlayer_invalidMove() public {

        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Invalid move");
        tournament.playAgainstPlayer(3);
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_before() public {

        vm.warp(startTime - 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Tournament is not active");
        tournament.playAgainstPlayer(1);
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_after() public {

        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.warp(endTime + 2 days);
        vm.expectRevert("Tournament is not active");
        tournament.playAgainstPlayer(1);
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_notPlayer() public {

        vm.warp(startTime + 2 days);
        vm.startPrank(player1);

        vm.expectRevert("You must deposit before playing");        
        tournament.playAgainstPlayer(1);

        vm.stopPrank();
    }

    event MoveSaved(address indexed player);

    function test_PlayAgainstPlayer_FirstPlayer() public {

        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectEmit();
        emit MoveSaved(player1);
        tournament.playAgainstPlayer(1);

        vm.stopPrank();
    }

    event Draw(address indexed player, address indexed opponent, uint256 day);

    function test_PlayAgainstPlayer_RockRock() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Draw(player2, player1, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(0);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 2);
        assertEq(tournament.pointsOfPlayer(player2), 2);
    }

    function test_PlayAgainstPlayer_PaperPaper() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(1, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Draw(player2, player1, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(1);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 2);
        assertEq(tournament.pointsOfPlayer(player2), 2);
    }

    function test_PlayAgainstPlayer_ScissorsScissors() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(2, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Draw(player2, player1, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(2);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 2);
        assertEq(tournament.pointsOfPlayer(player2), 2);
    }

    event Winner(address indexed player, uint256 day);

	event Loser(address indexed player, uint256 day);

    function test_PlayAgainstPlayer_RockPaper() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player2, block.timestamp / (60 * 60 * 24));
        emit Loser(player1, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(1);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 4);
    }

    function test_PlayAgainstPlayer_RockScissors() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(2);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 4);
        assertEq(tournament.pointsOfPlayer(player2), 0);
    }

    function test_PlayAgainstPlayer_PaperRock() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(1, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(0);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 4);
        assertEq(tournament.pointsOfPlayer(player2), 0);
    }

    function test_PlayAgainstPlayer_PaperScissors() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(1, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player2, block.timestamp / (60 * 60 * 24));
        emit Loser(player1, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(2);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 4);
    }

    function test_PlayAgainstPlayer_ScissorsRock() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(2, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player2, block.timestamp / (60 * 60 * 24));
        emit Loser(player1, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(0);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 4);
    }

    function test_PlayAgainstPlayer_ScissorsPaper() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(2, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(1);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 4);
        assertEq(tournament.pointsOfPlayer(player2), 0);
    }

    function test_PlayAgainstPlayer_4Players() public {
        assertEq(tournament.pointsOfPlayer(player1), 0);
        assertEq(tournament.pointsOfPlayer(player2), 0);
        assertEq(tournament.pointsOfPlayer(player3), 0);
        assertEq(tournament.pointsOfPlayer(player4), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(2);

        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);
        vm.startPrank(player4);

        vm.expectEmit();
        emit Draw(player4, player3, block.timestamp / (60 * 60 * 24));
        tournament.playAgainstPlayer(1);

        vm.stopPrank();

        assertEq(tournament.pointsOfPlayer(player1), 4);
        assertEq(tournament.pointsOfPlayer(player2), 0);
        assertEq(tournament.pointsOfPlayer(player3), 2);
        assertEq(tournament.pointsOfPlayer(player4), 2);
        assertEq(tournament.topScore(), 4);
    }

    function test_alreadyPlayed_notStaked() public {
        vm.warp(startTime + 2 days);
        assertEq(tournament.alreadyPlayed(player1), false);
    }

    function test_alreadyPlayed_stakedNotPlayed() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        assertEq(tournament.alreadyPlayed(player1), false);
    }

    function test_alreadyPlayed_playedToday() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.prank(player1);
        tournament.playAgainstPlayer(0);

        assertEq(tournament.alreadyPlayed(player1), true);
    }

    function test_alreadyPlayed_playedYesterday() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.prank(player1);
        tournament.playAgainstPlayer(0);

        vm.warp(startTime + 3 days);
        assertEq(tournament.alreadyPlayed(player1), false);
    }

    function test_getRank() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        vm.startPrank(player4);
        tournament.playAgainstPlayer(1);
        vm.stopPrank();

        (uint256 rank1, uint256 split1) = tournament.getRank(player1);
        assertEq(rank1, 1);
        assertEq(split1, 1);
        (uint256 rank2, uint256 split2) = tournament.getRank(player2);
        assertEq(rank2, 3);
        assertEq(split2, 1);
        (uint256 rank3, uint256 split3) = tournament.getRank(player3);
        assertEq(rank3, 2);
        assertEq(split3, 2);
        (uint256 rank4, uint256 split4) = tournament.getRank(player4);
        assertEq(rank4, 2);
        assertEq(split4, 2);
    }

    function test_getRank_notPlayer() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        vm.startPrank(player4);
        tournament.playAgainstPlayer(1);
        vm.stopPrank();

        vm.expectRevert("Not a player");
        tournament.getRank(player5);
    }

    function test_getPrizeShare_1Player() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        
        assertEq(tournament.getPrizeShare(player1), 0.5 ether);
    }

    function test_getPrizeShare_4Players() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        vm.startPrank(player4);
        tournament.playAgainstPlayer(1);
        vm.stopPrank();
        
        assertEq(tournament.getPrizeShare(player1), 0.5 ether);
        assertEq(tournament.getPrizeShare(player2), 0.125 ether);
        assertEq(tournament.getPrizeShare(player3), 0.125 ether);
        assertEq(tournament.getPrizeShare(player4), 0.125 ether);
        assertEq(tournament.getPrizeShare(player5), 0);
    }

    function test_getPoolPrize_noPlayer() public {
        assertEq(tournament.getPoolPrize(), 0);
    }

    function test_getPoolPrize_noValorization_noWithdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        assertEq(tournament.getPoolPrize(), 0);
    }

    function test_getPoolPrize_valorization_noWithdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        mockYLP.setPricePerShare(200000); // Value of LP doubled
        uint contractBalance = mockYLP.balanceOf(address(tournament));
        uint fees = tournament.fees();

        assertEq(tournament.getPoolPrize(), contractBalance * (1 ether - fees) / 2 ether);
    }

    function test_getPoolPrize_noValorization_withdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);

        vm.warp(endTime + 2 days);
        tournament.unstakeLPToken();
        vm.stopPrank();

        assertEq(tournament.getPoolPrize(), 0);
    }

    function test_getPoolPrize_valorizationBeforeWithdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles

        uint contractBalance = mockYLP.balanceOf(address(tournament));
        uint fees = tournament.fees();
        
        vm.warp(endTime + 2 days);
        tournament.unstakeLPToken();
        vm.stopPrank();

        assertEq(tournament.getPoolPrize(), contractBalance * (1 ether - fees) / 2 ether);
    }

    function test_getPoolPrize_valorizationBeforeAfterWithdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles

        uint fees = tournament.fees();
        
        vm.warp(endTime + 2 days);
        tournament.unstakeLPToken();
        vm.stopPrank();

        mockYLP.setPricePerShare(400000); // Value of LP doubles again

        assertEq(tournament.getPoolPrize(), LPTokenAmount * (1 ether - fees) / 2 ether + LPTokenAmount * (1 ether - fees) * 3 / 4 ether);
    }

    function test_getPrizeAmount_noValorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        assertEq(tournament.getPrizeAmount(player1), 0);
        assertEq(tournament.getPrizeAmount(player2), 0);
    }

    function test_getPrizeAmount_valorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        mockYLP.setPricePerShare(200000); // Value of LP doubles

        assertEq(tournament.getPrizeAmount(player1), tournament.getPoolPrize() * 5 / 10);
        assertEq(tournament.getPrizeAmount(player2), tournament.getPoolPrize() * 25 / 100);
    }

    function test_getExpectedPoolPrize_noValorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        vm.warp(startTime + 7 days);

        assertEq(tournament.getExpectedPoolPrize(), 0);
    }

    function test_getExpectedPoolPrize_valorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        vm.warp(startTime + 7 days);
        mockYLP.setPricePerShare(200000); // Value of LP doubles

        assertEq(tournament.getExpectedPoolPrize(), tournament.getPoolPrize() * 30 / 7);
    }

    function test_getExpectedPoolPrize_future() public {
        vm.warp(startTime - 2 days);
        stakeForTest(player1);
        stakeForTest(player2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles

        assertEq(tournament.getExpectedPoolPrize(), 0);
    }

    function test_getFees_noValorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        assertEq(tournament.getFees(), 0);
    }

    function test_getFees_valorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournament.playAgainstPlayer(2);
        vm.stopPrank();

        mockYLP.setPricePerShare(200000); // Value of LP doubled
        uint contractBalance = mockYLP.balanceOf(address(tournament));
        uint fees = tournament.fees();

        assertEq(tournament.getFees(), contractBalance * fees / 2 ether);
    }

    function test_getNumberOfPlayers_noPlayer() public {
        assertEq(tournament.getNumberOfPlayers(), 0);
    }

    function test_getNumberOfPlayers_onePlayer() public {
        vm.warp(startTime - 2 days);
        stakeForTest(player1);

        assertEq(tournament.getNumberOfPlayers(), 1);
    }

    function test_getNumberOfPlayers_twoPlayers() public {
        vm.warp(startTime - 2 days);
        stakeForTest(player1);
        stakeForTest(player2);

        assertEq(tournament.getNumberOfPlayers(), 2);
    }



}

