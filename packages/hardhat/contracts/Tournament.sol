//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
//import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "./VRFConsumerBaseV2Upgradeable.sol";

interface YearnInterface {
	function pricePerShare() external view returns (uint256);
	function token() external view returns (address); // Underlying asset
}

interface UniswapInterface {
	function getReserves() external view returns (uint112, uint112, uint32);
	function totalSupply() external view returns (uint256);
	function token0() external view returns (address); // Underlying asset
	function token1() external view returns (address); // Underlying asset
}

interface Factory {
	function getVrfConfig() external view returns (uint64, bytes32, uint32);
	function getVrfCoordinator() external view returns (address);
}

contract Tournament is Initializable, VRFConsumerBaseV2Upgradeable {

	//////////////
	/// ERRORS ///
	//////////////
		
	///////////////////////
	/// State Variables ///
	///////////////////////

	address public owner;
	
	//TOURNAMENT INFO
	string public name; // Name of the tournament
	IERC20Metadata poolIncentivized;
	uint256 public depositAmount; // Exact Amount of LP to be deposited by the players
	uint32 public startTime;
	uint32 public endTime;
	address private factory;
	enum Protocol {
		Uniswap,
		Yearn
	}
	Protocol public protocol;
	uint256 private realizedPoolPrize; // Amount of LP left by players that withdrawn
	uint256 private realizedFees; // Amount of LP fees left by players that withdrawn
	uint64 private unclaimedPoolPrize = 1 ether; // 100% of the pool prize unclaimed
	uint64 public fees = 0.1 ether; // 10% fees on pool prize
	uint16 public topScore = 0;
	uint256 private nbRanks = 1;

	// PLAYER INFO
	address[] public players;
	mapping(uint16 => address[]) public scoreToPlayers; // Used for ranking
	mapping(address => Player) public playersMap; //address => Player Struct

	struct Player {
		uint16 score; // how many points each player has
		uint8 streak; // number of consecutive wins
		uint32 lastGame; // when the player last played (used to determine if the player already played today)
		uint depositPricePerShare; // price per share at deposit
	}
	struct StoredPlayer {
		uint8 move;
		address addr;
	}
	StoredPlayer private storedPlayer;


	///////////////////////////////
    /// Chainlink VRF Variables ///
    ///////////////////////////////
    struct ContractGame {
        uint8 playerMove;
        address player;
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
        uint8 vrfMove;
        address winner;
    }

    // requestId --> GameStatus  @note is there a better way to track games?
    mapping(uint256 => ContractGame) public contractGameRequestId; 

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    VRFCoordinatorV2Interface private vrfCoordinator;    
    /// VRF END ///

	//////////////
	/// EVENTS ///
	//////////////

	// Events: a way to emit log statements from smart contract that can be listened to by external parties
	event Staked(address indexed player, uint256 amount);
	event Unstaked(address indexed player, uint256 amount);

	event MoveSaved(
		address indexed player,
		uint vrf
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

	/////////////////
	/// MODIFIERS ///
	/////////////////


	// Modifier: used to define a set of rules that must be met before or after a function is executed
	//@note we could use OZ Ownable
	// Check the withdraw() function
	modifier onlyOwner() {
		// msg.sender: predefined variable that represents address of the account that called the current function
		require(msg.sender == owner, "Not the Owner");
		_;
	}

	function initialize(
		address _owner, 
		string memory _name, 
		address _poolIncentivized, 
		uint256 _depositAmount, 
		uint32 _startTime, 
		uint32 _endTime, 
		address _factory
		) public initializer {
			require(_startTime < _endTime, "Start time must be before end time");
			// Defaults to current block timestamp
			startTime = _startTime == 0 ? uint32(block.timestamp) : _startTime;
			require(startTime >= block.timestamp, "Start time must be today or in the future");
			require(_endTime > block.timestamp, "End time must be in the future");
			require(_depositAmount > 0, "Amount to stake must be greater than 0");
			owner = _owner;
			name = _name;
			depositAmount = _depositAmount;
			if(_poolIncentivized != address(0)) {
				poolIncentivized = IERC20Metadata(_poolIncentivized);
				string memory symbol = poolIncentivized.symbol();
				if(keccak256(abi.encodePacked(symbol)) == keccak256("UNI-V2")) {
					protocol = Protocol.Uniswap;
				} else {
					protocol = Protocol.Yearn;
				}
			}
			endTime = _endTime;
			factory = _factory;
			// VRF
			address _vrfCoordinatorV2 = Factory(factory).getVrfCoordinator();
			__VRFConsumerBaseV2Upgradeable_init(_vrfCoordinatorV2);
			vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
		}

	/////////////////////////////
	/// Stake & Unstake Funcs ///
	/////////////////////////////

	/**
	 * @notice Allows the players to stake their LP token to register for the tournament
	 */
	function stakeLPToken() public {
		require(!isPlayer(msg.sender), "You have already staked");
		require(stakingAllowed(), "Staking not allowed");
		require(IERC20(poolIncentivized).transferFrom(msg.sender, address(this), depositAmount)); // Revert message handled by the ERC20 transferFrom function
		playersMap[msg.sender].depositPricePerShare = getPricePerShare();
		players.push(msg.sender);
		// emit: keyword used to trigger an event
		emit Staked(msg.sender, depositAmount);
	}

	/**
	 * @notice Allows the players to withdraw their entitled LP token amount once the tournament is over
	 * @dev Also updates the state of the contract to reflect the withdrawal
	 */
	function unstakeLPToken() public {
		require(isPlayer(msg.sender), "You have nothing to withdraw"); // Address never staked or already withdrew
		require(unstakingAllowed(), "Unstaking not allowed");
		// Get back its deposited value of underlying assets
		uint256 amount = withdrawAmountFromDeposit(msg.sender); // corresponds to deposited underlying assets
		uint256 extraPoolPrize = (1 ether - fees) * (depositAmount - amount) / 1 ether; // How much LP token is left by the user
		realizedFees += depositAmount - amount - extraPoolPrize;
		// Add rewards from the game
		amount += getPrizeAmount(msg.sender);
		realizedPoolPrize += extraPoolPrize;
		unclaimedPoolPrize -= getPrizeShare(msg.sender);
		require(IERC20(poolIncentivized).transfer(msg.sender, amount), "Transfer of LP token Failed");

		playersMap[msg.sender].depositPricePerShare = 0; // Reuse of this variable to indicate that the player unstaked its LP token

		// emit: keyword used to trigger an event
		emit Unstaked(msg.sender, amount);
	}

	/**
	 * @notice Allows the owner to withdraw realized fees
	 * @dev Total fees will be available for withdrawal once all players have withdrawn
	 * @dev Partial fees can be withdran at any time after players begun to withdraw
	 */
	function withdrawFees() public onlyOwner {
		require(realizedFees > 0, "No fees to withdraw");
		uint256 _realizedFees = unclaimedPoolPrize == 0 ? poolIncentivized.balanceOf(address(this)) : realizedFees;
		realizedFees = 0;
		require(IERC20(poolIncentivized).transfer(msg.sender, _realizedFees), "Transfer of LP token Failed");		
	}


	///////////////////////////
	/// GAME PLAY FUNCTIONS ///
	///////////////////////////

	/**
	 * @notice Submit a move for play against another player
	 * @param _move is the player's move
	 */
	function playAgainstPlayer(uint8 _move) public {
		require(_move <= 2, "Invalid move");
		require(isActive(), "Tournament is not active");
		require(!alreadyPlayed(msg.sender), "You already played today");
		require(isPlayer(msg.sender), "You must deposit before playing");
		playersMap[msg.sender].lastGame = uint32(block.timestamp);

        if(storedPlayer.addr != address(0)) {
			// A player is already waiting to be matched
            resolveGame(_move);
        } else {
			// No player is waiting to be matched, we store the move and wait for a player to join
            storedPlayer.move = _move;
            storedPlayer.addr = msg.sender;
        }
        
        emit MoveSaved(msg.sender, 0);
	}

	/**
	 * @notice Submit a move for play against a contract
	 * @param _move is the player's move
	 * @return requestId is the requestId generated by chainlink and used to grab the game struct
	 */
	function playAgainstContract(uint8 _move) public returns(uint256 requestId) {
		require(_move <= 2, "Invalid move");
		require(isActive(), "Tournament is not active");
		require(!alreadyPlayed(msg.sender), "You already played today");
		require(isPlayer(msg.sender), "You must deposit before playing");
		playersMap[msg.sender].lastGame = uint32(block.timestamp);

        requestId = _requestRandomWords(_move, msg.sender);

        require(requestId > 0, "Your move could not be processed");
		emit MoveSaved(msg.sender, requestId);
	}

	////////////////////////
    //// VRFv2 functions ///
    ////////////////////////
	// fuji info
    // fuji id: 1341
    // gaslane: 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61
    // vrf: 0x2eD832Ba664535e5886b75D64C46EB9a228C2610

	/**
	 * @notice Requests a random number from the VRF
	 * @dev If a request is successful, the callback function, fulfillRandomWords will be called.
	 * @param _playerMove is the player's move
	 * @param _player is the player's address
	 */
    function _requestRandomWords(uint8 _playerMove, address _player) internal returns (uint256 requestId) {

		(uint64 _subscriptionId, bytes32 _gasLane, uint32 _callbackGasLimit) = Factory(factory).getVrfConfig();

		// Will revert if subscription is not set and funded.
		//@todo can I just call this in the play function??
		requestId = vrfCoordinator.requestRandomWords(
			_gasLane,
			_subscriptionId,
			3, // Number of confirmations
			_callbackGasLimit,
			1 // Number of words
		);

		contractGameRequestId[requestId] = ContractGame(
			_playerMove,
			_player,
			false,
			true,
			new uint256[](0),
			3, // Placeholder value indicating unfulfilled request
			address(0)
		);

		requestIds.push(requestId);
		lastRequestId = requestId;
    }

	/**
	 * @notice Handle VRF callback
	 * @param requestId is the requestId generated by chainlink and used to grab the game struct
	 * @param randomWords is the random number generated by the VRF
	 */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // check number is ready
        require(contractGameRequestId[requestId].exists, "request not found");
      
        // number of moves size 3 (0rock 1paper 2scissor)
        uint8 vrfMove = uint8(randomWords[0] % 3);

        ContractGame storage game = contractGameRequestId[requestId];

        game.fulfilled = true;
        game.randomWords = randomWords;
        game.vrfMove = vrfMove;

        resolveVrfGame(requestId);
    }

	//////////////////////////////
	/// RESOLVE GAME FUNCTIONS ///
	//////////////////////////////

	/**
	 * Function that allows the bot to sumbit a batch of signed moves for resolution
	 */
	function resolveBatch() public {
	}

	/**
	 * @notice Resolves the game against another player
	 * @param _move The move the player made
	 */
	function resolveGame(uint8 _move) internal {
		if(_move == storedPlayer.move) {
            // Draw
			updateScore(msg.sender, 1);
			updateScore(storedPlayer.addr, 1);
			emit Draw(msg.sender, storedPlayer.addr, timeToDate(uint32(block.timestamp)));
        } else if (((3 + _move - storedPlayer.move) % 3) == 1) {
            // msg.sender wins
			updateScore(msg.sender, 2);
			updateScore(storedPlayer.addr, 0);
			emit Winner(msg.sender, timeToDate(uint32(block.timestamp)));
			emit Loser(storedPlayer.addr, timeToDate(uint32(block.timestamp)));
        } else {
			// storedPlayer wins
			updateScore(storedPlayer.addr, 2);
			updateScore(msg.sender, 0);
			emit Winner(storedPlayer.addr, timeToDate(uint32(block.timestamp)));
			emit Loser(msg.sender, timeToDate(uint32(block.timestamp)));
        }
		// Reset the stored player
        storedPlayer.addr = address(0);
    }

	/**
	 * @notice Resolves the game against the contract (VRF)
	 * @param requestId is the requestId generated by chainlink and used to grab the game struct
	 */
    function resolveVrfGame(uint256 requestId) internal {
        ContractGame storage game = contractGameRequestId[requestId]; 
        if(game.playerMove == game.vrfMove){
            //draw
			updateScore(game.player, 1);
			emit Draw(game.player, address(0), timeToDate(uint32(block.timestamp)));
            game.winner = address(0);
        } else if (((3 + game.playerMove - game.vrfMove) % 3) == 1) {
        // } else if ((game.playerMove + 1) % 3 == game.vrfMove) {
            // player wins 
			updateScore(game.player, 2);
			emit Winner(game.player, timeToDate(uint32(block.timestamp)));
        	game.winner = game.player;
        } else {
            //player loses
			updateScore(game.player, 0);
    		emit Loser(game.player, timeToDate(uint32(block.timestamp)));
            game.winner = address(vrfCoordinator);
        }
    }

	/**
	 * @notice Updates the player score by adding points
	 * @dev Should be called in any case. Also updates player's rank and streak
	 * @param _player is the address of the player
	 * @param _points 0 = lost, 1 = draw, 2 = won
	 */
	function updateScore(address _player, uint8 _points) internal {
		if(_points == 0) {
			playersMap[_player].streak = 0;
			return;
		} else if(_points == 2) {
			playersMap[_player].streak += 1;
		}
		// We first remove the player from it's current rank
		uint16 score = playersMap[_player].score;
		for(uint i=0; i<scoreToPlayers[score].length; i++) {
			if(scoreToPlayers[score][i] == _player) {
				scoreToPlayers[score][i] = scoreToPlayers[score][scoreToPlayers[score].length - 1];
				break;
			}
		}
		if(score > 0) {
			scoreToPlayers[score].pop();
			if(scoreToPlayers[score].length == 0) { nbRanks -= 1; } // No more players at this rank
		}
		// Now we can update the score and push the user to its new rank
		playersMap[_player].score += _points**playersMap[_player].streak;
		if(topScore < playersMap[_player].score) {
			topScore = playersMap[_player].score;
		}
		scoreToPlayers[playersMap[_player].score].push(_player);
		if(scoreToPlayers[playersMap[_player].score].length == 1) { nbRanks += 1; } // New rank created for this player
	}

	////////////////////
	/// Getter Funcs ///
	////////////////////

	function getTournament() public view returns (string memory rName, address contractAddress, address rPoolIncentivized, string memory rLPTokenSymbol, uint256 rdepositAmount, uint32 rStartTime, uint32 rEndTime, uint16 rPlayers) {

		rName = name;
		contractAddress = address(this);
		rPoolIncentivized = address(poolIncentivized);
		rLPTokenSymbol = getFancySymbol();
		rdepositAmount = depositAmount;
		rStartTime = startTime;
		rEndTime = endTime;
		rPlayers = getNumberOfPlayers();
	}

	function getGame(uint256 _requestId) public view returns (uint8 playerMove, address gamePlayer, bool fulfilled, bool exists, uint256[] memory randomWords, uint256 vrfMove, address winner) {
		playerMove = contractGameRequestId[_requestId].playerMove;
		gamePlayer = contractGameRequestId[_requestId].player;
		fulfilled = contractGameRequestId[_requestId].fulfilled;
		exists = contractGameRequestId[_requestId].exists;
		randomWords = contractGameRequestId[_requestId].randomWords;
		vrfMove = contractGameRequestId[_requestId].vrfMove;
		winner = contractGameRequestId[_requestId].winner;
	}

	/**
	 * @notice Returns the current price per share of the LP token
	 * @dev Get function for Yearn, while for Uniswap we need to compute k / supply
	 * @return pPS The current price per share
	 */
	function getPricePerShare() public view returns(uint256 pPS) {
		if(Protocol.Yearn == protocol) {
			YearnInterface yearn = YearnInterface(address(poolIncentivized));
			pPS = yearn.pricePerShare();
		} else { // Uniswap
			UniswapInterface uniswap = UniswapInterface(address(poolIncentivized));
			(uint112 res0, uint112 res1, ) = uniswap.getReserves();
			uint256 supply = uniswap.totalSupply();
			pPS = uint256(res0) * uint256(res1) / supply;
		}
	}

	/**
	 * @notice Returns the current amount of LP token entitled to the player on withdrawal
	 * @dev Ensures that the player will get the same value of underlying assets that he deposited. Earnings not included
	 * @param _player The player address
	 * @return amount The amount of LP token the player would receive if he withdraws now
	 */
	function withdrawAmountFromDeposit(address _player) public view returns (uint256 amount) {
		uint256 pPS = getPricePerShare();
		if(playersMap[_player].depositPricePerShare == 0) return 0; // User aleady withdrew
		// We prevent user to receive more LP than deposited in exeptional case where pPS disminushes
		pPS = (pPS < playersMap[_player].depositPricePerShare) ? playersMap[_player].depositPricePerShare : pPS;
		amount = depositAmount * playersMap[_player].depositPricePerShare / pPS;
	}

	/**
	 * @notice Returns the rank of the player
	 * @dev 50% shared for 1st rank, 25% shared for 2nd rank, etc. 1 ether = 100%
	 * @param _player The player address
	 * @return rank The player's rank
	 * @return split The number of players sharing the same rank
	 */
	function getRank(address _player) public view returns (uint16 rank, uint16 split) {
		if(!isPlayer(_player)) return (0, 0);
		uint16 cumulativePlayers;
		for(uint16 i=topScore; i>=playersMap[_player].score; i--) {
			if(scoreToPlayers[i].length > 0) {
				cumulativePlayers += uint16(scoreToPlayers[i].length);
				rank += 1;
			}
			if(i == 0) { // If the player did not score, he won't be in in the mapping
				rank += 1;
				split = uint16(players.length) - cumulativePlayers;
				return (rank, split);
			}
		}
		split = uint16(scoreToPlayers[playersMap[_player].score].length);
	}

	/**
	 * @notice Returns the share of the pool prize earned by the player
	 * @dev 50% shared for 1st rank, 25% shared for 2nd rank, etc. 1 ether = 100%
	 * @param _player The player address
	 * @return share The player's share
	 */
	function getPrizeShare(address _player) public view returns (uint64 share) {
		// TODO: how to manage rewards if the number of different ranks is low?
		(uint256 rank, uint256 split) = getRank(_player);
		if(split == 0) return 0; // Not a player = no share
		uint8 multiplier = (nbRanks == rank) ? 2 : 1; // We double the allocation for the last rank so that sum of shares is 100%
		share = uint64((multiplier * 1 ether / (2 ** rank)) / split);
	}

	/**
	 * @notice Returns the total pool prize
	 * @dev The realized pool price is static while remaining pool prize is dynamic
	 * @return amount The pool prize amount
	 */
	function getPoolPrize() public view returns (uint256 amount) {
		amount = realizedPoolPrize + getRemainingPoolPrize();
	}

	/**
	 * @notice Returns the amount of pool prize left
	 * @dev The number of LP tokens will be obtained from the players that did not withdraw yet
	 * @return amount The remaining pool prize amount
	 */
	function getRemainingPoolPrize() public view returns (uint256 amount) {
		uint256 extraLP = 0;
		for (uint i=0; i<players.length; i++) {
			if(playersMap[players[i]].depositPricePerShare == 0) continue; // The player withdrew, we skip him
			extraLP += depositAmount - withdrawAmountFromDeposit(players[i]);
		}
		amount = extraLP * (1 ether - fees) / 1 ether;
	}

	/**
	 * @notice Returns the amount of pool prize earned by the user
	 * @dev Unclaimed pool prize is cross multiplied by the player share and divided by the unclaimed shares
	 * @param _player The player address
	 * @return amount The user pool prize amount
	 */
	function getPrizeAmount(address _player) public view returns (uint256 amount) {
		amount = getRemainingPoolPrize() * getPrizeShare(_player) / unclaimedPoolPrize;
	}

	/**
	 * @notice Returns if the expected pool prize at the end of the tournament
	 * @dev Current pool prize is cross multiplied by the duration of the tournament and divided by the elapsed time
	 * @return amount The expected pool prize amount
	 */
	function getExpectedPoolPrize() public view returns (uint256 amount) {
		if(isFuture()) return 0;
		amount = getPoolPrize() * (endTime - startTime) / (block.timestamp - startTime);
	}

	/**
	 * @notice Returns if the amount of fees accrued by the protocol
	 * @return amount The amount of fees
	 */
	function getFees() internal view returns (uint256 amount) {
		amount = getPoolPrize() * fees / (1 ether - fees);
	}

	/**
	 * @notice Converts time in seconds to days
	 * @dev Players can only withdraw if the tournament has ended
	 * @param _time The time in seconds
	 * @return days_ The number of days
	 */
	function timeToDate(uint32 _time) internal pure returns (uint16 days_) {
		days_ = uint16(_time / 1 days);
	}

	/**
	 * @notice Returns if the tournament is ended
	 * @dev Players can only withdraw if the tournament has ended. Use unstakingAllowed() to check if unstaking is allowed
	 * @return ended
	 */
	function isEnded() public view returns (bool ended) {
		ended = timeToDate(uint32(block.timestamp)) >= timeToDate(endTime);
	}

	/**
	 * @notice Returns if the tournament is not yet started
	 * @dev Players can only stake if the tournament is future. Use stakingAllowed() to check if staking is allowed
	 * @return future
	 */
	function isFuture() public view returns (bool future) {
		future = timeToDate(uint32(block.timestamp)) < timeToDate(startTime);
	}

	/**
	 * @notice Returns if the tournament is active
	 * @dev Players can only play if the tournament is active
	 * @return active
	 */
	function isActive() public view returns (bool active) {
		active = !isFuture() && !isEnded();
	}

	/**
	 * @notice Returns if the player is registered in this tournament
	 * @dev Returns true if the player has made a deposit and has not yet withdrawn
	 * @param _player The player address
	 * @return isP
	 */
	function isPlayer(address _player) public view returns (bool isP) {
		isP = playersMap[_player].depositPricePerShare > 0;
	}

	/**
	 * @notice Returns if the player has already played today
	 * @dev Resets at O0:OO UTC
	 * @param _player The player address
	 */
	function alreadyPlayed(address _player) public view returns (bool) {
		uint32 today = timeToDate(uint32(block.timestamp));
		uint32 lastGame = timeToDate(playersMap[_player].lastGame);
		return today == lastGame;
	}

	/**
	 * @notice Returns the player's score
	 * @param _player The player address
	 */
	function pointsOfPlayer(address _player) public view returns (uint16) {
		return playersMap[_player].score;
	}

	/**
	 * @notice Returns if staking is allowed
	 * @dev Players can stake anytime until 1 day before the end of the game. If they were able to stake at last minute, they could get a share of the pool prize without any contribution.
	 * @return allowed
	 */
	function stakingAllowed() public view returns (bool allowed) {
		allowed = timeToDate(uint32(block.timestamp)) >= timeToDate(endTime - 1 days);
	}

	/**
	 * @notice Returns if unstaking is allowed
	 * @dev Players can stake anytime after the end of the game
	 * @return allowed
	 */
	function unstakingAllowed() public view returns (bool allowed) {
		allowed = isEnded();
	}

	/**
	 * @notice Returns the number of players
	 * @return number Number of players
	 */
	function getNumberOfPlayers() public view returns (uint16 number) {
		number = uint16(players.length);
	}

	/**
	 * @notice Returns the list of all players
	 * @return arr List of players
	 */
	function getPlayers() public view returns (address[] memory arr) {
		arr = players;
	}

	/**
	 * @notice Returns the list of players at a given score
	 * @param _score The score of the players
	 * @return arr List of players
	 */
	function getPlayersAtScore(uint16 _score) public view returns (address[] memory arr) {
		if(_score == 0) return new address[](0); // We don't return the list of players without any point
		arr = scoreToPlayers[_score];
	}

	/**
	 * @notice Returns data available on the player
	 * @param _player The address of the player
	 * @return rank of the player
	 * @return score of the player
	 * @return lastGame Last time the player played
	 */
	function getPlayer(address _player) public view returns (uint16 rank, uint16 score, uint32 lastGame) {
		(rank, ) = getRank(_player);
		score = playersMap[_player].score;
		lastGame = playersMap[_player].lastGame;
	}

	/**
	 * @notice Returns the number of decimals of the LP token
	 * @return decimals Number of decimals
	 */
	function getLPDecimals() public view returns (uint8 decimals) {
		decimals = IERC20Metadata(poolIncentivized).decimals();
	}

	/**
	 * @notice Returns the symbol of the pool as defined in the pool contract
	 * @return symbol of the pool
	 */
	function getLPSymbol() public view returns (string memory symbol) {
		symbol = IERC20Metadata(poolIncentivized).symbol();
	}

	/**
	 * @notice Returns the symbol of the pool
	 * @dev If the pool is Uniswapn it adds the symbol of the underlying tokens to UNI-V2
	 * @return symbol "fancy" symbol of the pool
	 */
	function getFancySymbol() public view returns (string memory symbol) {
		if(protocol == Protocol.Uniswap) {
			address token0 = UniswapInterface(address(poolIncentivized)).token0();
			address token1 = UniswapInterface(address(poolIncentivized)).token1();
			string memory symbol0 = IERC20Metadata(token0).symbol();
			string memory symbol1 = IERC20Metadata(token1).symbol();
			symbol = string.concat("UNI-V2 (",symbol0);
			symbol = string.concat(symbol, "-");
			symbol = string.concat(symbol, symbol1);
			symbol = string.concat(symbol, ")");
		} else {
			symbol = getLPSymbol();
		}
	}
}
