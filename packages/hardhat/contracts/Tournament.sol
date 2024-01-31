//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface YearnInterface {
	function pricePerShare() external view returns (uint256);
	function token() external view returns (address); // Underlying asset
}

interface UniswapInterface {
	function getReserves() external view returns (uint256, uint256, uint256);
	function totalSupply() external view returns (uint256);
	function token0() external view returns (address); // Underlying asset
	function token1() external view returns (address); // Underlying asset
}

contract Tournament {
	// State Variables
	address public immutable owner;
	string public name; // Name of the tournament
	uint256 public contractLPToken; // amount of LP token held by the contract
	IERC20Metadata poolIncentivized;
	string public LPTokenSymbol;
	uint256 public LPTokenDecimals;
	uint256 public LPTokenAmount; // Amount of LP to be deposited by the players
	uint256 public startTime;
	uint256 public endTime;
	Protocol public protocol;

	uint256 private realizedPoolPrize; // Amount of LP left by players that withdrawn
	uint256 private realizedFees; // Amount of LP fees left by players that withdrawn
	// uint256 private unclaimedPoolPrize = 1 ether; // 100% of the pool prize unclaimed
	uint256 public fees = 0.1 ether; // 10% fees on pool prize

	uint256 public topScore = 0;
	address[] public players;
	mapping(uint256 => address[]) public scoreToPlayers; // Used for ranking
	mapping(address => Player) public playersMap;
	struct Player {
		uint score; // how many points each player has
		uint lastGame; // when the player last played (used to determine if the player already played today)
		uint depositPricePerShare; // price per share at deposit
		uint depositPricePerShare2; // price per share at deposit (only used for UniswapV2 LPs)
	}
	struct StoredPlayer {
		uint8 move;
		address addr;
	}
	StoredPlayer private storedPlayer;

	enum Protocol {
		Uniswap,
		Yearn
	}

	enum Moves {
		Paper,
		Rock,
		Scissors
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

	event MoveSaved(
		address indexed player
	);

	event Winner(
		address indexed player,
		uint256 day
	);

	event Loser(
		address indexed player,
		uint256 day
	);

	event Draw(
		address indexed player,
		address indexed opponent,
		uint256 day
	);

	// Constructor: Called once on contract deployment
	// Check packages/hardhat/deploy/00_deploy_your_contract.ts
	constructor(address _owner, string memory _name, address _poolIncentivized, uint256 _LPTokenAmount, uint256 _startTime, uint256 _endTime) {
		require(_startTime < _endTime, "Start time must be before end time");
		// Defaults to current block timestamp
		startTime = _startTime == 0 ? block.timestamp : _startTime;
		require(startTime >= block.timestamp, "Start time must be today or in the future");
		require(_endTime > block.timestamp, "End time must be in the future");
		require(_LPTokenAmount > 0, "Amount to stake must be greater than 0");
		owner = _owner;
		name = _name;
		LPTokenAmount = _LPTokenAmount;
		if(_poolIncentivized != address(0)) {
			poolIncentivized = IERC20Metadata(_poolIncentivized);
			LPTokenSymbol = poolIncentivized.symbol();
			LPTokenDecimals = poolIncentivized.decimals();
			if(keccak256(abi.encodePacked(LPTokenSymbol)) == keccak256("UNI-V2")) {
				protocol = Protocol.Uniswap;
			} else {
				protocol = Protocol.Yearn;
			}
		}
		endTime = _endTime;
	}

	// Modifier: used to define a set of rules that must be met before or after a function is executed
	// Check the withdraw() function
	modifier onlyOwner() {
		// msg.sender: predefined variable that represents address of the account that called the current function
		require(msg.sender == owner, "Not the Owner");
		_;
	}

	function getTournament() public view returns (string memory rName, address contractAddress, address rPoolIncentivized, string memory rLPTokenSymbol, uint256 rLPTokenAmount, uint256 rStartTime, uint256 rEndTime, uint256 rPlayers) {
		rName = name;
		contractAddress = address(this);
		rPoolIncentivized = address(poolIncentivized);
		rLPTokenSymbol = LPTokenSymbol;
		rLPTokenAmount = LPTokenAmount;
		rStartTime = startTime;
		rEndTime = endTime;
		rPlayers = players.length;
	}

	/**
	 * Function that returns the current price per share from the LP token contract
	 */
	function getPricePerShare() private view returns(uint256, uint256) {
		if(Protocol.Yearn == protocol) {
			YearnInterface yearn = YearnInterface(address(poolIncentivized));
			return ( yearn.pricePerShare(), 0 );
		} else { // Uniswap
			UniswapInterface uniswap = UniswapInterface(address(poolIncentivized));
			(uint256 res0, uint256 res1, ) = uniswap.getReserves();
			uint supply = uniswap.totalSupply();
			return ( 1 ether * res0 / supply, 1 ether * res1 / supply );
		}
	}

	/**
	 * Function that allows anyone to stake their LP token to register in the tournament
	 */
	function stakeLPToken() public {
		require(!isPlayer(msg.sender), "You have already staked");
		require(stakingAllowed(), "Staking not allowed");
		require(IERC20(poolIncentivized).transferFrom(msg.sender, address(this), LPTokenAmount), "Transfer of LP token Failed");
		(uint256 pPS, uint256 pPS2) = getPricePerShare();
		playersMap[msg.sender].depositPricePerShare = pPS;
		playersMap[msg.sender].depositPricePerShare2 = pPS2;
		players.push(msg.sender);
		// emit: keyword used to trigger an event
		emit Staked(msg.sender, LPTokenAmount);
	}

	/**
	 * Function that returns the current amount of LP token entitled to the player on withdrawal (before adding earned prizes)
	 */
	function LPTokenAmountOfPlayer(address _player) public view returns (uint256) {
		(uint256 pPS, uint256 pPS2) = getPricePerShare();
		if(Protocol.Yearn == protocol) {
			return LPTokenAmount * playersMap[_player].depositPricePerShare / pPS;
		} else { // Uniswap
			return LPTokenAmount / ( ( ( pPS / playersMap[_player].depositPricePerShare ) + ( pPS2 / playersMap[_player].depositPricePerShare2 ) ) / 2 );
		}
	}

	/**
	 * Function that returns the player's rank and how many players share this rank
	 */
	function getRank(address _player) public view returns (uint256 rank, uint256 split) {
		for(uint i=topScore; i>=playersMap[_player].score; i--) {
			if(scoreToPlayers[i].length > 0) {
				rank += 1;
			}
		}
		split = scoreToPlayers[playersMap[_player].score].length;
	}

	/**
	 * Function that returns the player's prize share (50% shared for 1st rank, 25% shared for 2nd rank, etc)
	 */
	function getPrizeShare(address _player) public view returns (uint256) {
		// TODO: how to manage rewards if the number of different ranks is low?
		(uint256 rank, uint256 split) = getRank(_player);
		if(split == 0) { return 0; }
		return (1 ether / (2 ** rank)) / split;
	}

	/**
	 * Function that returns the amount of LP token in the pool prize
	 */
	function getPoolPrize() public view returns (uint256) {
		uint256 extraLP = 0;
		for (uint i=0; i<players.length; i++) {
			if(playersMap[players[i]].depositPricePerShare == 0) continue; // Already counted in realizedPoolPrize
			extraLP += LPTokenAmount - LPTokenAmountOfPlayer(players[i]);
		}
		return realizedPoolPrize + extraLP * (1 ether - fees) / 1 ether;
	}

	/**
	 * Function that returns the amount of LP token earned by the player
	 */
	function getPrizeAmount(address _player) public view returns (uint256) {
		return getPoolPrize() * getPrizeShare(_player) / 1 ether;
	}

	/**
	 * Function that allows anyone to unstake their LP token once the tournament is over
	 */
	function unstakeLPToken() public {
		require(isPlayer(msg.sender), "You have nothing to withdraw");
		require(unstakingAllowed(), "Unstaking not allowed");
		// Get back its deposited value of underlying assets
		uint256 amount = LPTokenAmountOfPlayer(msg.sender); // corresponds to deposited underlying assets
		uint256 extraPoolPrize = (1 ether - fees) / 1 ether * (LPTokenAmount - amount); // How much LP token is left by the user
		realizedPoolPrize += extraPoolPrize;
		realizedFees += LPTokenAmount - extraPoolPrize;
		// Add rewards from the game
		amount += getPrizeAmount(msg.sender);
		// unclaimedPoolPrize -= share; // TODO: useful?
		require(IERC20(poolIncentivized).transfer(msg.sender, amount), "Transfer of LP token Failed");

		playersMap[msg.sender].depositPricePerShare = 0; // Reuse of this variable to indicate that the player unstaked its LP token

		// emit: keyword used to trigger an event
		emit Unstaked(msg.sender, amount);
	}

	/**
	 * Function that allows the owner to withdraw realized fees
	 * Total fees will be available for withdrawal once all players have withdrawn
	 * Partial fees can be withdran at any time after players begun to withdraw
	 */
	function withdrawFees() public onlyOwner {
		require(realizedFees > 0, "No fees to withdraw");
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
	function playAgainstContract(uint8 _move) public returns(uint256 contractMove) {
		require(isActive(), "Tournament is not active");
	}
	
	function _resolveGame(uint8 _move) internal {
		if(_move == storedPlayer.move) {
            // Draw
			updateScore(msg.sender, 2);
			updateScore(storedPlayer.addr, 2);
            // winner = address(0);
			emit Draw(msg.sender, storedPlayer.addr, timeToDate(block.timestamp));
        } else if (((3 +_move - storedPlayer.move) % 3) == 1) {
            // msg.sender wins
			updateScore(msg.sender, 4);
            // winner = msg.sender;
			emit Winner(msg.sender, timeToDate(block.timestamp));
			emit Loser(storedPlayer.addr, timeToDate(block.timestamp));
        } else {
			// storedPlayer wins
			updateScore(storedPlayer.addr, 4);
            // winner = storedPlayer.addr;
			emit Winner(storedPlayer.addr, timeToDate(block.timestamp));
			emit Loser(msg.sender, timeToDate(block.timestamp));
        }
		// Reset the stored player
        storedPlayer.addr = address(0);
    }

	/**
	 * Function that allows the player to submit a move for play against another player
	 */
	function playAgainstPlayer(uint8 _move) public {
		// require(isActive(), "Tournament is not active");
		// playersMap[msg.sender].lastGame = block.timestamp;
		// if(_move == uint8(Moves.Paper)) updateScore(msg.sender, 0); // TODO: game logic
		// else if(_move == uint8(Moves.Rock)) updateScore(msg.sender, 1);
		// else updateScore(msg.sender, 2); // Scissors

		require(_move <= 2, "Invalid move");
		require(isActive(), "Tournament is not active");
		require(!alreadyPlayed(msg.sender), "You already played today");
		require(isPlayer(msg.sender), "You must deposit before playing");
		playersMap[msg.sender].lastGame = block.timestamp;

        if(storedPlayer.addr != address(0)) {
			// A player is already waiting to be matched
            _resolveGame(_move);
        } else {
			// No player is waiting to be matched, we store the move and wait for a player to join
            storedPlayer.move = _move;
            storedPlayer.addr = msg.sender;
        }
        
        emit MoveSaved(msg.sender);
	}

	/**
	 * Function that updates the player score by adding the points
	 */
	function updateScore(address _player, uint8 _points) internal {
		if(_points == 0) { return; }
		// We first remove the player from it's current rank
		uint score = playersMap[_player].score;
		for(uint i=0; i<scoreToPlayers[score].length; i++) {
			if(scoreToPlayers[score][i] == _player) {
				scoreToPlayers[score][i] = scoreToPlayers[score][scoreToPlayers[score].length - 1];
				break;
			}
		}
		if(score > 0) { scoreToPlayers[score].pop(); }
		// Now we can update the score and push the user to its new rank
		playersMap[_player].score += _points;
		if(topScore < playersMap[_player].score) {
			topScore = playersMap[_player].score;
		}
		scoreToPlayers[playersMap[_player].score].push(_player);
	}

	/**
	 * Function that returns the expected pool prize at the end of the tournament from the accrued LP since the start
	 */
	function getExpectedPoolPrize() public view returns (uint256) {
		if(isFuture()) return 0;
		return getPoolPrize() * (endTime - startTime) / (block.timestamp - startTime);
	}

	/**
	 * Function that returns the amount of fees accrued by the protocol on this tournament
	 */
	function getFees() public view returns (uint256) {
		return (fees / 1 ether) * getPoolPrize();
	}

	function getNumberOfPlayers() public view returns (uint256) {
		return players.length;
	}

	function timeToDate(uint256 _time) internal pure returns (uint256) {
		return _time / (60 * 60 * 24);
	}

	function isEnded() public view returns (bool) {
		return timeToDate(block.timestamp) >= timeToDate(endTime);
	}

	/**
	 * Function that returns true if the tournament is not yet started
	 */
	function isFuture() public view returns (bool) {
		return timeToDate(block.timestamp) < timeToDate(startTime);
	}

	/**
	 * Function that returns if the tournament is active (players are allowed to play)
	 */
	function isActive() public view returns (bool) {
		return !isFuture() && !isEnded();
	}

	/**
	 * Function that returns true if the address deposited and did not withdraw
	 */
	function isPlayer(address _player) public view returns (bool) {
		return playersMap[_player].depositPricePerShare > 0;
	}

	/**
	 * Function that returns if the player has already played today (resets at O0:OO UTC)
	 */
	function alreadyPlayed(address _player) public view returns (bool) {
		uint256 today = timeToDate(block.timestamp);
		uint256 lastGame = timeToDate(playersMap[_player].lastGame);
		return today == lastGame;
	}

	function pointsOfPlayer(address _player) public view returns (uint256) {
		return playersMap[_player].score;
	}

	function stakingAllowed() public view returns (bool) {
		return !isEnded();
	}

	function unstakingAllowed() public view returns (bool) {
		return isEnded();
	}

	function getPlayers() public view returns (address[] memory) {
		return players;
	}

	function getPlayersAtScore(uint256 _score) public view returns (address[] memory) {
		return scoreToPlayers[_score];
	}

	function player(address _player) public view returns (uint256 LPToken, uint256 score, uint256 lastGame) {
		LPToken = LPTokenAmountOfPlayer(_player);
		score = playersMap[_player].score;
		lastGame = playersMap[_player].lastGame;
	}

}
