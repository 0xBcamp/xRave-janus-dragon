//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable-4.7.3/utils/cryptography/ECDSAUpgradeable.sol";

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
}


contract Tournament is Initializable, VRFConsumerBaseV2Upgradeable {
    using ECDSAUpgradeable for bytes32;

	//////////////
	/// ERRORS ///
	//////////////

	error Tournament__AlreadyPlayed();
	error Tournament__AlreadyStaked();
	error Tournament__InvalidEndTime();
	error Tournament__InvalidMove();
	error Tournament__InvalidStartTime();
	error Tournament__InvalidTimeRange();
	error Tournament__NoFees();
	error Tournament__NothingToWithdraw();
	error Tournament__NotOwner();
	error Tournament__NotPlayer();
	error Tournament__RequestFailed();
	error Tournament__RequestNotFound();
	error Tournament__StakingNotAllowed();
	error Tournament__TournamentNotActive();
	error Tournament__UnstakingNotAllowed();
	error Tournament__ZeroDepositAmount();

	///////////////////////
	/// State Variables ///
	///////////////////////

	address public s_owner;
	
	//TOURNAMENT INFO
	string private s_name; // Name of the tournament
	IERC20Metadata private s_poolIncentivized;
	uint256 private s_depositAmount; // Exact Amount of LP to be deposited by the players
	uint32 private s_startTime;
	uint32 private s_endTime;
	address private s_factory;
	enum Protocol {
		Uniswap,
		Yearn
	}
	Protocol private s_protocol;
	uint256 private s_realizedPoolPrize; // Amount of LP left by players that withdrawn
	uint256 private s_realizedFees; // Amount of LP fees left by players that withdrawn
	uint64 private s_unclaimedPoolPrize = 1 ether; // 100% of the pool prize unclaimed
	uint64 public constant FEES = 0.1 ether; // 10% fees on pool prize
	uint16 public s_topScore = 0;
	uint256 private s_nbRanks = 1;

	// PLAYER INFO
	address[] private s_players;
	mapping(uint16 => address[]) private s_scoreToPlayers; // Used for ranking
	mapping(address => Player) private s_playersMap; //address => Player Struct

	struct Player {
		uint16 score; // how many points each player has
		uint8 streak; // number of consecutive wins
		uint32 lastGame; // when the player last played (used to determine if the player already played today)
		uint depositPricePerShare; // price per share at deposit
	}
	struct StoredPlayer {
		address addr;
		bytes32 hash;
		uint32 lastGame;
	}
	StoredPlayer private s_storedPlayer;


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

    VRFCoordinatorV2Interface private s_vrfCoordinator;    
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
		if(msg.sender != s_owner) revert Tournament__NotOwner();
		_;
	}

	function initialize(
		address _owner, 
		string calldata _name, 
		address _poolIncentivized, 
		uint256 _depositAmount, 
		uint32 _startTime, 
		uint32 _endTime, 
		address _factory,
		address _vrfCoordinator
		) public initializer {
			if(_startTime >= _endTime) revert Tournament__InvalidTimeRange();
			// Defaults to current block timestamp
			s_startTime = _startTime == 0 ? uint32(block.timestamp) : _startTime;
			if(_startTime < block.timestamp) revert Tournament__InvalidStartTime();
			if(_endTime <= block.timestamp) revert Tournament__InvalidEndTime();
			if(_depositAmount == 0) revert Tournament__ZeroDepositAmount();
			s_owner = _owner;
			s_name = _name;
			s_depositAmount = _depositAmount;
			if(_poolIncentivized != address(0)) {
				s_poolIncentivized = IERC20Metadata(_poolIncentivized);
				string memory symbol = s_poolIncentivized.symbol();
				if(keccak256(abi.encodePacked(symbol)) == keccak256("UNI-V2")) {
					s_protocol = Protocol.Uniswap;
				} else {
					s_protocol = Protocol.Yearn;
				}
			}
			s_endTime = _endTime;
			s_factory = _factory;
			// VRF
			__VRFConsumerBaseV2Upgradeable_init(_vrfCoordinator);
			s_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
		}

	/////////////////////////////
	/// Stake & Unstake Funcs ///
	/////////////////////////////

	/**
	 * @notice Allows the players to stake their LP token to register for the tournament
	 */
	function stakeLPToken() public {
		if(isPlayer(msg.sender)) revert Tournament__AlreadyStaked();
		if(!stakingAllowed()) revert Tournament__StakingNotAllowed();
		IERC20(s_poolIncentivized).transferFrom(msg.sender, address(this), s_depositAmount); // Revert message handled by the ERC20 transferFrom function
		s_playersMap[msg.sender].depositPricePerShare = getPricePerShare();
		s_players.push(msg.sender);
		// emit: keyword used to trigger an event
		emit Staked(msg.sender, s_depositAmount);
	}

	/**
	 * @notice Allows the players to withdraw their entitled LP token amount once the tournament is over
	 * @dev Also updates the state of the contract to reflect the withdrawal
	 */
	function unstakeLPToken() public {
		if(!isPlayer(msg.sender)) revert Tournament__NothingToWithdraw(); // Address never staked or already withdrew
		if(!unstakingAllowed()) revert Tournament__UnstakingNotAllowed();
		// Get back its deposited value of underlying assets
		uint256 amount = withdrawAmountFromDeposit(msg.sender); // corresponds to deposited underlying assets
		uint256 extraPoolPrize = (1 ether - FEES) * (s_depositAmount - amount) / 1 ether; // How much LP token is left by the user
		s_realizedFees += s_depositAmount - amount - extraPoolPrize;
		// Add rewards from the game
		amount += getPrizeAmount(msg.sender);
		s_realizedPoolPrize += extraPoolPrize;
		s_unclaimedPoolPrize -= getPrizeShare(msg.sender);

		s_playersMap[msg.sender].depositPricePerShare = 0; // Reuse of this variable to indicate that the player unstaked its LP token

		IERC20(s_poolIncentivized).transfer(msg.sender, amount);
		emit Unstaked(msg.sender, amount);
	}

	/**
	 * @notice Allows the owner to withdraw realized fees
	 * @dev Total fees will be available for withdrawal once all players have withdrawn
	 * @dev Partial fees can be withdran at any time after players begun to withdraw
	 */
	function withdrawFees() public onlyOwner {
		if(s_realizedFees == 0) revert Tournament__NoFees();
		uint256 _realizedFees = s_unclaimedPoolPrize == 0 ? s_poolIncentivized.balanceOf(address(this)) : s_realizedFees;
		s_realizedFees = 0;
		IERC20(s_poolIncentivized).transfer(msg.sender, _realizedFees);
	}


	///////////////////////////
	/// GAME PLAY FUNCTIONS ///
	///////////////////////////

	/**
	 * @notice Generate the hashes corresponding to the player moves
	 * @param _player is the player address
	 */
	function hashMoves(address _player) public view returns(bytes32 hash0, bytes32 hash1, bytes32 hash2) {
		if(!isActive() || alreadyPlayed(_player) || !isPlayer(_player)) return (0, 0, 0);
		return _hashMoves(_player, s_playersMap[_player].lastGame);
	}

	/**
	 * @notice Generate the hashes corresponding to the player moves
	 */
	function _hashMoves(address _player, uint32 _lastGame) internal view returns(bytes32 hash0, bytes32 hash1, bytes32 hash2) {
		hash0 = keccak256(abi.encodePacked(
			_player,
			address(this),
			uint(0),
			_lastGame
		));

		hash1 = keccak256(abi.encodePacked(
			_player,
			address(this),
			uint(1),
			_lastGame
		));

		hash2 = keccak256(abi.encodePacked(
			_player,
			address(this),
			uint(2),
			_lastGame
		));
	}

	/**
	 * @notice Find the player move from its hash
	 */
	function recoverMove(address _player, bytes32 _hash, uint32 _lastGame) internal view returns(uint8) {

		(bytes32 hash0, bytes32 hash1, bytes32 hash2) = _hashMoves(_player, _lastGame);
		if(_hash == hash0) return 0;
		if(_hash == hash1) return 1;
		if(_hash == hash2) return 2;
		revert Tournament__InvalidMove();
	}

	/**
	 * @notice Submit a move for play against another player
	 */
	function playAgainstPlayer(bytes32 _hash) public {
		if(!isActive()) revert Tournament__TournamentNotActive();
		if(alreadyPlayed(msg.sender)) revert Tournament__AlreadyPlayed();
		if(!isPlayer(msg.sender)) revert Tournament__NotPlayer();

        if(s_storedPlayer.addr != address(0)) {
			// A player is already waiting to be matched
			uint8 senderMove = recoverMove(msg.sender, _hash, s_playersMap[msg.sender].lastGame);
			uint8 storedMove = recoverMove(s_storedPlayer.addr, s_storedPlayer.hash, s_storedPlayer.lastGame);

            resolveGame(msg.sender, senderMove, s_storedPlayer.addr, storedMove);
			s_storedPlayer.addr = address(0);
        } else {
			// No player is waiting to be matched, we store the move and wait for a player to join
			recoverMove(msg.sender, _hash, s_playersMap[msg.sender].lastGame); // We check that the move is valid before saving it

            s_storedPlayer.addr = msg.sender;
			s_storedPlayer.hash = _hash;
			s_storedPlayer.lastGame = s_playersMap[msg.sender].lastGame;
        }

		s_playersMap[msg.sender].lastGame = uint32(block.timestamp);        
        emit MoveSaved(msg.sender, 0);
	}

	/**
	 * @notice Submit a move for play against a contract
	 * @param _move is the player's move
	 * @return requestId is the requestId generated by chainlink and used to grab the game struct
	 */
	function playAgainstContract(uint8 _move) public returns(uint256 requestId) {
		if(_move > 2) revert Tournament__InvalidMove();
		if(!isActive()) revert Tournament__TournamentNotActive();
		if(alreadyPlayed(msg.sender)) revert Tournament__AlreadyPlayed();
		if(!isPlayer(msg.sender)) revert Tournament__NotPlayer();
		s_playersMap[msg.sender].lastGame = uint32(block.timestamp);

        requestId = _requestRandomWords(_move, msg.sender);

        if(requestId == 0) revert Tournament__RequestFailed();
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

		(uint64 _subscriptionId, bytes32 _gasLane, uint32 _callbackGasLimit) = Factory(s_factory).getVrfConfig();

		// Will revert if subscription is not set and funded.
		//@todo can I just call this in the play function??
		requestId = s_vrfCoordinator.requestRandomWords(
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
        if(!contractGameRequestId[requestId].exists) revert Tournament__RequestNotFound();
      
        // number of moves size 3 (0rock 1paper 2scissor)
        uint8 vrfMove = uint8(randomWords[0] % 3);

        ContractGame storage game = contractGameRequestId[requestId];

        game.fulfilled = true;
        game.randomWords = randomWords;
        game.vrfMove = vrfMove;

        resolveGame(game.player, game.playerMove, address(0), vrfMove);
    }

	//////////////////////////////
	/// RESOLVE GAME FUNCTIONS ///
	//////////////////////////////

	/**
	 * @notice Resolves the game against another player
	 * @dev Will resolve the game against another player. If against VRF, _stored will be VRF
	 * @param _senderAddr The address of the player
	 * @param _senderMove The move the player made
	 * @param _storedAddr The address of the stored player. Will be 0x0 for VRF
	 * @param _storedMove The move the stored player made
	 */
	function resolveGame(address _senderAddr, uint8 _senderMove, address _storedAddr, uint8 _storedMove) internal {
		if(_senderMove == _storedMove) {
            // Draw
			updateScore(_senderAddr, 1);
			updateScore(_storedAddr, 1);
			emit Draw(_senderAddr, _storedAddr, timeToDate(uint32(block.timestamp)));
        } else if (((3 + _senderMove - _storedMove) % 3) == 1) {
            // sender wins
			updateScore(_senderAddr, 2);
			updateScore(_storedAddr, 0);
			emit Winner(_senderAddr, timeToDate(uint32(block.timestamp)));
			emit Loser(_storedAddr, timeToDate(uint32(block.timestamp)));
        } else {
			// storedPlayer wins
			updateScore(_storedAddr, 2);
			updateScore(_senderAddr, 0);
			emit Winner(_storedAddr, timeToDate(uint32(block.timestamp)));
			emit Loser(_senderAddr, timeToDate(uint32(block.timestamp)));
        }
    }

	/**
	 * @notice Updates the player score by adding points
	 * @dev Should be called in any case. Also updates player's rank and streak
	 * @param _player is the address of the player. VRF will be 0x0
	 * @param _points 0 = lost, 1 = draw, 2 = won
	 */
	function updateScore(address _player, uint8 _points) internal {
		if(_player == address(0)) return; // We don't update VRF score
		if(_points == 0) {
			s_playersMap[_player].streak = 0;
			return;
		} else if(_points == 2) {
			s_playersMap[_player].streak += 1;
		}
		// We first remove the player from it's current rank
		uint16 score = s_playersMap[_player].score;
		uint256 length = s_scoreToPlayers[score].length;
		for(uint i=0; i<length; i++) {
			if(s_scoreToPlayers[score][i] == _player) {
				s_scoreToPlayers[score][i] = s_scoreToPlayers[score][s_scoreToPlayers[score].length - 1];
				break;
			}
		}
		if(score > 0) {
			s_scoreToPlayers[score].pop();
			if(s_scoreToPlayers[score].length == 0) { s_nbRanks -= 1; } // No more players at this rank
		}
		// Now we can update the score and push the user to its new rank
		s_playersMap[_player].score += _points**s_playersMap[_player].streak;
		if(s_topScore < s_playersMap[_player].score) {
			s_topScore = s_playersMap[_player].score;
		}
		s_scoreToPlayers[s_playersMap[_player].score].push(_player);
		if(s_scoreToPlayers[s_playersMap[_player].score].length == 1) { s_nbRanks += 1; } // New rank created for this player
	}

	////////////////////
	/// Getter Funcs ///
	////////////////////

	function getTournament() public view returns (
		string memory rName,
		address contractAddress,
		address rPoolIncentivized,
		string memory rLPTokenSymbol,
		uint8 rProtocol,
		address token0,
		address token1,
		uint256 rdepositAmount,
		uint8 rDecimals,
		uint32 rStartTime,
		uint32 rEndTime,
		uint16 rPlayers,
		uint256 poolPrize
	) {
		rName = s_name;
		contractAddress = address(this);
		rPoolIncentivized = address(s_poolIncentivized);
		rLPTokenSymbol = getFancySymbol();
		rProtocol = uint8(s_protocol);
		(token0, token1) = getUnderlyingAssets();
		rdepositAmount = s_depositAmount;
		rDecimals = getLPDecimals();
		rStartTime = s_startTime;
		rEndTime = s_endTime;
		rPlayers = getNumberOfPlayers();
		poolPrize = getExpectedPoolPrize();
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
		if(Protocol.Yearn == s_protocol) {
			YearnInterface yearn = YearnInterface(address(s_poolIncentivized));
			pPS = yearn.pricePerShare();
		} else { // Uniswap
			UniswapInterface uniswap = UniswapInterface(address(s_poolIncentivized));
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
		if(s_playersMap[_player].depositPricePerShare == 0) return 0; // User aleady withdrew
		// We prevent user to receive more LP than deposited in exeptional case where pPS disminushes
		pPS = (pPS < s_playersMap[_player].depositPricePerShare) ? s_playersMap[_player].depositPricePerShare : pPS;
		amount = s_depositAmount * s_playersMap[_player].depositPricePerShare / pPS;
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
		uint16 playerScore = s_playersMap[_player].score;
		for(uint16 i=s_topScore; i>=playerScore; i--) {
			if(s_scoreToPlayers[i].length > 0) {
				cumulativePlayers += uint16(s_scoreToPlayers[i].length);
				rank += 1;
			}
			if(i == 0) { // If the player did not score, he won't be in in the mapping
				rank += 1;
				split = uint16(s_players.length) - cumulativePlayers;
				return (rank, split);
			}
		}
		split = uint16(s_scoreToPlayers[s_playersMap[_player].score].length);
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
		uint8 multiplier = (s_nbRanks == rank) ? 2 : 1; // We double the allocation for the last rank so that sum of shares is 100%
		share = uint64((multiplier * 1 ether / (2 ** rank)) / split);
	}

	/**
	 * @notice Returns the total pool prize
	 * @dev The realized pool price is static while remaining pool prize is dynamic
	 * @return amount The pool prize amount
	 */
	function getPoolPrize() public view returns (uint256 amount) {
		amount = s_realizedPoolPrize + getRemainingPoolPrize();
	}

	/**
	 * @notice Returns the amount of pool prize left
	 * @dev The number of LP tokens will be obtained from the players that did not withdraw yet
	 * @return amount The remaining pool prize amount
	 */
	function getRemainingPoolPrize() public view returns (uint256 amount) {
		uint256 extraLP = 0;
		uint256 length = s_players.length;
		for (uint i=0; i<length; i++) {
			if(s_playersMap[s_players[i]].depositPricePerShare == 0) continue; // The player withdrew, we skip him
			extraLP += s_depositAmount - withdrawAmountFromDeposit(s_players[i]);
		}
		amount = extraLP * (1 ether - FEES) / 1 ether;
	}

	/**
	 * @notice Returns the amount of pool prize earned by the user
	 * @dev Unclaimed pool prize is cross multiplied by the player share and divided by the unclaimed shares
	 * @param _player The player address
	 * @return amount The user pool prize amount
	 */
	function getPrizeAmount(address _player) public view returns (uint256 amount) {
		amount = getRemainingPoolPrize() * getPrizeShare(_player) / s_unclaimedPoolPrize;
	}

	/**
	 * @notice Returns if the expected pool prize at the end of the tournament
	 * @dev Current pool prize is cross multiplied by the duration of the tournament and divided by the elapsed time
	 * @return (uint256) The expected pool prize amount
	 */
	function getExpectedPoolPrize() public view returns (uint256) {
		if(isFuture()) return 0;
		if(isEnded()) return getPoolPrize();
		return getPoolPrize() * (s_endTime - s_startTime) / (1 + block.timestamp - s_startTime); // Add 1 to avoid division by 0
	}

	/**
	 * @notice Returns if the amount of fees accrued by the protocol
	 * @return amount The amount of fees
	 */
	function getFees() internal view returns (uint256 amount) {
		amount = getPoolPrize() * FEES / (1 ether - FEES);
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
		ended = timeToDate(uint32(block.timestamp)) >= timeToDate(s_endTime);
	}

	/**
	 * @notice Returns if the tournament is not yet started
	 * @dev Players can only stake if the tournament is future. Use stakingAllowed() to check if staking is allowed
	 * @return future
	 */
	function isFuture() public view returns (bool future) {
		future = timeToDate(uint32(block.timestamp)) < timeToDate(s_startTime);
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
		isP = s_playersMap[_player].depositPricePerShare > 0;
	}

	/**
	 * @notice Returns if the player has already played today
	 * @dev Resets at O0:OO UTC
	 * @param _player The player address
	 */
	function alreadyPlayed(address _player) public view returns (bool) {
		uint32 today = timeToDate(uint32(block.timestamp));
		uint32 lastGame = timeToDate(s_playersMap[_player].lastGame);
		return today == lastGame;
	}

	/**
	 * @notice Returns the player's score
	 * @param _player The player address
	 */
	function pointsOfPlayer(address _player) public view returns (uint16) {
		return s_playersMap[_player].score;
	}

	/**
	 * @notice Returns if staking is allowed
	 * @dev Players can stake anytime until 1 day before the end of the game. If they were able to stake at last minute, they could get a share of the pool prize without any contribution.
	 * @return (bool)
	 */
	function stakingAllowed() public view returns (bool) {
		return timeToDate(uint32(block.timestamp)) < timeToDate(s_endTime - 1 days);
	}

	/**
	 * @notice Returns if unstaking is allowed
	 * @dev Players can stake anytime after the end of the game
	 * @return (bool))
	 */
	function unstakingAllowed() public view returns (bool) {
		return isEnded();
	}

	/**
	 * @notice Returns the number of players
	 * @return number Number of players
	 */
	function getNumberOfPlayers() public view returns (uint16 number) {
		number = uint16(s_players.length);
	}

	/**
	 * @notice Returns the list of all players
	 * @return arr List of players
	 */
	function getPlayers() public view returns (address[] memory arr) {
		arr = s_players;
	}

	/**
	 * @notice Returns the list of players at a given score
	 * @param _score The score of the players
	 * @return arr List of players
	 */
	function getPlayersAtScore(uint16 _score) public view returns (address[] memory arr) {
		if(_score == 0) return new address[](0); // We don't return the list of players without any point
		arr = s_scoreToPlayers[_score];
	}

	/**
	 * @notice Returns data available on the player
	 * @param _player The address of the player
	 * @return rank of the player
	 * @return score of the player
	 */
	function getPlayer(address _player) public view returns (uint16 rank, uint16 score) {
		(rank, ) = getRank(_player);
		score = s_playersMap[_player].score;
	}

	/**
	 * @notice Returns the number of decimals of the LP token
	 * @return decimals Number of decimals
	 */
	function getLPDecimals() public view returns (uint8 decimals) {
		decimals = IERC20Metadata(s_poolIncentivized).decimals();
	}

	/**
	 * @notice Returns the symbol of the pool as defined in the pool contract
	 * @return symbol of the pool
	 */
	function getLPSymbol() public view returns (string memory symbol) {
		symbol = IERC20Metadata(s_poolIncentivized).symbol();
	}

	/**
	 * @notice Returns the addresses of the underlying assets
	 * @return token0 (address) for yearn or Uniswap
	 * @return token1 (address) for Uniswap
	 */
	function getUnderlyingAssets() public view returns (address token0, address token1) {
		if(s_protocol == Protocol.Uniswap) {
			token0 = UniswapInterface(address(s_poolIncentivized)).token0();
			token1 = UniswapInterface(address(s_poolIncentivized)).token1();
		} else {
			token0 = YearnInterface(address(s_poolIncentivized)).token();
			token1 = address(0);
		}
	}

	/**
	 * @notice Returns the symbol of the pool
	 * @dev If the pool is Uniswapn it adds the symbol of the underlying tokens to UNI-V2
	 * @return symbol "fancy" symbol of the pool
	 */
	function getFancySymbol() public view returns (string memory symbol) {
		if(s_protocol == Protocol.Uniswap) {
			address token0 = UniswapInterface(address(s_poolIncentivized)).token0();
			address token1 = UniswapInterface(address(s_poolIncentivized)).token1();
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
