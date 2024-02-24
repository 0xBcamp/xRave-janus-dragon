//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Tournament} from"./Tournament.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error TournamentFactory__NotOwner();

contract TournamentFactory {
	// State Variables
	address[] private s_tournamentArray; // Store deployed contracts
	mapping(address => Tournament) private s_tournamentMap;
	mapping(address => address) private TournamentPartner;
	address public immutable i_owner;

	address private immutable i_implementationContract;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private s_gasLane;
    uint32 private s_callbackGasLimit = 1000000;

	constructor (address _owner, address _vrfCoordinatorV2) {
		i_owner = _owner;
		i_implementationContract = address(new Tournament());

		i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_subscriptionId = i_vrfCoordinator.createSubscription();

	}
	//// VRF deployment to Avax. @todo make structs for each chain? Pass in struct to createTournament() for vrf constructor args.
	// uint64 subscriptionId = 1341;
	// bytes32 gasLane = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
	// uint32 callbackGasLimit = 500000;
	// address vrfCoordinatorV2 = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;

	// Events: a way to emit log statements from smart contract that can be listened to by external parties
	event TournamentCreated(
		address tournament
	);

	// Modifier: used to define a set of rules that must be met before or after a function is executed
	modifier isOwner() {
		if(msg.sender != i_owner) revert TournamentFactory__NotOwner();
		_;
	}

	/**
	 * Function that allows anyone to deploy a new tournament contract
	 *
	 * @param _name (string) - name of the tournament
	 * @param _poolIncentivized (address) - address of the pool to incentivize and from which we will accept the LP token
	 * @param _LPTokenAmount (uint256) - amount of the ERC-20 LP token to stake in order to participate
	 * @param _startTime (uint256) - block timestamp at which the tournament starts
	 * @param _endTime (uint256) - block timestamp at which the tournament ends
	 * @return instance (address) - address of the new tournament
	 */
	function createTournament(
		string calldata _name, 
		address _poolIncentivized, 
		uint256 _LPTokenAmount, 
		uint32 _startTime, 
		uint32 _endTime
	) public returns(address instance) {
		instance = Clones.clone(i_implementationContract);
		Tournament(instance).initialize(
			i_owner, 
			_name, 
			_poolIncentivized, 
			_LPTokenAmount, 
			_startTime, 
			_endTime, 
			address(this),
			address(i_vrfCoordinator)
		);
		s_tournamentArray.push(instance);
		s_tournamentMap[instance] = Tournament(instance);
		i_vrfCoordinator.addConsumer(i_subscriptionId, instance);
		emit TournamentCreated(instance);
	}

	/**
	 * @notice Allows the owner to change the chainlink config
	 * @dev Gas lanes for each chain can be found here https://docs.chain.link/vrf/v2/subscription/supported-networks
	 * @param _gasLane (bytes32) - gas lane
	 * @param _callbackGasLimit (uint32) - callback gas limit
	 */
	function setChainlinkConfig(bytes32 _gasLane, uint32 _callbackGasLimit) external isOwner {
		s_gasLane = _gasLane;
		s_callbackGasLimit = _callbackGasLimit;
	}

	/**
	 * @notice Returns the chainlink config
	 * @dev For use by the clones when requesting a word to VRF
	 */
	function getVrfConfig() public view returns (uint64, bytes32, uint32) {
		return (i_subscriptionId, s_gasLane, s_callbackGasLimit);
	}

	/**
	 * @notice Returns an array of all the tournament contracts
	 * @return list (address[] memory) - list of all tournament
	 */
	function getAllTournaments() public view returns (address[] memory list) {
		list = s_tournamentArray;
	}

	/**
	 * @notice Returns an array of all the active tournament contracts
	 * @return activeTournaments (address[] memory) - list of all tournament
	 */
	function getAllActiveTournaments() external view returns (address[] memory activeTournaments) {
		uint activeCount = 0;
		uint length = s_tournamentArray.length;
		// First pass: Count the number of active tournaments
		for (uint i = 0; i < length; i++) {
			if (s_tournamentMap[s_tournamentArray[i]].isActive()) {
				activeCount++;
			}
		}

		// Second pass: Populate the array with active tournaments
		activeTournaments = new address[](activeCount);
		uint currentIndex = 0;
		for (uint i = 0; i < length; i++) {
			if (s_tournamentMap[s_tournamentArray[i]].isActive()) {
				activeTournaments[currentIndex] = s_tournamentArray[i];
				currentIndex++;
			}
		}
	}

	/**
	 * @notice Returns an array of all the past tournament contracts
	 * @return pastTournaments (address[] memory) - list of all tournament
	 */
	function getAllPastTournaments() external view returns (address[] memory pastTournaments) {
		uint count = 0;
		uint length = s_tournamentArray.length;
		// First pass: Count the number of active tournaments
		for (uint i = 0; i < length; i++) {

			if (s_tournamentMap[s_tournamentArray[i]].isEnded()) {
				count++;
			}
		}

		// Second pass: Populate the array with active tournaments
		pastTournaments = new address[](count);
		uint currentIndex = 0;
		for (uint i = 0; i < length; i++) {

			if (s_tournamentMap[s_tournamentArray[i]].isEnded()) {
				pastTournaments[currentIndex] = s_tournamentArray[i];
				currentIndex++;
			}
		}
	}

	/**
	 * @notice Returns an array of all the future tournament contracts
	 * @return futureTournaments (address[] memory) - list of all tournament
	 */
	function getAllFutureTournaments() external view returns (address[] memory futureTournaments) {
		uint count = 0;
		uint length = s_tournamentArray.length;

		// First pass: Count the number of active tournaments
		for (uint i = 0; i < length; i++) {
			if (s_tournamentMap[s_tournamentArray[i]].isFuture()) {
				count++;
			}
		}

		// Second pass: Populate the array with active tournaments
		futureTournaments = new address[](count);
		uint currentIndex = 0;
		for (uint i = 0; i < length; i++) {
			if (s_tournamentMap[s_tournamentArray[i]].isFuture()) {
				futureTournaments[currentIndex] = s_tournamentArray[i];
				currentIndex++;
			}
		}
	}

	/**
	 * @notice Returns an array of all the tournament entered by a player
	 * @return playersTournaments (address[] memory) - list of all tournament
	 */
	function getTournamentsByPlayer(address _player) external view returns (address[] memory playersTournaments) {
		uint count = 0;
		uint length = s_tournamentArray.length;

		// First pass: Count the number of active tournaments
		for (uint i = 0; i < length; i++) {
			if (s_tournamentMap[s_tournamentArray[i]].isPlayer(_player)) {
				count++;
			}
		}

		// Second pass: Populate the array with active tournaments
		playersTournaments = new address[](count);
		uint currentIndex = 0;
		for (uint i = 0; i < length; i++) {

			if (s_tournamentMap[s_tournamentArray[i]].isPlayer(_player)) {
				playersTournaments[currentIndex] = s_tournamentArray[i];
				currentIndex++;
			}
		}
	}

	/**
	 * Function that returns an array of all the tournament a partner created
	 */
	function getTournamentsByPartner(address _partner) external view returns (address[] memory) {

	}

	/**
	 * @notice Returns true if the contract is a deployed tournament, false otherwise
	 * @param _contract (address) - address of the contract
	 * @return (bool)
	 */
	function isTournament(address _contract) external view returns (bool) {
		if(address(s_tournamentMap[_contract]) == _contract) {
			return true;
		}
		return false;
	}
}

