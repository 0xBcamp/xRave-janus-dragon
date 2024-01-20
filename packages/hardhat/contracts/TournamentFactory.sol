//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Tournament.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";

contract TournamentFactory {
	// State Variables
	Tournament[] public TournamentArray; // Store deployed contracts
	mapping(uint256 => address) public tidToAddress; // Mapping tid => contract address
	uint256 public tid; // Number of deployed contracts
	address public owner;

	// Events: a way to emit log statements from smart contract that can be listened to by external parties
	event TournamentCreated(
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
	 * Function that allows anyone to deploy a new tournament contract
	 *
	 * @param _poolIncentivized (address) - address of the pool to incentivize and from which we will accept the LP token
	 * @param _rewardToken (address) - address of the ERC-20 token used as prize for the players
	 * @param _rewardAmount (uint256) - amount of the ERC-20 token to fund the prize
	 * @param _LPTokenAmount (uint256) - amount of the ERC-20 LP token to stake in order to participate
	 * @param _startTime (uint256) - block number at which the tournament starts
	 * @param _endTime (uint256) - block number at which the tournament ends
	 *
	 * @return newTournament (address) - address of the new tournament
	 */
	function createTournament(address _poolIncentivized, address _rewardToken, uint256 _rewardAmount, uint256 _LPTokenAmount, uint256 _startTime, uint256 _endTime) public returns (address newTournament) {
		
	}

	/**
	 * Function that returns all the data from a tournament
	 */
	function getTournament(uint256 _tid) external view returns (address contractAddress, address poolIncentivized, address rewardToken, uint256 LPTokenAmount, uint256 rewardAmount, uint256 startTime, uint256 endTime) {

	}

	/**
	 * Function that returns an array of all the tournament contracts
	 */
	function getAllTournaments() external view returns (address[] memory) {

	}

	/**
	 * Function that returns an array of all the active tournament contracts
	 */
	function getAllActiveTournaments() external view returns (address[] memory) {

	}

	/**
	 * Function that returns an array of all the past tournament contracts
	 */
	function getAllPastTournaments() external view returns (address[] memory) {

	}

	/**
	 * Function that returns an array of all the future tournament contracts
	 */
	function getAllFutureTournaments() external view returns (address[] memory) {

	}

	/**
	 * Function that returns an array of all the tournament a player is registered to
	 */
	function getTournamentsByPlayer(address _player) external view returns (address[] memory) {

	}
}
