//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Tournament.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TournamentFactory {
	// State Variables
	address[] public TournamentArray; // Store deployed contracts
	mapping(address => Tournament) public TournamentMap;
	mapping(address => address) public TournamentPartner;
	address public owner;

	//// VRF deployment to Avax. @todo make structs for each chain? Pass in struct to createTournament() for vrf constructor args.
	// uint64 subscriptionId = 1341;
	// bytes32 gasLane = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
	// uint32 callbackGasLimit = 500000;
	// address vrfCoordinatorV2 = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;

	// Events: a way to emit log statements from smart contract that can be listened to by external parties
	event TournamentCreated(
		address tournament
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
	 * @param _name (string) - name of the tournament
	 * @param _poolIncentivized (address) - address of the pool to incentivize and from which we will accept the LP token
	 * @param _LPTokenAmount (uint256) - amount of the ERC-20 LP token to stake in order to participate
	 * @param _startTime (uint256) - block number at which the tournament starts
	 * @param _endTime (uint256) - block number at which the tournament ends
	 *
	 * @return newTournament (address) - address of the new tournament
	 */
	function createTournament(
		string memory _name, 
		address _poolIncentivized, 
		uint256 _LPTokenAmount, 
		uint256 _startTime, 
		uint256 _endTime, 
		uint64 _subscriptionId, 
		bytes32 _gasLane, 
		uint32 _callbackGasLimit, 
		address _vrfCoordinatorV2
	) public returns (Tournament newTournament) {
		newTournament = new Tournament(
			owner, 
			_name, 
			_poolIncentivized, 
			_LPTokenAmount, 
			_startTime, 
			_endTime, 
			_subscriptionId, 
			_gasLane, 
			_callbackGasLimit, 
			_vrfCoordinatorV2
		);
		TournamentArray.push(address(newTournament));
		TournamentMap[address(newTournament)] = newTournament;
		emit TournamentCreated(address(newTournament));
	}


	/**
	 * Function that returns an array of all the tournament contracts
	 */
	function getAllTournaments() public view returns (address[] memory list) {
		list = TournamentArray;
	}


	/**
	 * Function that returns an array of all the active tournament contracts
	 */
	function getAllActiveTournaments() external view returns (address[] memory) {
		uint activeCount = 0;

		// First pass: Count the number of active tournaments
		for (uint i = 0; i < TournamentArray.length; i++) {
			if (TournamentMap[TournamentArray[i]].isActive()) {
				activeCount++;
			}
		}

		// Second pass: Populate the array with active tournaments
		address[] memory activeTournaments = new address[](activeCount);
		uint currentIndex = 0;
		for (uint i = 0; i < TournamentArray.length; i++) {
			if (TournamentMap[TournamentArray[i]].isActive()) {
				activeTournaments[currentIndex] = TournamentArray[i];
				currentIndex++;
			}
		}

		return activeTournaments;
	}

	/**
	 * Function that returns an array of all the past tournament contracts
	 */
	function getAllPastTournaments() external view returns (address[] memory) {
		uint count = 0;

		// First pass: Count the number of active tournaments
		for (uint i = 0; i < TournamentArray.length; i++) {

			if (TournamentMap[TournamentArray[i]].isEnded()) {
				count++;
			}
		}

		// Second pass: Populate the array with active tournaments
		address[] memory pastTournaments = new address[](count);
		uint currentIndex = 0;
		for (uint i = 0; i < TournamentArray.length; i++) {

			if (TournamentMap[TournamentArray[i]].isEnded()) {
				pastTournaments[currentIndex] = TournamentArray[i];
				currentIndex++;
			}
		}


		return pastTournaments;
	}

	/**
	 * Function that returns an array of all the future tournament contracts
	 */
	function getAllFutureTournaments() external view returns (address[] memory) {
		uint count = 0;


		// First pass: Count the number of active tournaments
		for (uint i = 0; i < TournamentArray.length; i++) {
			if (TournamentMap[TournamentArray[i]].isFuture()) {
				count++;
			}
		}

		// Second pass: Populate the array with active tournaments
		address[] memory futureTournaments = new address[](count);
		uint currentIndex = 0;
		for (uint i = 0; i < TournamentArray.length; i++) {
			if (TournamentMap[TournamentArray[i]].isFuture()) {
				futureTournaments[currentIndex] = TournamentArray[i];
				currentIndex++;
			}
		}

		return futureTournaments;
	}

	/**
	 * Function that returns an array of all the tournament a player is registered to
	 */
	function getTournamentsByPlayer(address _player) external view returns (address[] memory) {
		uint count = 0;

		// First pass: Count the number of active tournaments
		for (uint i = 0; i < TournamentArray.length; i++) {
			if (TournamentMap[TournamentArray[i]].isPlayer(_player)) {
				count++;
			}
		}

		// Second pass: Populate the array with active tournaments
		address[] memory playersTournaments = new address[](count);
		uint currentIndex = 0;
		for (uint i = 0; i < TournamentArray.length; i++) {

			if (TournamentMap[TournamentArray[i]].isPlayer(_player)) {
				playersTournaments[currentIndex] = TournamentArray[i];
				currentIndex++;
			}
		}


		return playersTournaments;
	}

	/**
	 * Function that returns an array of all the tournament a partner created
	 */
	function getTournamentsByPartner(address _partner) external view returns (address[] memory) {

	}

	/**
	 * Function that returns true if the contract is a deployed tournament, false otherwise
	 */
	function isTournament(address _contract) external view returns (bool) {
		if(address(TournamentMap[_contract]) == _contract) {
			return true;
		}
		return false;
	}
}

