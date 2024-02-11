// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Test, stdStorage, StdStorage} from "../../lib/forge-std/src/Test.sol";
import {console2} from "../../lib/forge-std/src/console2.sol";
import {Tournament} from "../../contracts/Tournament.sol";
import {TournamentFactory} from "../../contracts/TournamentFactory.sol";
import {Vyper_contract} from "../../contracts/Vyper_contract.sol"; // Mock Yearn LP
import {UniswapV2Pair} from "../../contracts/UniswapV2Pair.sol"; // Mock Uniswap LP
import {USDT} from "../../contracts/USDT.sol"; // Mock USDT
import {WETH} from "../../contracts/WETH.sol"; // Mock WETH
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";// Mock VRF Coordinator

/**
 *  // Mocks a call to an address, returning specified data. -- can use this to mock the VRF Coordinator
    //
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    
    function mockCall(address, bytes calldata, bytes calldata) external;
 */

contract TournamentExposed is Tournament {
    function _getFees() public view returns (uint) {
        return getFees();
    }
}

// contract TournamentFactory {
//     function getVrfConfig() external view returns (uint64, bytes32, uint32) {
// 		return (uint64(1), bytes32("0x123456789"), uint32(1000000));
// 	}
// }

contract TournamentTest is Test {
    using stdStorage for StdStorage;

    TournamentFactory public factory;
    TournamentExposed public tournamentU;
    TournamentExposed public tournamentY;
    USDT public mockUSDT;
    WETH public mockWETH;
    UniswapV2Pair public mockUniLP;
    Vyper_contract public mockYLP;
    VRFCoordinatorV2Mock public mockVRF;

    // Define parameters for Tournament constructor
    uint256 LPTokenAmount = 1e18; // 1 LP Token
    uint32 startTime =  uint32(block.timestamp) + 30 days; // Start in 30 days
    uint32 endTime = startTime + 30 days; // End one week after start
    uint32 beforeTime = startTime - 2 days;
    uint32 duringTime = startTime + 2 days;
    uint32 afterTime = endTime + 2 days;

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
        bytes32 move = getMoveHash(tournamentU, _playerA, _move);
        tournamentU.playAgainstPlayer(move);
        move = getMoveHash(tournamentY, _playerA, _move);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();
        
        stakeForTest(_playerB);
    }

    function getMoveHash(Tournament _tournament, address _player, uint8 _move) public view returns (bytes32) {
        (bytes32 h0, bytes32 h1, bytes32 h2) = _tournament.hashMoves(_player);
        return _move == 0 ? h0 : _move == 1 ? h1 : h2;
    }

    function newAddress(uint _fuzz) public returns(address player) {
        vm.startPrank(owner);

        player = makeAddr(vm.toString(_fuzz));
        mockYLP.transfer(player, 1e18);
        mockUniLP.transfer(player, 1e18);

        vm.stopPrank();
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
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
        mockUSDT = new USDT();
        mockWETH = new WETH();
        mockUniLP = new UniswapV2Pair(address(mockWETH), address(mockUSDT));
        mockYLP = new Vyper_contract(address(mockUSDT));

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
        factory = new TournamentFactory(owner, address(mockVRF));
        factory.setChainlinkConfig(gasLane, callbackGasLimit);

        // create subscription ID
        (subId,,) = factory.getVrfConfig();
        // fund subscription
        mockVRF.fundSubscription(subId, 1000000000000000000);

        string memory name = "Yearn Tournament";
        // Deploy Tournament contract
        tournamentY = new TournamentExposed();
        tournamentY.initialize(
            owner, name, address(mockYLP), LPTokenAmount, 
            startTime, endTime, address(factory), address(mockVRF)
        );

        name = "Uniswap Tournament";
        // Deploy Tournament contract
        tournamentU = new TournamentExposed();
        tournamentU.initialize(
            owner, name, address(mockUniLP), LPTokenAmount, 
            startTime, endTime, address(factory), address(mockVRF)
        );

        vm.stopPrank();
        vm.prank(address(factory));
        // add tournament as consumer of VRF
        mockVRF.addConsumer(subId, address(tournamentY));

    }

    function testSetUp() public {
        assertEq(tournamentY.owner(), owner);
        assertEq(tournamentY.name(), "Yearn Tournament");
        //assertEq(tournamentY.poolIncentivized(), address(mockYLP));
        assertEq(tournamentY.depositAmount(), 1e18);
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
        vm.warp(beforeTime);
        assertEq(tournamentY.isActive(), false);
    }

    function test_isActive_during() public {
        vm.warp(duringTime);
        assertEq(tournamentY.isActive(), true);
    }

    function test_isActive_after() public {
        vm.warp(afterTime);
        assertEq(tournamentY.isActive(), false);
    }

    function test_isFuture_before() public {
        vm.warp(beforeTime);
        assertEq(tournamentY.isFuture(), true);
    }

    function test_isFuture_during() public {
        vm.warp(duringTime);
        assertEq(tournamentY.isFuture(), false);
    }

    function test_isFuture_after() public {
        vm.warp(afterTime);
        assertEq(tournamentY.isFuture(), false);
    }

    function test_isEnded_before() public {
        vm.warp(beforeTime);
        assertEq(tournamentY.isEnded(), false);
    }

    function test_isEnded_during() public {
        vm.warp(duringTime);
        assertEq(tournamentY.isEnded(), false);
    }

    function test_isEnded_after() public {
        vm.warp(afterTime);
        assertEq(tournamentY.isEnded(), true);
    }

    function test_stakingAllowed_before() public {
        vm.warp(beforeTime);
        assertEq(tournamentY.stakingAllowed(), true);
    }

    function test_stakingAllowed_during() public {
        vm.warp(duringTime);
        assertEq(tournamentY.stakingAllowed(), true);
    }

    function test_stakingAllowed_after() public {
        vm.warp(afterTime);
        assertEq(tournamentY.stakingAllowed(), false);
    }

    function test_unstakingAllowed_before() public {
        vm.warp(beforeTime);
        assertEq(tournamentY.unstakingAllowed(), false);
    }

    function test_unstakingAllowed_during() public {
        vm.warp(duringTime);
        assertEq(tournamentY.unstakingAllowed(), false);
    }

    function test_unstakingAllowed_after() public {
        vm.warp(afterTime);
        assertEq(tournamentY.unstakingAllowed(), true);
    }

    function test_getLPDecimals() public {
        assertEq(tournamentY.getLPDecimals(), 18);
    }

    function test_getLPSymbol() public {
        assertEq(keccak256(abi.encodePacked(tournamentY.getLPSymbol())), keccak256("yvUSDT"));
    }

    function test_getTournament() public {
        (
            string memory rName,
            address contractAddress,
            address rPoolIncentivized,
            string memory rLPTokenSymbol,
            uint8 rProtocol,
            address token0,
            address token1,
            uint256 rdepositAmount,
            uint8 rDecimals,
            uint256 rStartTime,
            uint256 rEndTime,
            uint256 rPlayers,
            uint256 rPoolPrize
        ) = tournamentY.getTournament();
        assertEq(keccak256(abi.encodePacked(rName)), keccak256(abi.encodePacked("Yearn Tournament")));
        assertEq(contractAddress, address(tournamentY));
        assertEq(rPoolIncentivized, address(mockYLP));
        assertEq(keccak256(abi.encodePacked(rLPTokenSymbol)), keccak256(abi.encodePacked("yvUSDT")));
        assertEq(rdepositAmount, 1e18);
        assertEq(rStartTime, startTime);
        assertEq(rEndTime, endTime);
        assertEq(rPlayers, 0);
    }

    function test_isPlayer() public {
        vm.warp(duringTime);

        stakeForTest(player1);

        assertEq(tournamentY.isPlayer(player1), true);
        assertEq(tournamentY.isPlayer(player2), false);
    }

    function test_getNumberOfPlayers() public {
        assertEq(tournamentY.getNumberOfPlayers(), 0);
        uint initPlayers = tournamentY.getNumberOfPlayers();

        vm.warp(duringTime);

        stakeForTest(player1);

        assertEq(tournamentY.getNumberOfPlayers(), initPlayers + 1);

        stakeForTest(player2);

        assertEq(tournamentY.getNumberOfPlayers(), initPlayers + 2);
    }

    function testFuzz_getNumberOfPlayers(uint8 nb) public {
        assertEq(tournamentY.getNumberOfPlayers(), 0);
        uint initPlayers = tournamentY.getNumberOfPlayers();

        vm.warp(duringTime);

        for (uint i = 0; i < nb; i++) {
            address player = newAddress(i);
            stakeForTest(player);
        }

        assertEq(tournamentY.getNumberOfPlayers(), initPlayers + nb);
    }

    function test_getPlayers() public {
        assertEq(keccak256(abi.encodePacked(tournamentY.getPlayers())), keccak256(abi.encodePacked(new address[](0))));

        vm.warp(duringTime);

        stakeForTest(player1);

        assertEq(tournamentY.getPlayers().length, 1);
        assertEq(tournamentY.players(0), player1);

        stakeForTest(player2);

        assertEq(tournamentY.getPlayers().length, 2);
        assertEq(tournamentY.players(0), player1);
        assertEq(tournamentY.players(1), player2);
    }

    event Staked(address indexed player, uint256 amount);

    function test_stakeLPToken_before() public {
        uint initBalanceY = mockYLP.balanceOf(player1);
        uint initBalanceU = mockUniLP.balanceOf(player1);

        vm.warp(beforeTime);

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

        vm.warp(duringTime);

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

        vm.warp(afterTime);

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

        vm.warp(duringTime);

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
        vm.warp(beforeTime);

        vm.startPrank(player1);

        vm.expectRevert();
        tournamentY.stakeLPToken();
        vm.stopPrank();
        
        assertEq(mockYLP.balanceOf(player1), initBalance);
        assertEq(mockYLP.balanceOf(address(tournamentY)), 0);
    }

    function test_getPricePerShare_Yearn() public {
        assertEq(tournamentY.getPricePerShare(), 100000);

        mockYLP.setPricePerShare(150000);

        assertEq(tournamentY.getPricePerShare(), 150000);

        mockYLP.setPricePerShare(50000);

        assertEq(tournamentY.getPricePerShare(), 50000);
    }

    function testFuzz_getPricePerShare_Yearn(uint _fuzz) public {
        mockYLP.setPricePerShare(_fuzz);

        assertEq(tournamentY.getPricePerShare(), _fuzz);
    }

    function test_getPricePerShare_Uniswap() public {
        vm.warp(startTime);

        assertEq(tournamentU.getPricePerShare(), 1000 ether);

        mockUniLP.setReserves(1500 ether, 2000 ether);

        assertEq(tournamentU.getPricePerShare(), 3000 ether);

        mockUniLP.setReserves(2500 ether, 500 ether);

        assertEq(tournamentU.getPricePerShare(), 1250 ether);

        mockUniLP.setTotalSupply(2000 ether);
        
        assertEq(tournamentU.getPricePerShare(), 1250 ether / 2);
    }

    function testFuzz_getPricePerShare_Uniswap(uint112 _fuzz0, uint112 _fuzz1) public {
        vm.assume(sqrt(uint(_fuzz0) * uint(_fuzz1)) >= 1000 ether); 
        vm.warp(startTime);

        mockUniLP.setReserves(_fuzz0, _fuzz1);

        assertEq(tournamentU.getPricePerShare(), uint(_fuzz0) * uint(_fuzz1) / 1000 ether);
    }

    function test_withdrawAmountFromDeposit_notValuated() public {
        vm.warp(duringTime);

        stakeForTest(player1);

        assertEq(tournamentY.withdrawAmountFromDeposit(player1), LPTokenAmount);
        assertEq(tournamentU.withdrawAmountFromDeposit(player1), LPTokenAmount);
    }

    function test_withdrawAmountFromDeposit_valuated() public {
        vm.warp(duringTime);

        stakeForTest(player1);

        mockYLP.setPricePerShare(150000);
        mockUniLP.setReserves(1500 ether, 2000 ether);
        mockUniLP.setTotalSupply(2000 ether);

        assertEq(tournamentY.withdrawAmountFromDeposit(player1), LPTokenAmount * 10 / 15);
        assertEq(tournamentU.withdrawAmountFromDeposit(player1), LPTokenAmount * 10 / 15);

        mockUniLP.setReserves(2000 ether, 1000 ether);
        mockUniLP.setTotalSupply(1000 ether);

        assertEq(tournamentU.withdrawAmountFromDeposit(player1), LPTokenAmount / 2);
    }

    function test_withdrawAmountFromDeposit_devaluated() public {
        vm.warp(duringTime);

        stakeForTest(player1);

        mockYLP.setPricePerShare(50000);
        mockUniLP.setReserves(500 ether, 500 ether);

        assertEq(tournamentY.withdrawAmountFromDeposit(player1), LPTokenAmount);
        assertEq(tournamentU.withdrawAmountFromDeposit(player1), LPTokenAmount);

        mockUniLP.setTotalSupply(2000 ether);

        assertEq(tournamentU.withdrawAmountFromDeposit(player1), LPTokenAmount);
    }

    function test_unstakeLPToken_before() public {
        vm.warp(beforeTime);

        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Unstaking not allowed");
        tournamentY.unstakeLPToken();
        vm.expectRevert("Unstaking not allowed");
        tournamentU.unstakeLPToken();
        vm.stopPrank();
    }

    function test_unstakeLPToken_during() public {
        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Unstaking not allowed");
        tournamentY.unstakeLPToken();
        vm.expectRevert("Unstaking not allowed");
        tournamentU.unstakeLPToken();
        vm.stopPrank();
   }

    function test_unstakeLPToken_notPlayer() public {
        vm.warp(afterTime);
        vm.startPrank(player1);

        vm.expectRevert("You have nothing to withdraw");
        tournamentY.unstakeLPToken();
        vm.expectRevert("You have nothing to withdraw");
        tournamentU.unstakeLPToken();
        vm.stopPrank();
    }

    function test_unstakeLPToken_noBalance() public {
        vm.warp(duringTime);
        stakeForTest(player1);

        uint initPlayerBalance = mockYLP.balanceOf(player1);
        uint initContractBalance = mockYLP.balanceOf(address(tournamentY));

        vm.prank(address(tournamentY));
        mockYLP.approve(address(this), initContractBalance);
        mockYLP.transferFrom(address(tournamentY), player2, initContractBalance);

        vm.warp(afterTime);
        vm.startPrank(player1);
        vm.expectRevert();
        tournamentY.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalance);
        assertEq(mockYLP.balanceOf(address(tournamentY)), 0);
    }

    event Unstaked(address indexed player, uint256 amount);

    function test_unstakeLPToken_after_notValuated() public {
        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        vm.warp(afterTime);
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

    function test_unstakeLPToken_after_notPlayed_devaluated() public {
        vm.warp(duringTime);
        stakeForTest(player1);
        stakeForTest(player2);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initPlayer2BalanceY = mockYLP.balanceOf(player2);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initPlayer2BalanceU = mockUniLP.balanceOf(player2);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        mockYLP.setPricePerShare(50000);
        mockUniLP.setReserves(500 ether, 500 ether);
        vm.warp(afterTime);
    
        vm.startPrank(player1);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentU.unstakeLPToken();
        vm.stopPrank();
   
        vm.startPrank(player2);
        vm.expectEmit();
        emit Unstaked(address(player2), LPTokenAmount);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player2), LPTokenAmount);
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalanceY + LPTokenAmount);
        assertEq(mockYLP.balanceOf(player2), initPlayer2BalanceY + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY - 2 * LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initPlayerBalanceU + LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player2), initPlayer2BalanceU + LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU - 2 * LPTokenAmount);
    }

    function test_unstakeLPToken_after_played_devaluated() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.prank(player2);
        tournamentY.playAgainstPlayer(move);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initPlayer2BalanceY = mockYLP.balanceOf(player2);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initPlayer2BalanceU = mockUniLP.balanceOf(player2);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        mockYLP.setPricePerShare(90000);
        mockUniLP.setReserves(900 ether, 900 ether);
        vm.warp(afterTime);

        vm.startPrank(player1);
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player1), LPTokenAmount);
        tournamentU.unstakeLPToken();
        vm.stopPrank();
   
        vm.startPrank(player2);
        vm.expectEmit();
        emit Unstaked(address(player2), LPTokenAmount);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player2), LPTokenAmount);
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player1), initPlayerBalanceY + LPTokenAmount);
        assertEq(mockYLP.balanceOf(player2), initPlayer2BalanceY + LPTokenAmount);
        assertEq(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY - 2 * LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player1), initPlayerBalanceU + LPTokenAmount);
        assertEq(mockUniLP.balanceOf(player2), initPlayer2BalanceU + LPTokenAmount);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU - 2 * LPTokenAmount);
    }

    function test_unstakeLPToken_after_played_valuated() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.prank(player2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        vm.prank(player2);
        tournamentU.playAgainstPlayer(move);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initPlayer2BalanceY = mockYLP.balanceOf(player2);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initPlayer2BalanceU = mockUniLP.balanceOf(player2);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        mockYLP.setPricePerShare(200000);
        mockUniLP.setReserves(2000 ether, 1000 ether);
        vm.warp(afterTime);

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
        emit Unstaked(address(player2), LPTokenAmount / 2 + 0.45 ether);
        tournamentY.unstakeLPToken();
        vm.expectEmit();
        emit Unstaked(address(player2), LPTokenAmount / 2 + 0.45 ether);
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(player2), initPlayer2BalanceY + LPTokenAmount / 2 + 0.45 ether);
        assertEq(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY - (LPTokenAmount + 0.45 ether + 0.45 ether));
        assertEq(mockUniLP.balanceOf(player2), initPlayer2BalanceU + LPTokenAmount / 2 + 0.45 ether);
        assertEq(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU - (LPTokenAmount + 0.45 ether + 0.45 ether));
    }

    function test_unstakeLPToken_after_played_valuated_noRemaining() public {
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.prank(player2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        vm.prank(player2);
        tournamentU.playAgainstPlayer(move);

        mockYLP.setPricePerShare(200000);
        mockUniLP.setReserves(2000 ether, 1000 ether);
        vm.warp(afterTime);

        vm.startPrank(player1);
        tournamentY.unstakeLPToken();
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        mockYLP.setPricePerShare(400000);
        mockUniLP.setReserves(2000 ether, 1500 ether);
        
        vm.startPrank(player2);
        tournamentY.unstakeLPToken();
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertApproxEqAbs(mockYLP.balanceOf(address(tournamentY)), initContractBalanceY + tournamentY._getFees(), 1);
        assertApproxEqAbs(mockUniLP.balanceOf(address(tournamentU)), initContractBalanceU + tournamentU._getFees(), 1);
    }

    function test_unstakeLPToken_twice() public {
        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        uint initPlayerBalanceY = mockYLP.balanceOf(player1);
        uint initContractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint initPlayerBalanceU = mockUniLP.balanceOf(player1);
        uint initContractBalanceU = mockUniLP.balanceOf(address(tournamentU));

        vm.warp(afterTime);
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
                
        vm.warp(duringTime);
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

    function test_PlayAgainstContract_invalidMove() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Invalid move");
        tournamentY.playAgainstContract(3);
        vm.stopPrank();
    }

    function test_PlayAgainstContract_before() public {

        vm.warp(beforeTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Tournament is not active");
        tournamentY.playAgainstContract(1);
        vm.stopPrank();
    }

    function test_PlayAgainstContract_after() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.warp(afterTime);
        vm.expectRevert("Tournament is not active");
        tournamentY.playAgainstContract(1);
        vm.stopPrank();
    }

    function test_PlayAgainstContract_notPlayer() public {

        vm.warp(duringTime);
        vm.startPrank(player1);

        vm.expectRevert("You must deposit before playing");        
        tournamentY.playAgainstContract(1);

        vm.stopPrank();
    }

    function test_PlayAgainstContract_twice() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);
        tournamentY.playAgainstContract(1);

        vm.expectRevert("You already played today");
        tournamentY.playAgainstContract(1);
        vm.stopPrank();
    }

    event MoveSaved(address indexed player, uint vrf);

    function test_PlayAgainstContract_unresolved() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectEmit();
        emit MoveSaved(player1, 1);
        tournamentY.playAgainstContract(1);

        vm.stopPrank();
    }

    event Draw(address indexed player, address indexed opponent, uint256 day);

    function test_PlayAgainstContract_invalidRequest() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectEmit();
        emit MoveSaved(player1, 1);
        tournamentY.playAgainstContract(1);

        uint[] memory randomWords = new uint[](1);
        randomWords[0] = 1;

        vm.expectRevert("nonexistent request");
        mockVRF.fulfillRandomWordsWithOverride(10, address(tournamentY), randomWords);

        vm.stopPrank();
    }

    function test_PlayAgainstContract_resolvedDraw() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectEmit();
        emit MoveSaved(player1, 1);
        tournamentY.playAgainstContract(1);

        uint[] memory randomWords = new uint[](1);
        randomWords[0] = 1;

        vm.expectEmit();
        emit Draw(player1, address(0), block.timestamp / (60 * 60 * 24));
        mockVRF.fulfillRandomWordsWithOverride(1, address(tournamentY), randomWords);

        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_invalidMove() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.expectRevert("Invalid move");
        tournamentY.playAgainstPlayer(bytes32('0xdeadbeef'));
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_before() public {

        vm.warp(beforeTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        bytes32 move = getMoveHash(tournamentY, player1, 1);
        vm.expectRevert("Tournament is not active");
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_after() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        vm.warp(afterTime);
        bytes32 move = getMoveHash(tournamentY, player1, 1);
        vm.expectRevert("Tournament is not active");
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_notPlayer() public {

        vm.warp(duringTime);
        vm.startPrank(player1);

        bytes32 move = getMoveHash(tournamentY, player1, 1);
        vm.expectRevert("You must deposit before playing");
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_twice() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        bytes32 move = getMoveHash(tournamentY, player1, 1);
        vm.startPrank(player1);
        tournamentY.playAgainstPlayer(move);

        move = getMoveHash(tournamentY, player1, 1);
        vm.expectRevert("You already played today");
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_firstPlayer() public {

        vm.warp(duringTime);
        stakeForTest(player1);
        vm.startPrank(player1);

        bytes32 move = getMoveHash(tournamentY, player1, 1);
        vm.expectEmit();
        emit MoveSaved(player1, 0);
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();
    }

    function test_PlayAgainstPlayer_RockRock() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 0);
        vm.expectEmit();
        emit Draw(player2, player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 1);
        assertEq(tournamentY.pointsOfPlayer(player2), 1);
    }

    function test_PlayAgainstPlayer_PaperPaper() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(1, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 1);
        vm.expectEmit();
        emit Draw(player2, player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 1);
        assertEq(tournamentY.pointsOfPlayer(player2), 1);
    }

    function test_PlayAgainstPlayer_ScissorsScissors() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(2, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.expectEmit();
        emit Draw(player2, player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 1);
        assertEq(tournamentY.pointsOfPlayer(player2), 1);
    }

    event Winner(address indexed player, uint256 day);

	event Loser(address indexed player, uint256 day);

    function test_PlayAgainstPlayer_RockPaper() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 1);
        vm.expectEmit();
        emit Winner(player2, block.timestamp / (60 * 60 * 24));
        emit Loser(player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 2);
    }

    function test_PlayAgainstPlayer_RockScissors() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 2);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
    }

    function test_PlayAgainstPlayer_PaperRock() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(1, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 0);
        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 2);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
    }

    function test_PlayAgainstPlayer_PaperScissors() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(1, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.expectEmit();
        emit Winner(player2, block.timestamp / (60 * 60 * 24));
        emit Loser(player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 2);
    }

    function test_PlayAgainstPlayer_ScissorsRock() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(2, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 0);
        vm.expectEmit();
        emit Winner(player2, block.timestamp / (60 * 60 * 24));
        emit Loser(player1, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 2);
    }

    function test_PlayAgainstPlayer_ScissorsPaper() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(2, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 1);
        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 2);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
    }

    function test_PlayAgainstPlayer_4Players() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
        assertEq(tournamentY.pointsOfPlayer(player3), 0);
        assertEq(tournamentY.pointsOfPlayer(player4), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);
        vm.startPrank(player4);

        move = getMoveHash(tournamentY, player4, 1);
        vm.expectEmit();
        emit Draw(player4, player3, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 2);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
        assertEq(tournamentY.pointsOfPlayer(player3), 1);
        assertEq(tournamentY.pointsOfPlayer(player4), 1);
        assertEq(tournamentY.topScore(), 2);
    }

    function test_PlayAgainstPlayer_4Players_2Days() public {
        assertEq(tournamentY.pointsOfPlayer(player1), 0);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
        assertEq(tournamentY.pointsOfPlayer(player3), 0);
        assertEq(tournamentY.pointsOfPlayer(player4), 0);

        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);
        vm.startPrank(player2);

        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.expectEmit();
        emit Winner(player1, block.timestamp / (60 * 60 * 24));
        emit Loser(player2, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);
        vm.startPrank(player4);

        move = getMoveHash(tournamentY, player4, 1);
        vm.expectEmit();
        emit Draw(player4, player3, block.timestamp / (60 * 60 * 24));
        tournamentY.playAgainstPlayer(move);

        vm.stopPrank();

        assertEq(tournamentY.pointsOfPlayer(player1), 2);
        assertEq(tournamentY.pointsOfPlayer(player2), 0);
        assertEq(tournamentY.pointsOfPlayer(player3), 1);
        assertEq(tournamentY.pointsOfPlayer(player4), 1);
        assertEq(tournamentY.topScore(), 2);

        skip(1 days);

        move = getMoveHash(tournamentY, player1, 1);
        vm.prank(player1);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentY, player3, 2);
        vm.prank(player3);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentY, player2, 0);
        vm.prank(player2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentY, player4, 0);
        vm.prank(player4);
        tournamentY.playAgainstPlayer(move);

        assertEq(tournamentY.pointsOfPlayer(player1), 2);
        assertEq(tournamentY.pointsOfPlayer(player2), 1);
        assertEq(tournamentY.pointsOfPlayer(player3), 3);
        assertEq(tournamentY.pointsOfPlayer(player4), 2);
        assertEq(tournamentY.topScore(), 3);
    }

    function test_alreadyPlayed_notStaked() public {
        vm.warp(duringTime);
        assertEq(tournamentY.alreadyPlayed(player1), false);
    }

    function test_alreadyPlayed_stakedNotPlayed() public {
        vm.warp(duringTime);
        stakeForTest(player1);
        assertEq(tournamentY.alreadyPlayed(player1), false);
    }

    function test_alreadyPlayed_playedToday() public {
        vm.warp(duringTime);
        stakeForTest(player1);
        bytes32 move = getMoveHash(tournamentY, player1, 0);
        vm.prank(player1);
        tournamentY.playAgainstPlayer(move);

        assertEq(tournamentY.alreadyPlayed(player1), true);
    }

    function test_alreadyPlayed_playedYesterday() public {
        vm.warp(duringTime);
        stakeForTest(player1);
        bytes32 move = getMoveHash(tournamentY, player1, 0);
        vm.prank(player1);
        tournamentY.playAgainstPlayer(move);

        skip(1 days);
        assertEq(tournamentY.alreadyPlayed(player1), false);
    }

    function test_getRank() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        move = getMoveHash(tournamentY, player4, 1);
        vm.startPrank(player4);
        tournamentY.playAgainstPlayer(move);
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
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        bytes32 move = getMoveHash(tournamentY, player2, 2);
        vm.startPrank(player2);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        move = getMoveHash(tournamentY, player4, 1);
        vm.startPrank(player4);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();

        (uint rank, uint split) = tournamentY.getRank(player5);
        assertEq(rank, 0);
        assertEq(split, 0);
    }

    function test_getPrizeShare_1Player() public {
        vm.warp(duringTime);
        stakeForTest(player1);
        
        assertEq(tournamentY.getPrizeShare(player1), 1 ether);
        assertEq(tournamentU.getPrizeShare(player1), 1 ether);
    }

    function test_getPrizeShare_4Players() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        vm.startPrank(player4);
        move = getMoveHash(tournamentY, player4, 1);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player4, 1);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();
        
        assertEq(tournamentY.getPrizeShare(player1), 0.5 ether);
        assertEq(tournamentY.getPrizeShare(player2), 0.25 ether);
        assertEq(tournamentY.getPrizeShare(player3), 0.125 ether);
        assertEq(tournamentY.getPrizeShare(player4), 0.125 ether);
        assertEq(tournamentY.getPrizeShare(player5), 0); // Not a player
        assertEq(tournamentU.getPrizeShare(player1), 0.5 ether);
        assertEq(tournamentU.getPrizeShare(player2), 0.25 ether);
        assertEq(tournamentU.getPrizeShare(player3), 0.125 ether);
        assertEq(tournamentU.getPrizeShare(player4), 0.125 ether);
        assertEq(tournamentU.getPrizeShare(player5), 0); // Not a player
    }

    function test_getPoolPrize_noPlayer() public {
        assertEq(tournamentY.getPoolPrize(), 0);
        assertEq(tournamentU.getPoolPrize(), 0);
    }

    function test_getPoolPrize_noValuation_noWithdrawal() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();

        assertEq(tournamentY.getPoolPrize(), 0);
        assertEq(tournamentU.getPoolPrize(), 0);
    }

    function test_getPoolPrize_valuation_noWithdrawal() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();

        mockYLP.setPricePerShare(200000); // Value of LP doubled
        mockUniLP.setReserves(2000 ether, 1000 ether);
        uint contractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint contractBalanceU = mockUniLP.balanceOf(address(tournamentU));
        uint fees = tournamentY.fees();

        assertEq(tournamentY.getPoolPrize(), contractBalanceY * (1 ether - fees) / 2 ether);
        assertEq(tournamentU.getPoolPrize(), contractBalanceU * (1 ether - fees) / 2 ether);
    }

    function test_getPoolPrize_noValuation_withdrawal() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);

        vm.warp(afterTime);
        tournamentY.unstakeLPToken();
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(tournamentY.getPoolPrize(), 0);
        assertEq(tournamentU.getPoolPrize(), 0);
    }

    function test_getPoolPrize_valuationBeforeWithdrawal() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(2000 ether, 1000 ether);

        uint contractBalanceY = mockYLP.balanceOf(address(tournamentY));
        uint contractBalanceU = mockUniLP.balanceOf(address(tournamentU));
        uint fees = tournamentY.fees();
        
        vm.warp(afterTime);
        tournamentY.unstakeLPToken();
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        assertEq(tournamentY.getPoolPrize(), contractBalanceY * (1 ether - fees) / 2 ether);
        assertEq(tournamentU.getPoolPrize(), contractBalanceU * (1 ether - fees) / 2 ether);
    }

    function test_getPoolPrize_valuationBeforeAfterWithdrawal() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(2000 ether, 1000 ether);

        uint fees = tournamentY.fees();
        
        vm.warp(afterTime);
        tournamentY.unstakeLPToken();
        tournamentU.unstakeLPToken();
        vm.stopPrank();

        mockYLP.setPricePerShare(400000); // Value of LP doubles again
        mockUniLP.setReserves(2000 ether, 2000 ether);

        assertEq(tournamentY.getPoolPrize(), LPTokenAmount * (1 ether - fees) / 2 ether + LPTokenAmount * (1 ether - fees) * 3 / 4 ether);
        assertEq(tournamentU.getPoolPrize(), LPTokenAmount * (1 ether - fees) / 2 ether + LPTokenAmount * (1 ether - fees) * 3 / 4 ether);
    }

    function test_getPrizeAmount_noValuation() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();

        assertEq(tournamentY.getPrizeAmount(player1), 0);
        assertEq(tournamentY.getPrizeAmount(player2), 0);
        assertEq(tournamentU.getPrizeAmount(player1), 0);
        assertEq(tournamentU.getPrizeAmount(player2), 0);
    }

    function test_getPrizeAmount_devaluation() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();

        mockYLP.setPricePerShare(50000); // Value of LP drops
        mockUniLP.setReserves(500 ether, 500 ether);

        assertEq(tournamentY.getPrizeAmount(player1), 0);
        assertEq(tournamentY.getPrizeAmount(player2), 0);
        assertEq(tournamentU.getPrizeAmount(player1), 0);
        assertEq(tournamentU.getPrizeAmount(player2), 0);
    }

    function test_getPrizeAmount_valuation() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(2000 ether, 2000 ether);

        assertEq(tournamentY.getPrizeAmount(player1), tournamentY.getPoolPrize() * 5 / 10);
        assertEq(tournamentY.getPrizeAmount(player2), tournamentY.getPoolPrize() * 5 / 10);
        assertEq(tournamentU.getPrizeAmount(player1), tournamentU.getPoolPrize() * 5 / 10);
        assertEq(tournamentU.getPrizeAmount(player2), tournamentU.getPoolPrize() * 5 / 10);
    }

    function test_getExpectedPoolPrize_noValuation() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();

        vm.warp(startTime + 7 days);

        assertEq(tournamentY.getExpectedPoolPrize(), 0);
        assertEq(tournamentU.getExpectedPoolPrize(), 0);
    }

    function test_getExpectedPoolPrize_devaluation() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();

        vm.warp(startTime + 7 days);
        mockYLP.setPricePerShare(50000); // Value of LP drops
        mockUniLP.setReserves(500 ether, 500 ether);

        assertEq(tournamentU.getExpectedPoolPrize(), 0);
    }

    function test_getExpectedPoolPrize_valuation() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        move = getMoveHash(tournamentU, player2, 2);
        tournamentU.playAgainstPlayer(move);
        vm.stopPrank();

        vm.warp(startTime + 7 days - 1); // 1s is added in the function
        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(2000 ether, 2000 ether);

        assertEq(tournamentY.getExpectedPoolPrize(), tournamentY.getPoolPrize() * 30 / 7);
        assertEq(tournamentU.getExpectedPoolPrize(), tournamentU.getPoolPrize() * 30 / 7);
    }

    function test_getExpectedPoolPrize_future() public {
        vm.warp(beforeTime);
        stakeForTest(player1);
        stakeForTest(player2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(2000 ether, 2000 ether);

        assertEq(tournamentY.getExpectedPoolPrize(), 0);
        assertEq(tournamentU.getExpectedPoolPrize(), 0);
    }

    function test_getFees_noValuation() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();

        assertEq(tournamentY._getFees(), 0);
    }

    function test_getFees_valuation() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();

        mockYLP.setPricePerShare(200000); // Value of LP doubled
        uint contractBalance = mockYLP.balanceOf(address(tournamentY));
        uint fees = tournamentY.fees();

        assertEq(tournamentY._getFees(), contractBalance * fees / 2 ether);
    }

    function test_getFees_devaluation() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();

        mockYLP.setPricePerShare(50000); // Value of LP drops

        assertEq(tournamentY._getFees(), 0);
    }

    function test_withdrawFees_notOwner() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(2000 ether, 2000 ether);

        vm.startPrank(player1);
        vm.expectRevert("Not the Owner");
        tournamentY.withdrawFees();
        vm.stopPrank();
    }

    function test_withdrawFees_ownerNoWithdrawal() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(2000 ether, 2000 ether);

        vm.startPrank(owner);
        vm.expectRevert("No fees to withdraw");
        tournamentY.withdrawFees();
        vm.stopPrank();
    }

    function test_withdrawFees_ownerWithdrawal() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        mockYLP.setPricePerShare(200000); // Value of LP doubles
        mockUniLP.setReserves(2000 ether, 2000 ether);

        vm.warp(afterTime);
        vm.startPrank(player1);
        tournamentY.unstakeLPToken();
        vm.stopPrank();

        uint initBalance = mockYLP.balanceOf(address(owner));

        vm.startPrank(owner);
        tournamentY.withdrawFees();
        vm.stopPrank();

        assertEq(mockYLP.balanceOf(address(owner)), initBalance + 0.05 ether);
    }

    function test_getPlayersAtScore() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();

        stakePlayStakeForTest(1, player3, player4);

        vm.startPrank(player4);
        move = getMoveHash(tournamentY, player4, 1);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();
        
        assertEq(keccak256(abi.encodePacked(tournamentY.getPlayersAtScore(2))), keccak256(abi.encodePacked([address(player1)])));
        assertEq(keccak256(abi.encodePacked(tournamentY.getPlayersAtScore(0))), keccak256(abi.encodePacked(new address[](0))));
        assertEq(keccak256(abi.encodePacked(tournamentY.getPlayersAtScore(1))), keccak256(abi.encodePacked([address(player4), address(player3)])));
    }

    function test_getPlayer() public {
        vm.warp(duringTime);
        stakePlayStakeForTest(0, player1, player2);

        vm.startPrank(player2);
        bytes32 move = getMoveHash(tournamentY, player2, 2);
        tournamentY.playAgainstPlayer(move);
        vm.stopPrank();

        (uint rank, uint score, uint lastGame) = tournamentY.getPlayer(player1);
        assertEq(rank, 1);
        assertEq(score, 2);
        assertEq(lastGame, block.timestamp);
    }

    function test_getFancySymbol() public {
        assertEq(tournamentU.getFancySymbol(), "UNI-V2 (WETH-USDT)");
    }

}

