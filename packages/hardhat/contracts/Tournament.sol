//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";

contract Tournament {
	// State Variables
	address public immutable owner;
	mapping(address => uint256) public playerToLPToken; // how much LP token each player has
	mapping(address => uint256) public playerToPoints; // how many points each player has
	mapping(address => uint256) public playerToLastGame; // when the player last played
	string public name;
	uint256 public contractLPToken; // amount of LP token held by the contract
	address public poolIncentivized;
	address public rewardToken;
	string public rewardTokenSymbol;
	string public LPTokenSymbol;
	uint256 public LPTokenAmount;
	uint256 public startTime;
	uint256 public endTime;
	uint256 public totalUnconvertedPoints;

	// Events: a way to emit log statements from smart contract that can be listened to by external parties
	event Staked(
	);

	event Unstaked(
	);

	// Constructor: Called once on contract deployment
	// Check packages/hardhat/deploy/00_deploy_your_contract.ts
	constructor(address _owner, string memory _name, address _poolIncentivized, address _rewardToken, uint256 _LPTokenAmount, uint256 _startTime, uint256 _endTime) {
		owner = _owner;
		name = _name;
		poolIncentivized = _poolIncentivized;
		rewardToken = _rewardToken;
		LPTokenAmount = _LPTokenAmount;
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

	function getTournament() public view returns (string memory name, address contractAddress, address poolIncentivized, address rewardToken, string memory LPTokenSymbol, uint256 LPTokenAmount, string memory rewardTokenSymbol, uint256 rewardAmount, uint256 startTime, uint256 endTime) {
		return (name, address(this), poolIncentivized, rewardToken, LPTokenSymbol, LPTokenAmount, rewardTokenSymbol, rewardAmount, startTime, endTime);
	}

	/**
	 * Function that allows anyone to stake their LP token to register in the tournament
	 */
	function stakeLPToken() public {

		// emit: keyword used to trigger an event
		emit Staked();
	}

	/**
	 * Function that allows anyone to unstake their LP token once the tournament is over
	 */
	function unstakeLPToken() public {

		// emit: keyword used to trigger an event
		emit Unstaked();
	}

	/**
	 * Function that allows the bot to sumbit a batch of signed moves for resolution
	 */
	function resolve() public {
	}

	function isActive() public view returns (bool) {
	}

	function isEnded() public view returns (bool) {
	}

	function isFuture() public view returns (bool) {
	}

	function isPlayer(address _player) public view returns (bool) {
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
