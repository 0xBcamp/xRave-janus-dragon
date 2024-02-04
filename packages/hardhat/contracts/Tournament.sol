//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";


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

contract Tournament is VRFConsumerBaseV2{

	//////////////
	/// ERRORS ///
	//////////////
		
	///////////////////////
	/// State Variables ///
	///////////////////////

	address public immutable owner;
	
	//TOURNAMENT INFO?
	// @todo could probably put all tournament info in a struct, probaly dont need LPTokenSymbols or Decimals
	string public name; // Name of the tournament
	uint256 public contractLPToken; // amount of LP token held by the 
	//@note why do we need IERC20Metadata??
	IERC20Metadata poolIncentivized;
	//@note change to depositAmout
	uint256 public LPTokenAmount; // Min Amount of LP to be deposited by the players
	uint256 public startTime;
	uint256 public endTime;
	//@note is this necessary??
	Protocol public protocol;
	uint256 private realizedPoolPrize; // Amount of LP left by players that withdrawn
	uint256 private realizedFees; // Amount of LP fees left by players that withdrawn
	// uint256 private unclaimedPoolPrize = 1 ether; // 100% of the pool prize unclaimed
	uint256 public fees = 0.1 ether; // 10% fees on pool prize
	uint256 public topScore = 0;

	// PLAYER INFO
	address[] public players;
	mapping(uint256 => address[]) public scoreToPlayers; // Used for ranking
	mapping(address => Player) public playersMap; //address => Player Struct

	//@note if we only allow one pool we don't need 2 depositPricePerShare variables
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

	//@note is this necessary? 
	enum Protocol {
		Uniswap,
		Yearn
	}


	///////////////////////////////
    /// Chainlink VRF Variables ///
    ///////////////////////////////
    struct ContractGame {
        uint8 playerMove;
        address player;
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
        uint256 vrfMove;
        address winner;
    }

    // requestId --> GameStatus  @note is there a better way to track games?
    mapping(uint256 => ContractGame) public contractGameRequestId; 

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private gasLimit;
    //uint256 private immutable i_entranceFee;
    //@todo uint8s??
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    
    /// VRF END ///

	//////////////
	/// EVENTS ///
	//////////////

	// Events: a way to emit log statements from smart contract that can be listened to by external parties
	event Staked(address indexed player, uint256 amount);
	event Unstaked(address indexed player, uint256 amount);

	// Against a player
	event MoveSaved(
		address indexed player,
		bool vrf
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

	// Constructor: Called once on contract deployment
	// Check packages/hardhat/deploy/00_deploy_your_contract.ts
	constructor(
		address _owner, 
		string memory _name, 
		address _poolIncentivized, 
		uint256 _LPTokenAmount, 
		uint256 _startTime, 
		uint256 _endTime,
		//VRF
		uint64 _subscriptionId, 
		bytes32 _gasLane, 
		uint32 _callbackGasLimit, 
		address _vrfCoordinatorV2
		)  VRFConsumerBaseV2(_vrfCoordinatorV2) {
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
				//@note why do we need to check the symbol??
				string memory symbol = poolIncentivized.symbol();
				if(keccak256(abi.encodePacked(symbol)) == keccak256("UNI-V2")) {
					protocol = Protocol.Uniswap;
				} else {
					protocol = Protocol.Yearn;
				}
			}
			endTime = _endTime;
			//VRF
			i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
            i_subscriptionId = _subscriptionId;
            i_gasLane = _gasLane;
            gasLimit = _callbackGasLimit;
		}

	/////////////////////////////
	/// Stake & Unstake Funcs ///
	/////////////////////////////

	/**
	 * Function that allows anyone to stake their LP token to register in the tournament
	 */
	function stakeLPToken() public {
		require(!isPlayer(msg.sender), "You have already staked");
		require(stakingAllowed(), "Staking not allowed");
		require(IERC20(poolIncentivized).transferFrom(msg.sender, address(this), LPTokenAmount)); // Revert message handled by the ERC20 transferFrom function
		(uint256 pPS, uint256 pPS2) = getPricePerShare();
		playersMap[msg.sender].depositPricePerShare = pPS;
		playersMap[msg.sender].depositPricePerShare2 = pPS2;
		players.push(msg.sender);
		// emit: keyword used to trigger an event
		emit Staked(msg.sender, LPTokenAmount);
	}

	/**
	 * Function that allows anyone to unstake their LP token once the tournament is over
	 */
	function unstakeLPToken() public {
		require(isPlayer(msg.sender), "You have nothing to withdraw"); // Address never staked or already withdrew
		require(unstakingAllowed(), "Unstaking not allowed");
		// Get back its deposited value of underlying assets
		uint256 amount = LPTokenAmountOfPlayer(msg.sender); // corresponds to deposited underlying assets
		uint256 extraPoolPrize = (1 ether - fees) * (LPTokenAmount - amount) / 1 ether; // How much LP token is left by the user
		realizedFees += LPTokenAmount - amount - extraPoolPrize;
		// Add rewards from the game
		amount += getPrizeAmount(msg.sender);
		realizedPoolPrize += extraPoolPrize;
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
	//updated to follow CEI
	function withdrawFees() public onlyOwner {
		require(realizedFees > 0, "No fees to withdraw");
		uint256 _realizedFees = realizedFees;
		realizedFees = 0;
		require(IERC20(poolIncentivized).transfer(msg.sender, _realizedFees), "Transfer of LP token Failed");		
	}


	///////////////////////////
	/// GAME PLAY FUNCTIONS ///
	///////////////////////////

	/**
	 * Function that allows the player to submit a move for play against another player
	 */
	function playAgainstPlayer(uint8 _move) public {
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
        
        emit MoveSaved(msg.sender, false);
	}

	/**
	 * Function that allows the player to submit a move for play against Chainlink VRF
	 */
	//@note must update lastgame in Player struct 
	function playAgainstContract(uint8 _move) public returns(uint256 requestId) {
		require(_move <= 2, "Invalid move");
		require(isActive(), "Tournament is not active");
		require(!alreadyPlayed(msg.sender), "You already played today");
		require(isPlayer(msg.sender), "You must deposit before playing");
		playersMap[msg.sender].lastGame = block.timestamp;

        requestId = _requestRandomWords(_move, msg.sender);

        require(requestId > 0, "Your move could not be processed");
		emit MoveSaved(msg.sender, true);
	}

	////////////////////////
    //// VRFv2 functions ///
    ////////////////////////
	// fuji info
    // fuji id: 1341
    // gaslane: 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61
    // vrf: 0x2eD832Ba664535e5886b75D64C46EB9a228C2610


    // It will request a random number from the VRF 
    // If a request is successful, the callback function, fulfillRandomWords will be called.
    // @return requestId is the requestId generated by chainlink
    function _requestRandomWords(uint8 _playerMove, address _player) internal returns (uint256 requestId) {

            // Will revert if subscription is not set and funded.
            //@todo can I just call this in the play function??
            requestId = i_vrfCoordinator.requestRandomWords(
                i_gasLane,
                i_subscriptionId,
                REQUEST_CONFIRMATIONS,
                gasLimit,
                NUM_WORDS
            );

            contractGameRequestId[requestId] = ContractGame({
                playerMove: _playerMove,
                player: _player,
                fulfilled: false,
                exists: true,
                randomWords: new uint256[](0),
                vrfMove: 3, // Placeholder value indicating unfulfilled request
                winner: address(0)
            });

            requestIds.push(requestId);
            lastRequestId = requestId;
    }


     /**
     * This is the function that Chainlink VRF node
     * calls to play the game.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // check number is ready
        require(contractGameRequestId[requestId].exists, "request not found");
      
        // number of moves size 3 (0rock 1paper 2scissor)
        uint256 vrfMove = randomWords[0] % 3;

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
	
	function _resolveGame(uint8 _move) internal {
		if(_move == storedPlayer.move) {
            // Draw
			updateScore(msg.sender, 2);
			updateScore(storedPlayer.addr, 2);
			emit Draw(msg.sender, storedPlayer.addr, timeToDate(block.timestamp));
        } else if (((3 + _move - storedPlayer.move) % 3) == 1) {
            // msg.sender wins
			updateScore(msg.sender, 4);
			emit Winner(msg.sender, timeToDate(block.timestamp));
			emit Loser(storedPlayer.addr, timeToDate(block.timestamp));
        } else {
			// storedPlayer wins
			updateScore(storedPlayer.addr, 4);
			emit Winner(storedPlayer.addr, timeToDate(block.timestamp));
			emit Loser(msg.sender, timeToDate(block.timestamp));
        }
		// Reset the stored player
        storedPlayer.addr = address(0);
    }

	/**
	 * @param requestId is the requestId generated by chainlink and used to grab the game struct
	 * @dev this resolves a game aganist the contract
	 */
    //@todo make one function that resolves both pvp and vrf games
	//@todo make it only callable by VRF fulfillRandomwords
    function resolveVrfGame(uint256 requestId) internal {
        ContractGame storage game = contractGameRequestId[requestId]; 
        if(game.playerMove == game.vrfMove){
            //draw
			updateScore(game.player, 1);
			emit Draw(msg.sender, address(0), timeToDate(block.timestamp));
            game.winner = address(0);
        } else if (((3 + game.playerMove - game.vrfMove) % 3) == 1) {
        // } else if ((game.playerMove + 1) % 3 == game.vrfMove) {
            // player wins 
			updateScore(game.player, 2);
			emit Winner(game.player, timeToDate(block.timestamp));
            game.winner = address(i_vrfCoordinator);
        } else {
            //player loses
    		emit Loser(game.player, timeToDate(block.timestamp));
        	game.winner = game.player;
        }
    }

	/**
	 * Function that updates the player score by adding the points
	 */
	// @note MUST CALL AFTER RESOLVING GAME
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

	////////////////////
	/// Getter Funcs ///
	////////////////////

	function getTournament() public view returns (string memory rName, address contractAddress, address rPoolIncentivized, string memory rLPTokenSymbol, uint256 rLPTokenAmount, uint256 rStartTime, uint256 rEndTime, uint256 rPlayers) {

		rName = name;
		contractAddress = address(this);
		rPoolIncentivized = address(poolIncentivized);
		rLPTokenSymbol = getLPSymbol();
		rLPTokenAmount = LPTokenAmount;
		rStartTime = startTime;
		rEndTime = endTime;
		rPlayers = players.length;
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
	 * Function that returns the current price per share from the LP token contract
	 */
	function getPricePerShare() public view returns(uint256, uint256) {
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
	 * Function that returns the current amount of LP token entitled to the player on withdrawal (before adding earned prizes)
	 */
	function LPTokenAmountOfPlayer(address _player) public view returns (uint256) {
		(uint256 pPS, uint256 pPS2) = getPricePerShare();
		// We prevent user to receive more LP than deposited in exeptional case where pPS disminushes
		pPS = (pPS < playersMap[_player].depositPricePerShare) ? playersMap[_player].depositPricePerShare : pPS;
		pPS2 = (pPS2 < playersMap[_player].depositPricePerShare2) ? playersMap[_player].depositPricePerShare2 : pPS2;
		if(Protocol.Yearn == protocol) {
			return LPTokenAmount * playersMap[_player].depositPricePerShare / pPS;
		} else { // Uniswap
			return LPTokenAmount * 1 ether / ( ( ( 1 ether * pPS / playersMap[_player].depositPricePerShare ) + ( 1 ether * pPS2 / playersMap[_player].depositPricePerShare2 ) ) / 2 );
		}
	}

	/**
	 * Function that returns the player's rank and how many players share this rank
	 */
	function getRank(address _player) public view returns (uint256 rank, uint256 split) {
		if(!isPlayer(_player)) return (0, 0);
		uint256 cumulativePlayers;
		for(uint i=topScore; i>=playersMap[_player].score; i--) {
			if(scoreToPlayers[i].length > 0) {
				cumulativePlayers += scoreToPlayers[i].length;
				rank += 1;
			}
			if(i == 0) { // If the player did not score, he won't be in in the mapping
				rank += 1;
				split = players.length - cumulativePlayers;
				return (rank, split);
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
		if(split == 0) return 0; // Not a player = no share
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
		return getPoolPrize() * fees / (1 ether - fees);
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
	 * 
	 */
	//@note compaired to midnight - use to reset live per day
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
		if(_score == 0) return new address[](0); // We don't return the list of players without any point
		return scoreToPlayers[_score];
	}

	function player(address _player) public view returns (uint256 rank, uint256 score, uint256 lastGame) {
		(rank, ) = getRank(_player);
		score = playersMap[_player].score;
		lastGame = playersMap[_player].lastGame;
	}

	function getLPDecimals() public view returns (uint8) {
		return IERC20Metadata(poolIncentivized).decimals();
	}

	function getLPSymbol() public view returns (string memory) {
		return IERC20Metadata(poolIncentivized).symbol();
	}

}
