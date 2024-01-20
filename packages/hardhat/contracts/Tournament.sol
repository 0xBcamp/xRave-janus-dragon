//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";

contract Tournament {
	// State Variables
	address public immutable owner;
	mapping(address => uint256) public playerToLPToken;
	mapping(address => uint256) public playerToPoints;
	uint256 public contractLPToken; // amount of LP token held by the contract
	address public poolIncentivized;
	address public rewardToken;
	string public rewardTokenSymbol;
	uint256 public rewardAmount;
	string public LPTokenSymbol;
	uint256 public LPTokenAmount;
	uint256 public startTime;
	uint256 public endTime;

	// Events: a way to emit log statements from smart contract that can be listened to by external parties
	event Staked(
	);

	event Unstaked(
	);

	// Constructor: Called once on contract deployment
	// Check packages/hardhat/deploy/00_deploy_your_contract.ts
	constructor(address _owner) {
		owner = _owner;
	}

	// Modifier: used to define a set of rules that must be met before or after a function is executed
	// Check the withdraw() function
	modifier isOwner() {
		// msg.sender: predefined variable that represents address of the account that called the current function
		require(msg.sender == owner, "Not the Owner");
		_;
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

	function isPlayer() public view returns (bool) {
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

}
