// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

    /* Errors */
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState,
    );
    error Raffle__TransferFailed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__RaffleNotOpen();
    error NotOwner();
    error NotFunder();

contract DeFiConquest is VRFConsumerBaseV2, AutomationCompatibleInterface{
    
    /* Errors */
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState,
    );
    error Raffle__TransferFailed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__RaffleNotOpen();
    error NotOwner();
    error NotFunder();

    /* State variables */
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_entranceFee;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    using PriceConverter for uint256;
    uint256 private s_lastTimeStamp;
    RaffleState private s_raffleState;

    /* Type declarations for asynch call to oracle */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* Events */
    event RequestedFakePlayer(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event PlayerPicked(address indexed player);

    mapping(address => uint256) public addressToAmountDep;
    address[] public funders;

    address public /* immutable */ i_owner;
// entry deposit (15$)
    uint256 public constant MINIMUM_USD = 15 * 10 ** 18;
    uint256 public lives = 10;
    uint256 public recharge = 0;

    constructor(
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint256 lives,
        uint256 recharge,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
        ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_owner = msg.sender;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_entranceFee = entranceFee;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

// deposit to start playing
    bool public funderCheck;
    function deposit() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountDep[msg.sender] += msg.value;
        // if already a funder addLives()
        funderCheck = getFunders(msg.sender);
        recharge = (addressToAmountDep[msg.sender] - MINIMUM_USD)/1000000000000000000;
        require(msg.sender.funderCheck, addLife(recharge))
        funders.push(msg.sender);
        }

// TO DO add LP DeFi Tokens convertion
    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
        // converto to LP erc20 tokens
    }

// Players withdraw

   function withdraw() public onlyFunders {
        unit amount = addressToAmountDep[msg.sender];

        // this should delete the funders[] entry...

        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            if (funders[funderIndex] == msg.sender) {
                funders[funderIndex] = funders[funders.length - 1];
                funders.pop();
        }

        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: amount}("deposit withdrawed");
        require(callSuccess, "Call failed");
    }

// Owner withdraw

  function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

// Check if is funder

function getFunders(address addr) public returns bool {
for(uint256 i=0; i < funders.length; i++) {
    address addr = funders[i];
    return true;
    }
}

// Lives management
// TO DO develop maths adding up on deposit?

 function addLife(uint256 _lives) public virtual {
        lives = _lives + 5;
    }

// Add maths and function to get earned tokens (In eth?)

// Error transactions

    modifier onlyOwner {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

// TO DO modifier to restrict withdraw function

    modifier onlyFunders {
        if (amountToAmountDep[msg.sender] < 0) revert NotFunder();
        _;
    }
    
     fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }

    //function to start the turn

     function enterRaffle() public payable {
        // we should set i_entranceFee to minimu lives value
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        // Emit an event when we update a dynamic array or mapping
        // Named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
     * This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between playing turns (raffles).
     * 2. The raffle is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */

     function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /**
     * Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */

     function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        // Quiz... is this redundant?
        emit RequestedFakePlayer(requestId);
    }

     /**
     * This is the function that Chainlink VRF node
     * calls to play the game.
     */
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        // number of moves size 3 (paper scissors and rock)
        // randomNumber 202
        // 202 % 10 ? what's doesn't divide evenly into 202?
        // 20 * 10 = 200
        // 2
        // 202 % 10 = 2
        uint256 move = randomWords[0] % 3;
        
        //to do add maths for establishing winner

        s_lastTimeStamp = block.timestamp;
        emit PlayerPicked(move);

        //send LP tokens to winner

        // (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        // if (!success) {
        //    revert Raffle__TransferFailed();
        // }
    }

     /** Getter Functions */

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getFunder(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

}
