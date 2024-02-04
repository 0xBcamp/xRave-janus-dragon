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

    Tournament public tournamentU;
    Tournament public tournamentY;
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
        mockUniLP.approve(address(tournamentU), LPTokenAmount);
        mockYLP.approve(address(tournamentY), LPTokenAmount);
        tournamentU.stakeLPToken();
        tournamentY.stakeLPToken();
        vm.stopPrank();
    }

    function stakePlayStakeForTest(uint8 _move, address _playerA, address _playerB) public {
        stakeForTest(_playerA);
        vm.startPrank(_playerA);
        tournamentU.playAgainstPlayer(_move);
        tournamentY.playAgainstPlayer(_move);
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

        string memory name = "Yearn Tournament";
        // Deploy Tournament contract
        tournamentY = new Tournament(
            owner, name, address(mockYLP), LPTokenAmount, 
            startTime, endTime, subId, gasLane, 
            callbackGasLimit, address(mockVRF)
        );

        name = "Uniswap Tournament";
        // Deploy Tournament contract
        tournamentU = new Tournament(
            owner, name, address(mockUniLP), LPTokenAmount, 
            startTime, endTime, subId, gasLane, 
            callbackGasLimit, address(mockVRF)
        );

        // add toournament as consumer of VRF
        mockVRF.addConsumer(subId, address(tournamentY));

        vm.stopPrank();

    }

    function testSetUp() public {
        assertEq(tournamentY.owner(), owner);
        assertEq(tournamentY.name(), "Yearn Tournament");
        //assertEq(tournamentY.poolIncentivized(), address(mockYLP));
        assertEq(tournamentY.LPTokenAmount(), 1e18);
        assertEq(tournamentY.startTime(), startTime);
        assertEq(tournamentY.endTime(), endTime);
        //assertEq(tournamentY.subId(), 1);
        //assertEq(tournamentY.gasLane(), bytes32(0));
        //assertEq(tournamentY.callbackGasLimit(), 2000000);
        //assertEq(tournamentY.vrfCoordinator(), address(mockVRF));
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
        assertEq(tournamentY.isActive(), false);
    }

    function test_isActive_during() public {
        vm.warp(startTime + 2 days);
        assertEq(tournamentY.isActive(), true);
    }

    function test_isActive_after() public {
        vm.warp(endTime + 2 days);
        assertEq(tournamentY.isActive(), false);
    }

    function test_isFuture_before() public {
        vm.warp(startTime - 2 days);
        assertEq(tournamentY.isFuture(), true);
    }

    function test_isFuture_during() public {
        vm.warp(startTime + 2 days);
        assertEq(tournamentY.isFuture(), false);
    }

    function test_isFuture_after() public {
        vm.warp(endTime + 2 days);
        assertEq(tournamentY.isFuture(), false);
    }

    function test_isEnded_before() public {
        vm.warp(startTime - 2 days);
        assertEq(tournamentY.isEnded(), false);
    }

    function test_isEnded_during() public {
        vm.warp(startTime + 2 days);
        assertEq(tournamentY.isEnded(), false);
    }

    function test_isEnded_after() public {
        vm.warp(endTime + 2 days);
        assertEq(tournamentY.isEnded(), true);
    }

    function test_stakingAllowed_before() public {
        vm.warp(startTime - 2 days);
        assertEq(tournamentY.stakingAllowed(), true);
    }

    function test_stakingAllowed_during() public {
        vm.warp(startTime + 2 days);
        assertEq(tournamentY.stakingAllowed(), true);
    }

    function test_stakingAllowed_after() public {
        vm.warp(endTime + 2 days);
        assertEq(tournamentY.stakingAllowed(), false);
    }

    function test_unstakingAllowed_before() public {
        vm.warp(startTime - 2 days);
        assertEq(tournamentY.unstakingAllowed(), false);
    }

    function test_unstakingAllowed_during() public {
        vm.warp(startTime + 2 days);
        assertEq(tournamentY.unstakingAllowed(), false);
    }

    function test_unstakingAllowed_after() public {
        vm.warp(endTime + 2 days);
        assertEq(tournamentY.unstakingAllowed(), true);
    }

    function test_getLPDecimals() public {
        assertEq(tournamentY.getLPDecimals(), 18);
    }

    function test_isPlayer() public {
        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        assertEq(tournamentY.isPlayer(player1), true);
        assertEq(tournamentY.isPlayer(player2), false);
    }

    function test_getNumberOfPlayers() public {
        uint initPlayers = tournamentY.getNumberOfPlayers();

        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        assertEq(tournamentY.getNumberOfPlayers(), initPlayers + 1);

        stakeForTest(player2);

        assertEq(tournamentY.getNumberOfPlayers(), initPlayers + 2);
    }

    event Staked(address indexed player, uint256 amount);

    function test_stakeLPToken_before() public {
        uint initBalanceY = mockYLP.balanceOf(player1);
        uint initBalanceU = mockUniLP.balanceOf(player1);

        vm.warp(startTime - 2 days);

        vm.startPrank(player1);

        mockUniLP.approve(address(tournamentU), LPTokenAmount);
        mockYLP.approve(address(tournamentY), LPTokenAmount);

        vm.expectEmit();
        emit Staked(address(player1), LPTokenAmount);
        tournamentU.stakeLPToken();

        vm.expectEmit();
        emit Staked(address(player1), LPTokenAmount);
        tournamentY.stakeLPToken();

        vm.stopPrank();
        
        assertEq(mockYLP.balanceOf(player1), initBalanceY - LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initBalanceU - LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), LPTokenAmount);
    }

    function test_stakeLPToken_during() public {
        uint initBalanceY = mockYLP.balanceOf(player1);
        uint initBalanceU = mockUniLP.balanceOf(player1);

        vm.warp(startTime + 2 days);

        vm.startPrank(player1);

        mockUniLP.approve(address(tournamentU), LPTokenAmount);
        mockYLP.approve(address(tournamentY), LPTokenAmount);

        vm.expectEmit();
        emit Staked(address(player1), LPTokenAmount);
        tournamentU.stakeLPToken();

        vm.expectEmit();
        emit Staked(address(player1), LPTokenAmount);
        tournamentY.stakeLPToken();

        vm.stopPrank();
        
        assertEq(mockYLP.balanceOf(player1), initBalanceY - LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initBalanceU - LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), LPTokenAmount);
    }

    function test_stakeLPToken_after() public {
        uint initBalanceY = mockYLP.balanceOf(player1);
        uint initBalanceU = mockUniLP.balanceOf(player1);

        vm.warp(endTime + 2 days);

        vm.startPrank(player1);

        mockUniLP.approve(address(tournamentU), LPTokenAmount);
        mockYLP.approve(address(tournamentY), LPTokenAmount);

        vm.expectRevert("Staking not allowed");
        tournamentY.stakeLPToken();
        vm.expectRevert("Staking not allowed");
        tournamentU.stakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initBalanceY);
        assertEq(mockYLP.balanceOf(address(tournamentY)), 0);
        assertEq(mockUniLP.balanceOf(player1), initBalanceU);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), 0);
    }

    function test_stakeLPToken_twice() public {
        uint initBalanceY = mockYLP.balanceOf(player1);
        uint initBalanceU = mockUniLP.balanceOf(player1);

        vm.warp(startTime + 2 days);

        vm.startPrank(player1);
        mockUniLP.approve(address(tournamentU), 2 * LPTokenAmount);
        mockYLP.approve(address(tournamentY), 2 * LPTokenAmount);

        // First staking
        tournamentY.stakeLPToken();
        tournamentU.stakeLPToken();

        // Second staking
        vm.expectRevert("You have already staked");
        tournamentY.stakeLPToken();
        vm.expectRevert("You have already staked");
        tournamentU.stakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initBalanceY - LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initBalanceU - LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), LPTokenAmount);
    }

    function test_stakeLPToken_unapproved() public {
        uint initBalance = mockYLP.balanceOf(player1);
        vm.warp(startTime - 2 days);

        vm.startPrank(player1);

        vm.expectRevert();
        tournamentY.stakeLPToken();
        vm.stopPrank();
        
        assertEq(mockYLP.balanceOf(player1), initBalance);
        assertEq(mockYLP.balanceOf(address(tournamentY)), 0);
    }

    function test_getPricePerShare_Yearn() public {
        (uint val1, uint val2) = tournamentY.getPricePerShare();
        assertEq(val1, 100000);
        assertEq(val2, 0);

        mockYLP.setPricePerShare(150000);

        (val1, val2) = tournamentY.getPricePerShare();
        assertEq(val1, 150000);
        assertEq(val2, 0);

        mockYLP.setPricePerShare(50000);

        (val1, val2) = tournamentY.getPricePerShare();
        assertEq(val1, 50000);
        assertEq(val2, 0);
    }

    function test_getPricePerShare_Uniswap() public {
        vm.warp(startTime);

        (uint val1, uint val2) = tournamentU.getPricePerShare();
        assertEq(val1, 100);
        assertEq(val2, 100);

        mockUniLP.setReserves(150000, 200000);

        (val1, val2) = tournamentU.getPricePerShare();
        assertEq(val1, 150);
        assertEq(val2, 200);

        mockUniLP.setReserves(250000, 50000);

        (val1, val2) = tournamentU.getPricePerShare();
        assertEq(val1, 250);
        assertEq(val2, 50);

        mockUniLP.setTotalSupply(2000 ether);
        
        (val1, val2) = tournamentU.getPricePerShare();
        assertEq(val1, 125);
        assertEq(val2, 25);
    }

    function test_LPTokenAmountOfPlayer_unchanged() public {
        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        assertEq(tournamentY.LPTokenAmountOfPlayer(player1), LPTokenAmount);
        assertEq(tournamentU.LPTokenAmountOfPlayer(player1), LPTokenAmount);
    }

    function test_LPTokenAmountOfPlayer_valorized() public {
        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        mockYLP.setPricePerShare(150000);
        mockUniLP.setReserves(300000, 300000);
        mockUniLP.setTotalSupply(2000 ether);


        assertEq(tournamentY.LPTokenAmountOfPlayer(player1), LPTokenAmount * 10 / 15);
        assertEq(tournamentU.LPTokenAmountOfPlayer(player1), LPTokenAmount * 10 / 15);

        mockUniLP.setReserves(200000, 200000);
        mockUniLP.setTotalSupply(1000 ether);

        assertEq(tournamentU.LPTokenAmountOfPlayer(player1), LPTokenAmount / 2);
    }

    function test_LPTokenAmountOfPlayer_devalorized() public {
        vm.warp(startTime + 2 days);

        stakeForTest(player1);

        mockYLP.setPricePerShare(50000);
        mockUniLP.setReserves(50000, 50000);

        assertEq(tournamentY.LPTokenAmountOfPlayer(player1), LPTokenAmount);
        assertEq(tournamentU.LPTokenAmountOfPlayer(player1), LPTokenAmount);

        mockUniLP.setTotalSupply(2000 ether);

        assertEq(tournamentU.LPTokenAmountOfPlayer(player1), LPTokenAmount);
    }

    function test_unstakeLPToken_before() public {
        vm.warp(startTime - 2 days);

        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Unstaking not allowed");
        tournamentY.unstakeLPToken();
        vm.expectRevert("Unstaking not allowed");
        tournamentU.unstakeLPToken();
        vm.stopPrank();
    }

    function test_unstakeLPToken_during() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Unstaking not allowed");
        tournamentY.unstakeLPToken();
        vm.expectRevert("Unstaking not allowed");
        tournamentU.unstakeLPToken();
        vm.stopPrank();
   }

    function test_unstakeLPToken_notPlayer() public {
        vm.warp(endTime + 2 days);
        vm.startPrank(player1);

        vm.expectRevert("You have nothing to withdraw");
        tournamentY.unstakeLPToken();
        vm.expectRevert("You have nothing to withdraw");
        tournamentU.unstakeLPToken();
        vm.stopPrank();
    }

    function test_unstakeLPToken_noBalance() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);

        uint initPlayerBalance = mockYLP.balanceOf(player1);
        uint initContractBalance = mockYLP.balanceOf(address(tournamentY));

        vm.prank(address(tournamentY));
        mockYLP.approve(address(this), initContractBalance);
        mockYLP.transferFrom(address(tournamentY), player2, initContractBalance);

        vm.warp(endTime + 2 days);
        vm.startPrank(player1);
        vm.expectRevert();
        tournamentY.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalance);
        assertEq(mockYLP.balanceOf(address(tournamentY)), 0);
    }

    event Unstaked(address indexed player, uint256 amount);

    function test_unstakeLPToken_after_unchanged() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        vm.warp(endTime + 2 days);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalanceY + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY - LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initPlayerBalanceU + LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU - LPTokenAmount);
    }

    function test_unstakeLPToken_after_notPlayed_devalorized() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        mockYLP.setPricePerShare(50000);
        mockUniLP.setReserves(50000, 50000);
        vm.warp(endTime + 2 days);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalanceY + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY - LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initPlayerBalanceU + LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU - LPTokenAmount);
    }

    function test_unstakeLPToken_after_played_devalorized() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.prank(player2);
        tournamentY.playAgainstPlayer(2);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        mockYLP.setPricePerShare(90000);
        mockUniLP.setReserves(90000, 90000);
        vm.warp(endTime + 2 days);
        vm.startPrank(player1);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalanceY + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY - LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initPlayerBalanceU + LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU - LPTokenAmount);
    }

    function test_unstakeLPToken_after_played_valorized() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.prank(player2);
        tournamentY.playAgainstPlayer(2);
        vm.prank(player2);
        tournamentU.playAgainstPlayer(2);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        mockYLP.setPricePerShare(200000);
        mockUniLP.setReserves(200000, 200000);
        vm.warp(endTime + 2 days);

        vm.startPrank(player1);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount / 2 + 0.45 ether);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount / 2 + 0.45 ether);
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalanceY + LPTokenAmount / 2 + 0.45 ether);
        assertEq(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY - (LPTokenAmount / 2 + 0.45 ether));
        assertEq(mockUniLP.balanceOf(player1), initPlayerBalanceU + LPTokenAmount / 2 + 0.45 ether);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU - (LPTokenAmount / 2 + 0.45 ether));

        vm.startPrank(player2);
        vm.expectEmit();
        emit Unstaked(address(player2), LPTokenAmount / 2 + 0.225 ether);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player2), LPTokenAmount / 2 + 0.225 ether);
        tournamentU.unstakeLPToken();
        vm.stopPrank();
    }

    function test_unstakeLPToken_twice() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        vm.warp(endTime + 2 days);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentU.unstakeLPToken();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalanceY + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY - LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initPlayerBalanceU + LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU - LPTokenAmount);

        vm.expectRevert("You have nothing to withdraw");
        tournamentY.unstakeLPToken();
        vm.expectRevert("You have nothing to withdraw");
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalanceY + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY - LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initPlayerBalanceU + LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU - LPTokenAmount);
    }

    function test_PlayAgainstContractAlwaysReturnsLessThan3(uint256 _fuzzNumber) public {
                
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);
        uint256 requestId = tournamentY.playAgainstContract(1);

        // fulfill random words
        // prank VRF because only VRF can call this function
        //vm.prank(address(mockVRF));
        //mockVRF.fulfillRandomWords(requestId, address(tournamentY));

        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = _fuzzNumber; // the actual number you want to use as return from VRF

        mockVRF.fulfillRandomWordsWithOverride(requestId, address(tournamentY), randomWords);


        vm.roll(10);
        (, , , , , uint256 vrfMove, ) = tournamentY.getGame(requestId);
        console2.log("VRF Move: ", vrfMove);    

        //assertApproxEqAbs(uint256 a, uint256 2, uint256 2)
        assertTrue(vrfMove <= 2, "VRF move is not valid");

    }

    function test_PlayAgainstPlayer_invalidMove() public {

        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Invalid move");
        tournamentY.playAgainstPlayer(3);
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_before() public {

        vm.warp(startTime - 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Tournament is not active");
        tournamentY.playAgainstPlayer(1);
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_after() public {

        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.warp(endTime + 2 days);
        vm.expectRevert("Tournament is not active");
        tournamentY.playAgainstPlayer(1);
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_notPlayer() public {

        vm.warp(startTime + 2 days);
        vm.startPrank(player1);

        vm.expectRevert("You must deposit before playing");        
        tournamentY.playAgainstPlayer(1);

        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_twice() public {

        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);
        tournamentY.playAgainstPlayer(1);

        vm.expectRevert("You already played today");
        tournamentY.playAgainstPlayer(1);
        vm.stopPrank();
    }

    event MoveSaved(address indexed player, uint vrf);

    function test_PlayAgainstPlayer_FirstPlayer() public {

        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectEmit();
        emit MoveSaved(player1, 0);
        tournamentY.playAgainstPlayer(1);

        vm.stopPrank();
    }

    event Draw(address indexed player, address indexed opponent, uint256 day);

    function test_PlayAgainstPlayer_RockRock() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Draw(player2, player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(0);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 2);
        assertEq(tournamentY.pointsOfPlayer(player2), 2);
    }

    function test_PlayAgainstPlayer_PaperPaper() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(1, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Draw(player2, player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(1);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 2);
        assertEq(tournamentY.pointsOfPlayer(player2), 2);
    }

    function test_PlayAgainstPlayer_ScissorsScissors() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(2, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Draw(player2, player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(2);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 2);
        assertEq(tournamentY.pointsOfPlayer(player2), 2);
    }

    event Winner(address indexed player, uint256 day);

	event Loser(address indexed player, uint256 day);

    function test_PlayAgainstPlayer_RockPaper() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player2, block.timestamp / (60 * 60 * 24));
        emit Loser(player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(1);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 4);
    }

    function test_PlayAgainstPlayer_RockScissors() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(2);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 4);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
    }

    function test_PlayAgainstPlayer_PaperRock() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(1, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(0);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 4);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
    }

    function test_PlayAgainstPlayer_PaperScissors() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(1, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player2, block.timestamp / (60 * 60 * 24));
        emit Loser(player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(2);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 4);
    }

    function test_PlayAgainstPlayer_ScissorsRock() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(2, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player2, block.timestamp / (60 * 60 * 24));
        emit Loser(player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(0);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 4);
    }

    function test_PlayAgainstPlayer_ScissorsPaper() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(2, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(1);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 4);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
    }

    function test_PlayAgainstPlayer_4Players() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
        assertEq(tournamentY.pointsOfPlayer(player3), 0);
        assertEq(tournamentY.pointsOfPlayer(player4), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(2);

        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);
        vm.startPrank(player4);

        vm.expectEmit();
        emit Draw(player4, player3, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(1);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 4);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
        assertEq(tournamentY.pointsOfPlayer(player3), 2);
        assertEq(tournamentY.pointsOfPlayer(player4), 2);
        assertEq(tournamentY.topScore(), 4);
    }

    function test_PlayAgainstPlayer_4Players_2Days() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
        assertEq(tournamentY.pointsOfPlayer(player3), 0);
        assertEq(tournamentY.pointsOfPlayer(player4), 0);

        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(2);

        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);
        vm.startPrank(player4);

        vm.expectEmit();
        emit Draw(player4, player3, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(1);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 4);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
        assertEq(tournamentY.pointsOfPlayer(player3), 2);
        assertEq(tournamentY.pointsOfPlayer(player4), 2);
        assertEq(tournamentY.topScore(), 4);

        skip(1 days);

        vm.prank(player1);
        tournamentY.playAgainstPlayer(1);
        vm.prank(player3);
        tournamentY.playAgainstPlayer(2);
        vm.prank(player2);
        tournamentY.playAgainstPlayer(0);
        vm.prank(player4);
        tournamentY.playAgainstPlayer(0);

        assertEq(tournamentY.pointsOfPlayer(player1), 4);
        assertEq(tournamentY.pointsOfPlayer(player2), 2);
        assertEq(tournamentY.pointsOfPlayer(player3), 6);
        assertEq(tournamentY.pointsOfPlayer(player4), 4);
        assertEq(tournamentY.topScore(), 6);
    }

    function test_alreadyPlayed_notStaked() public {
        vm.warp(startTime + 2 days);
        assertEq(tournamentY.alreadyPlayed(player1), false);
    }

    function test_alreadyPlayed_stakedNotPlayed() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        assertEq(tournamentY.alreadyPlayed(player1), false);
    }

    function test_alreadyPlayed_playedToday() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.prank(player1);
        tournamentY.playAgainstPlayer(0);

        assertEq(tournamentY.alreadyPlayed(player1), true);
    }

    function test_alreadyPlayed_playedYesterday() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        vm.prank(player1);
        tournamentY.playAgainstPlayer(0);

        vm.warp(startTime + 3 days);
        assertEq(tournamentY.alreadyPlayed(player1), false);
    }

    function test_getRank() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        vm.startPrank(player4);
        tournamentY.playAgainstPlayer(1);
        vm.stopPrank();

        (uint256 rank1, uint256 split1) = tournamentY.getRank(player1);
        assertEq(rank1, 1);
        assertEq(split1, 1);
        (uint256 rank2, uint256 split2) = tournamentY.getRank(player2);
        assertEq(rank2, 3);
        assertEq(split2, 1);
        (uint256 rank3, uint256 split3) = tournamentY.getRank(player3);
        assertEq(rank3, 2);
        assertEq(split3, 2);
        (uint256 rank4, uint256 split4) = tournamentY.getRank(player4);
        assertEq(rank4, 2);
        assertEq(split4, 2);
    }

    function test_getRank_notPlayer() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        vm.startPrank(player4);
        tournamentY.playAgainstPlayer(1);
        vm.stopPrank();

        (uint rank, uint split) = tournamentY.getRank(player5);
        assertEq(rank, 0);
        assertEq(split, 0);
    }

    function test_getPrizeShare_1Player() public {
        vm.warp(startTime + 2 days);
        stakeForTest(player1);
        
        assertEq(tournamentY.getPrizeShare(player1), 0.5 ether);
        assertEq(tournamentU.getPrizeShare(player1), 0.5 ether);
    }

    function test_getPrizeShare_4Players() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        vm.startPrank(player4);
        tournamentY.playAgainstPlayer(1);
        tournamentU.playAgainstPlayer(1);
        vm.stopPrank();
        
        assertEq(tournamentY.getPrizeShare(player1), 0.5 ether);
        assertEq(tournamentY.getPrizeShare(player2), 0.125 ether);
        assertEq(tournamentY.getPrizeShare(player3), 0.125 ether);
        assertEq(tournamentY.getPrizeShare(player4), 0.125 ether);
        assertEq(tournamentY.getPrizeShare(player5), 0); // Not a player
        assertEq(tournamentU.getPrizeShare(player1), 0.5 ether);
        assertEq(tournamentU.getPrizeShare(player2), 0.125 ether);
        assertEq(tournamentU.getPrizeShare(player3), 0.125 ether);
        assertEq(tournamentU.getPrizeShare(player4), 0.125 ether);
        assertEq(tournamentU.getPrizeShare(player5), 0); // Not a player
    }

    function test_getPoolPrize_noPlayer() public {
        assertEq(tournamentY.getPoolPrize(), 0);
        assertEq(tournamentU.getPoolPrize(), 0);
    }

    function test_getPoolPrize_noValorization_noWithdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);
        vm.stopPrank();

        assertEq(tournamentY.getPoolPrize(), 0);
        assertEq(tournamentU.getPoolPrize(), 0);
    }

    function test_getPoolPrize_valorization_noWithdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);
        vm.stopPrank();

        mockYLP.setPricePerShare(200000); // Value of LP doubled
        mockUniLP.setReserves(200000, 200000);
        uint contractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint contractBalanceU = mockUniLP.balanceOf(address(tournamentU));
        uint fees = tournamentY.fees();

        assertEq(tournamentY.getPoolPrize(), contractBalanceY * (1 ether - fees) / 2 ether);
        assertEq(tournamentU.getPoolPrize(), contractBalanceU * (1 ether - fees) / 2 ether);
    }

    function test_getPoolPrize_noValorization_withdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);

        vm.warp(endTime + 2 days);
        tournamentY.unstakeLPToken();
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(tournamentY.getPoolPrize(), 0);
        assertEq(tournamentU.getPoolPrize(), 0);
    }

    function test_getPoolPrize_valorizationBeforeWithdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(200000, 200000);

        uint contractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint contractBalanceU = mockUniLP.balanceOf(address(tournamentU));
        uint fees = tournamentY.fees();
        
        vm.warp(endTime + 2 days);
        tournamentY.unstakeLPToken();
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(tournamentY.getPoolPrize(), contractBalanceY * (1 ether - fees) / 2 ether);
        assertEq(tournamentU.getPoolPrize(), contractBalanceU * (1 ether - fees) / 2 ether);
    }

    function test_getPoolPrize_valorizationBeforeAfterWithdrawal() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(200000, 200000);

        uint fees = tournamentY.fees();
        
        vm.warp(endTime + 2 days);
        tournamentY.unstakeLPToken();
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        mockYLP.setPricePerShare(400000); // Value of LP doubles again
        mockUniLP.setReserves(400000, 400000);

        assertEq(tournamentY.getPoolPrize(), LPTokenAmount * (1 ether - fees) / 2 ether + LPTokenAmount * (1 ether - fees) * 3 / 4 ether);
        assertEq(tournamentU.getPoolPrize(), LPTokenAmount * (1 ether - fees) / 2 ether + LPTokenAmount * (1 ether - fees) * 3 / 4 ether);
    }

    function test_getPrizeAmount_noValorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);
        vm.stopPrank();

        assertEq(tournamentY.getPrizeAmount(player1), 0);
        assertEq(tournamentY.getPrizeAmount(player2), 0);
        assertEq(tournamentU.getPrizeAmount(player1), 0);
        assertEq(tournamentU.getPrizeAmount(player2), 0);
    }

    function test_getPrizeAmount_devalorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);
        vm.stopPrank();

        mockYLP.setPricePerShare(50000); // Value of LP drops
        mockUniLP.setReserves(50000, 50000);

        assertEq(tournamentY.getPrizeAmount(player1), 0);
        assertEq(tournamentY.getPrizeAmount(player2), 0);
        assertEq(tournamentU.getPrizeAmount(player1), 0);
        assertEq(tournamentU.getPrizeAmount(player2), 0);
    }

    function test_getPrizeAmount_valorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);
        vm.stopPrank();

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(200000, 200000);

        assertEq(tournamentY.getPrizeAmount(player1), tournamentY.getPoolPrize() * 5 / 10);
        assertEq(tournamentY.getPrizeAmount(player2), tournamentY.getPoolPrize() * 25 / 100);
        assertEq(tournamentU.getPrizeAmount(player1), tournamentU.getPoolPrize() * 5 / 10);
        assertEq(tournamentU.getPrizeAmount(player2), tournamentU.getPoolPrize() * 25 / 100);
    }

    function test_getExpectedPoolPrize_noValorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);
        vm.stopPrank();

        vm.warp(startTime + 7 days);

        assertEq(tournamentY.getExpectedPoolPrize(), 0);
        assertEq(tournamentU.getExpectedPoolPrize(), 0);
    }

    function test_getExpectedPoolPrize_devalorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);
        vm.stopPrank();

        vm.warp(startTime + 7 days);
        mockYLP.setPricePerShare(50000); // Value of LP drops
        mockUniLP.setReserves(50000, 50000);

        assertEq(tournamentU.getExpectedPoolPrize(), 0);
    }

    function test_getExpectedPoolPrize_valorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        tournamentU.playAgainstPlayer(2);
        vm.stopPrank();

        vm.warp(startTime + 7 days);
        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(200000, 200000);

        assertEq(tournamentY.getExpectedPoolPrize(), tournamentY.getPoolPrize() * 30 / 7);
        assertEq(tournamentU.getExpectedPoolPrize(), tournamentU.getPoolPrize() * 30 / 7);
    }

    function test_getExpectedPoolPrize_future() public {
        vm.warp(startTime - 2 days);
        stakeForTest(player1);
        stakeForTest(player2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(200000, 200000);

        assertEq(tournamentY.getExpectedPoolPrize(), 0);
        assertEq(tournamentU.getExpectedPoolPrize(), 0);
    }

    function test_getFees_noValorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        vm.stopPrank();

        assertEq(tournamentY.getFees(), 0);
    }

    function test_getFees_valorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        vm.stopPrank();

        mockYLP.setPricePerShare(200000); // Value of LP doubled
        uint contractBalance = mockYLP.balanceOf(address(tournamentY));
        uint fees = tournamentY.fees();

        assertEq(tournamentY.getFees(), contractBalance * fees / 2 ether);
    }

    function test_getFees_devalorization() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        vm.stopPrank();

        mockYLP.setPricePerShare(50000); // Value of LP drops

        assertEq(tournamentY.getFees(), 0);
    }

    function test_getNumberOfPlayers_noPlayer() public {
        assertEq(tournamentY.getNumberOfPlayers(), 0);
    }

    function test_getNumberOfPlayers_onePlayer() public {
        vm.warp(startTime - 2 days);
        stakeForTest(player1);

        assertEq(tournamentY.getNumberOfPlayers(), 1);
    }

    function test_getNumberOfPlayers_twoPlayers() public {
        vm.warp(startTime - 2 days);
        stakeForTest(player1);
        stakeForTest(player2);

        assertEq(tournamentY.getNumberOfPlayers(), 2);
    }

    function test_getPlayersAtScore() public {
        vm.warp(startTime + 2 days);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(2);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        vm.startPrank(player4);
        tournamentY.playAgainstPlayer(1);
        vm.stopPrank();
        
        assertEq(keccak256(abi.encodePacked(tournamentY.getPlayersAtScore(4))), keccak256(abi.encodePacked([address(player1)])));
        assertEq(keccak256(abi.encodePacked(tournamentY.getPlayersAtScore(0))), keccak256(abi.encodePacked(new address[](0))));
        assertEq(keccak256(abi.encodePacked(tournamentY.getPlayersAtScore(2))), keccak256(abi.encodePacked([address(player4), address(player3)])));
    }


}

