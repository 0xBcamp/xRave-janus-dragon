// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
//@note could not use 8.20 because of PUSH0 error in Remix 8.17 is default for ScaffoldETH
// WHY DEAL WITH LIVES?? -> your deposits are your lives. 
//@todo add getters 

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

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract SingleGame is VRFConsumerBaseV2, Ownable {
    //////////////
    /// ERRORS ///
    //////////////
    error NoLivesLeft();
    error InvalidMove();
    error NotEnoughFunds();


    /// State Variables ///

    // @todo do I need lives/points?
    uint256 lives; // must be over 0 to play
    uint256 points;
    uint256 MINIMUM_DEPOSIT = 1000000000000000; //0.001 eth @todo replace w/token

    uint8 currentMove; // 0 = no move must start game, 1 = rock, 2 = paper, 3 = scissors @todo encrypt 1, 2, 3?? 
    address currentPlayer;


    mapping(address => uint256) public livesLeft; // lives left of player
    mapping(address => uint256) public playersPoints; // number of points a player has
    mapping(address => uint256) public deposits; // deposits of player

    //mapping(address => uint8) private currentPlayerMove; // current move of player @todo encrypt
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

    // requestId --> GameStatus  
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

    /// Events /// 

    event ContractPlayed(uint256 move);
    event MoveMade(uint256 move);
    event PlayerPlayedAganistContract(uint8 playerMove);
    event GameResolved(address winner);
    event RequestSent(uint256 requestId);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

     constructor(uint64 subscriptionId, bytes32 gasLane, uint32 callbackGasLimit, address vrfCoordinatorV2)
        VRFConsumerBaseV2(vrfCoordinatorV2) {
            i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
            i_subscriptionId = subscriptionId;
            i_gasLane = gasLane;
            gasLimit = callbackGasLimit;
        }

    ///////////////////////
    /// Fund Management ///
    ///////////////////////
    //@todo accept deposits from token
    function deposit(uint256 amount) public  {
        if(amount < MINIMUM_DEPOSIT){
            revert NotEnoughFunds();
        }

        deposits[msg.sender] += amount;
        livesLeft[msg.sender] += 10; //@todo deposit amount to lives amount / MINIMUM_DEPOSIT;
    }
    //@todo withdraw deposits of token
    function withdraw(uint256 amount) public {
        if(deposits[msg.sender] < amount){
            revert NotEnoughFunds();
        }

        deposits[msg.sender] -= amount;
        livesLeft[msg.sender] = 0;
    }   

    //////////////////////
    /// Play Functions ///
    //////////////////////

    ///@param playerMove - 0 = rock, 1 = paper, 2 = scissors
    ///outcome - 0 = draw, 1 = win, 2 = lose
    //@todo uint8 for variables?
    function playAganistContract(uint8 playerMove) public /*payable*/ {
        if(playerMove > 2){
            revert InvalidMove();
        }
        
        if(livesLeft[msg.sender] == 0){
            revert NoLivesLeft();
        }

        if(deposits[msg.sender] <= MINIMUM_DEPOSIT){
            revert NoLivesLeft();
        }

        livesLeft[msg.sender] -= 1;
        _requestRandomWords(playerMove, msg.sender);

        emit PlayerPlayedAganistContract(playerMove);

    }

    function play(uint8 move) public /*payable*/ {
        if(move == 0 || move > 3){
            revert InvalidMove();
        }
        
        if(livesLeft[msg.sender] == 0){
            revert NoLivesLeft();
        }

        if(deposits[msg.sender] <= MINIMUM_DEPOSIT){
            revert NoLivesLeft();
        }

        livesLeft[msg.sender] -= 1;

        //store move
        if(currentMove > 0){
            //resolve game -> set currentMove to 0
            _resolveGame(move);     
        } else {
            currentMove = move;
            currentPlayer = msg.sender;
        }
        
        emit MoveMade(move);

    }

    function _resolveGame(uint8 move) internal returns (address winner){
        if(move == currentMove){
            //draw
            playersPoints[msg.sender] += 2;
            playersPoints[currentPlayer] += 2;

            winner = address(0);

        } else if ((move + 1) % 3 == currentMove) {
            // currentPlayer wins + 4 points & refunded life // @todo
            playersPoints[currentPlayer] += 4;
            winner = currentPlayer;
        } else {
            // currentPlayer loses
            playersPoints[msg.sender] += 4;
            winner = msg.sender;
        }

        currentMove = 0;
        currentPlayer = address(0);
        return winner;
    }

    function startGameWithWager(uint256 wager) public {
        // @todo
    }


    //@todo make this resolve pvp game too
    function resolveVrfGame(uint256 requestId) public returns (address winner) {
        ContractGame storage game = contractGameRequestId[requestId];

        if ((game.playerMove + 1) % 3 == game.vrfMove) {
            // player wins + 2 points & refunded life // @todo
            playersPoints[game.player] += 2;
            livesLeft[game.player] += 1;
            game.winner = game.player;
        } else if (game.playerMove == game.vrfMove) {
            // player ties + 1 points refund life??
            playersPoints[game.player] += 1;
            livesLeft[game.player] += 1;
        } else {
            // player loses
            //livesLeft[msg.sender] -= 1;
            game.winner = address(i_vrfCoordinator);
        }

        winner = game.winner;
        emit GameResolved(winner);
    }

    ////////////////////////
    //// VRFv2 functions ///
    ////////////////////////

    // fuji id: 1341
    //  gaslane: 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61
    // vrf: 0x2eD832Ba664535e5886b75D64C46EB9a228C2610


    // It will request a random number from the VRF 
    // If a request is successful, the callback function, fulfillRandomWords will be called.
    // @return requestId is the requestId generated by chainlink
    function _requestRandomWords(uint8 playerMove, address player) internal returns (uint256 requestId) {

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
                playerMove: playerMove,
                player: player,
                fulfilled: false,
                exists: true,
                randomWords: new uint256[](0),
                vrfMove: 3, // Placeholder value indicating unfulfilled request
                winner: address(0)
            });

            requestIds.push(requestId);
            lastRequestId = requestId;

            emit RequestSent(requestId);
            return requestId;
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
        
        emit ContractPlayed(vrfMove);
    }


    /////////////////////////////////
    /// Getter / Helper Functions ///
    /////////////////////////////////

    function getLivesLeft(address player) public view returns (uint256) {
        return livesLeft[player];
    }

    function getPoints(address player) public view returns (uint256) {
        return playersPoints[player];
    }
    
    function getDeposits(address player) public view returns (uint256) {
        return deposits[player];
    }

    function getContractGame(uint256 requestId) public view returns (ContractGame memory) {
        return contractGameRequestId[requestId];
    }



}
   