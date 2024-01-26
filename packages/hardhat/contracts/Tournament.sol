//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract YearnInterface {
	function pricePerShare() public view returns (uint256);
}

contract UniswapInterface {
	function getReserves() public view returns (uint256, uint256, uint256);
	function totalSupply() public view returns (uint256);
}

contract Tournament {
	// State Variables
	address public immutable owner;
	// mapping(address => uint256) public playerToLPToken; // how much LP token each player has deposited
	mapping(address => uint256) public playerToScore; // how many points each player has
	mapping(address => uint256) public playerToLastGame; // when the player last played
	mapping(address => uint256) public playerToDepositPricePerShare; // price per share at deposit
	mapping(address => uint256) public playerToDepositPricePerShare2; // price per share at deposit
	address[] public players;
	// uint256 public numPlayers;
	string public name;
	uint256 public contractLPToken; // amount of LP token held by the contract
	IERC20Metadata poolIncentivized;
	string public LPTokenSymbol;
	uint256 public LPTokenAmount;
	uint256 public startTime;
	uint256 public endTime;
	uint256 public totalUnconvertedScore;
	uint256 realizedPoolPrize;
	uint256 realizedFees;
	uint256 unclaimedPoolPrize = 1 ether; // 100% of the pool prize unclaimed
	Protocol public protocol;
	uint256 public fees = 0.1 ether; // 10% fees on pool prize
	uint256 topScore = 0;
	mapping(uint256 => address[]) public scoreToPlayers;

	enum Protocol {
		Uniswap,
		Yearn
	}

	// Events: a way to emit log statements from smart contract that can be listened to by external parties
	event Staked(
		address indexed player,
		uint256 amount
	);

	event Unstaked(
		address indexed player,
		uint256 amount
	);

	// Constructor: Called once on contract deployment
	// Check packages/hardhat/deploy/00_deploy_your_contract.ts
	constructor(address _owner, string memory _name, address _poolIncentivized, uint256 _LPTokenAmount, uint256 _startTime, uint256 _endTime) {
		require(_startTime < _endTime, "Start time must be before end time");
		require(_startTime > now, "Start time must be in the future");
		owner = _owner;
		name = _name;
		LPTokenAmount = _LPTokenAmount;
		if(_poolIncentivized != address(0)) {
			poolIncentivized = IERC20Metadata(_poolIncentivized);
			LPTokenSymbol = poolIncentivized.symbol();
			if(LPTokenSymbol == "UNI-V2") {
				protocol = Protocol.Uniswap;
			} else {
				protocol = Protocol.Yearn;
			}
		}
		startTime = _startTime;
		endTime = _endTime;
	}

	// Modifier: used to define a set of rules that must be met before or after a function is executed
	// Check the withdraw() function
	modifier isOwner() {
		// msg.sender: predefined variable that represents address of the account that called the current function
		require(msg.sender == owner, "Not the Owner");
		_;
	}

	function getTournament() public view returns (string memory rName, address contractAddress, address rPoolIncentivized, string memory rLPTokenSymbol, uint256 rLPTokenAmount, uint256 rStartTime, uint256 rEndTime) {
		rName = name;
		contractAddress = address(this);
		rPoolIncentivized = address(poolIncentivized);
		rLPTokenSymbol = LPTokenSymbol;
		rLPTokenAmount = LPTokenAmount;
		rStartTime = startTime;
		rEndTime = endTime;
	}

	/**
	 * Function that allows anyone to stake their LP token to register in the tournament
	 */
	function stakeLPToken() public {
		require(IERC20(poolIncentivized).transferFrom(msg.sender, address(this), LPTokenAmount), "Transfer of LP token Failed");
		// playerToLPToken[msg.sender] += LPTokenAmount;
		(uint256 pPS, uint256 pPS2) = getPricePerShare();
		playerToDepositPricePerShare[msg.sender] = pPS;
		playerToDepositPricePerShare2[msg.sender] = pPS2;
		players.push(msg.sender);
		// numPlayers += 1;
		// emit: keyword used to trigger an event
		emit Staked(msg.sender, LPTokenAmount);
	}

	/**
	 * Function that allows anyone to unstake their LP token once the tournament is over
	 */
	function unstakeLPToken() public {
		uint256 amount = LPTokenAmountOfPlayer(_player); // corresponds to deposited underlying assets
		uint256 extraPoolPrize = (1 ether - fees) / 1 ether * (LPTokenAmount - amount);
		realizedPoolPrize += extraPoolPrize;
		realizedFees += LPTokenAmount - extraPoolPrize;
		// rewards from the game
		amount += getPoolPrize() * getRewardShare(_player) / 1 ether;
		// playerToLPToken[msg.sender] = 0;
		require(IERC20(poolIncentivized).transfer(msg.sender, amount), "Transfer of LP token Failed");

		playerToDepositPricePerShare[msg.sender] = 0; // Reuse of this variable to indicate that the player unstaked its LP token
		// emit: keyword used to trigger an event
		emit Unstaked(msg.sender, amount);
	}

	function withdrawFees() public onlyOwner {
		require(IERC20(poolIncentivized).transfer(msg.sender, realizedFees), "Transfer of LP token Failed");		
		realizedFees = 0;
	}

	/**
	 * Function that allows the bot to sumbit a batch of signed moves for resolution
	 */
	function resolveBatch() public {
	}

	/**
	 * Function that allows the player to submit a move for play against Chainlink VRF
	 */
	function playAgainstContract(string memory _move) public returns(uint256 contractMove) {
	}
		
	/**
	 * Function that allows the player to submit a move for play against another player
	 */
	function playAgainstPlayer(string memory _move) public {
		playerToLastGame[msg.sender] = now;
	}

	function updateScore(address, _player, uint256 _points) internal {
		for(uint i=0; i<scoreToPlayers[playerToScore[_player]].length; i++) {
			if(scoreToPlayers[playerToScore[_player]][i] == _player) {
				scoreToPlayers[playerToScore[_player]][i] = scoreToPlayers[playerToScore[_player]][scoreToPlayers[playerToScore[_player]].length - 1];
				break;
			}
		}
		scoreToPlayers[playerToScore[_player]].pop();
		playerToScore[_player] += _points;
		if(topScore < playerToScore[_player]) {
			topScore = playerToScore[_player];
		}
		scoreToPlayers[playerToScore[_player]].push(_player);
	}

	/**
	 * Function that returns the player's rank and how many players share this rank
	 */
	function getRank(address _player) public view returns (uint256 rank, uint256 split) {
		for(uint i=topScore; i>=playerToScore[_player]; i--) {
			if(scoreToPlayers[i].length > 0) {
				rank += 1;
			}
			split = scoreToPlayers[playerToScore[_player]].length;
		}
	}

	/**
	 * Function that returns the player's reward share (50% shared for 1st rank, 25% shared for 2nd rank, etc)
	 */
	function getRewardShare(address _player) public view returns (uint256) {
		(uint256 rank, uint256 split) = getRank();
		return (1 ether / (2 ** rank)) / split;
	}

	function getPricePerShare() private returns(uint256, uint256) {
		if(Protocol.Yearn == protocol) {
			YearnInterface yearn = YearnInterface(poolIncentivized);
			return ( yearn.pricePerShare(), 0 );
		} else { // Uniswap
			return ( uniswap.getReserves()[0] / uniswap.totalSupply(), uniswap.getReserves()[1] / uniswap.totalSupply() );
		}
	}

	function getPoolPrize() public view returns (uint256) {
		uint256 extraLP = 0;
		for (uint i=0; i<players.length; i++) {
			if(playerToDepositPricePerShare[players[i]] == 0) continue; // Already counted in realizedPoolPrize
			extraLP += LPTokenAmount - LPTokenAmountOfPlayer(players[i]);
		}
		return realizedPoolPrize + extraLP * (1 ether - fees) / 1 ether;
	}

	function getExpectedPoolPrize() public view returns (uint256) {
		return getPoolPrize() * (endTime - startTime) / (now - startTime);
	}

	function getFees() public view returns (uint256) {
		return fees / 1 ether * getPoolPrize();
	}

	function getNumberOfPlayers() public view returns (uint256) {
		return players.length;
	}

	function isActive() public view returns (bool) {
		return now >= startTime && now < endTime;
	}

	function isEnded() public view returns (bool) {
		return now >= endTime;
	}

	function isFuture() public view returns (bool) {
		return now < startTime;
	}

	function isPlayer(address _player) public view returns (bool) {
		return playerToLPToken[_player] > 0;
	}

	function alreadyPlayed(address _player) public view returns (bool) {
		// return playerToLastGame[_player] + 1 days > now;
		// TODO: modify to find the timestamp at 0:00 UTC (timestamp divided by 60/60/24 should be an integer)
		uint256 today = ( now - ( now % (60 * 60 * 24) ) ) / (60 * 60 * 24);
		uint256 lastGame = ( playerToLastGame[_player] - ( playerToLastGame[_player] % (60 * 60 * 24) ) ) / (60 * 60 * 24);
		return today == lastGame;
	}

	function pointsOfPlayer(address _player) public view returns (uint256) {
		return playerToScore[_player];
	}

	function LPTokenAmountOfPlayer(address _player) public view returns (uint256) {
		if(Protocol.Yearn == protocol) {
			// return playerToLPToken[_player] * playerToDepositPricePerShare[_player] / getPricePerShare()[0];
			return LPTokenAmount * playerToDepositPricePerShare[_player] / getPricePerShare()[0];
		} else { // Uniswap
			(uint256 pPS, uint256 pPS2) = getPricePerShare();
			// return playerToLPToken[_player] / ( ( ( pPS / playerToDepositPricePerShare[_player] ) + ( pPS2 / playerToDepositPricePerShare2[_player] ) ) / 2 );
			return LPTokenAmount / ( ( ( pPS / playerToDepositPricePerShare[_player] ) + ( pPS2 / playerToDepositPricePerShare2[_player] ) ) / 2 );
		}
	}

	function stakingAllowed() public view returns (bool) {
		return !isEnded();
	}

	function unstakingAllowed() public view returns (bool) {
		return isEnded();
	}

	function player(address _player) public view returns (uint256 LPToken, uint256 points, uint256 lastGame) {
		LPToken = LPTokenAmountOfPlayer(_player);
		points = pointsOfPlayer(_player);
		lastGame = playerToLastGame[_player];
	}

}
