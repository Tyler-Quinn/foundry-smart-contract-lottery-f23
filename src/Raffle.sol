// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title A sample Raffle Contract
 * @author Tyler Quinn (credit: Patrick Collins)
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    /* ERRORS */
    error Raffle_NotEnoughEthSent();
    error Raffle_NotEnoughTokenBalance();
    error Raffle_RaffleNotOpen();
    error Raffle_TransferFailed();
    error Raffle_UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /* TYPE DECLARATIONS */
    enum RaffleState {OPEN, CALCULATING}

    /* STATE VARIABLES */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1; 

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address private immutable i_raffleToken;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* EVENTS */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /* FUNCTIONS */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address raffleToken
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_raffleToken = raffleToken;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    /**
    
     */
    function enterRaffle() external payable {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }

        // if i_raffleToken is zero then the raffle is for native ETH
        if (i_raffleToken == address(0)) {
            if (msg.value < i_entranceFee) {
                revert Raffle_NotEnoughEthSent();
            }
        } else {
            if (IERC20(i_raffleToken).balanceOf(msg.sender) < i_entranceFee) {
                revert Raffle_NotEnoughTokenBalance();
            }
            IERC20(i_raffleToken).safeTransferFrom(msg.sender, address(this), i_entranceFee);
        }      

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Automation nodes call
     * to see if the it's time to perform an upkeep.
     * The following should be true for this to return true:
     * 1. The time interval has passed between raffle runs
     * 2. The raffle is in the OPEN state
     * 3. The contract has ETH (aka, players)
     * 4. The subscription is funded with LINK
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool hasBalance;
        if (i_raffleToken == address(0)) {
            hasBalance = address(this).balance > 0;
        } else {
            hasBalance = IERC20(i_raffleToken).balanceOf(address(this)) > 0;
        }
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
    
     */
    function performUpkeep(bytes calldata /*performData*/) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            uint256 balance;
            if (i_raffleToken == address(0)) {
                balance = address(this).balance;
            } else {
                balance = IERC20(i_raffleToken).balanceOf(address(this));
            }
            revert Raffle_UpkeepNotNeeded(
                balance,
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
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        address payable winner = s_players[randomWords[0] % s_players.length];
        s_recentWinner = winner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);

        if (i_raffleToken == address(0)) {
            (bool success,) = winner.call{value: address(this).balance}("");
            if (!success) {
                revert Raffle_TransferFailed();
            }
        } else {
            IERC20(i_raffleToken).safeTransfer(winner, IERC20(i_raffleToken).balanceOf(address(this)));
        }
    }

    /* GETTER FUNCTIONS */

    function getEntranceFee() external view returns (uint256) {
        return (i_entranceFee);
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return (s_players[indexOfPlayer]);
    }

    function getRecentWinner() external view returns (address) {
        return (s_recentWinner);
    }

    function getLengthOfPlayer() external view returns (uint256) {
        return (s_players.length);
    }

    function getLastTimestamp() external view returns (uint256) {
        return (s_lastTimeStamp);
    }
}