//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Tournament {
	// State Variables
	address public immutable owner;
	mapping(address => uint256) public playerToLPToken; // how much LP token each player has
	mapping(address => uint256) public playerToPoints; // how many points each player has
	mapping(address => uint256) public playerToLastGame; // when the player last played
	string public name;
	uint256 public contractLPToken; // amount of LP token held by the contract
	IERC20Metadata poolIncentivized;
	string public LPTokenSymbol;
	uint256 public LPTokenAmount;
	uint256 public startTime;
	uint256 public endTime;
	uint256 public totalUnconvertedPoints;

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
		owner = _owner;
		name = _name;
		LPTokenAmount = _LPTokenAmount;
		if(_poolIncentivized != address(0)) {
			poolIncentivized = IERC20Metadata(_poolIncentivized);
			LPTokenSymbol = poolIncentivized.symbol();
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
		playerToLPToken[msg.sender] += LPTokenAmount;
		// emit: keyword used to trigger an event
		emit Staked(msg.sender, LPTokenAmount);
	}

	/**
	 * Function that allows anyone to unstake their LP token once the tournament is over
	 */
	function unstakeLPToken() public {
		uint256 amount = playerToLPToken[msg.sender];
		playerToLPToken[msg.sender] = 0;
		require(IERC20(poolIncentivized).transfer(msg.sender, amount), "Transfer of LP token Failed");

		// emit: keyword used to trigger an event
		emit Unstaked(msg.sender, amount);
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

	function isActive() public view returns (bool) {
	}

	function isEnded() public view returns (bool) {
	}

	function isFuture() public view returns (bool) {
	}

	function isPlayer(address _player) public view returns (bool) {
		return playerToLPToken[_player] > 0;
	}

	function numberOfPlayers() public view returns (uint256) {
	}

	function livesOfPlayer(address _player) public view returns (uint256) {
	}

	function pointsOfPlayer(address _player) public view returns (uint256) {
	}

	function LPTokenAmountOfPlayer(address _player) public view returns (uint256) {
	}

	function rewardTokenAmountOfPlayer(address _player) public view returns (uint256) {
	}

	function stakingAllowed() public view returns (bool) {
	}

	function unstakingAllowed() public view returns (bool) {
	}

	function player(address _player) public view returns (uint256 LPToken, uint256 points, uint256 lastGame) {
	}

}
