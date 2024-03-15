// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffleToken.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RaffleTestToken is Test {
    using SafeERC20 for IERC20;

    // EVENTS
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    // TYPE DECLARATIONS
    Raffle raffle;
    HelperConfig helperConfig;

    // STATE VARIABLES
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address raffleToken;

    address public PLAYER = makeAddr("player");
    address public PLAYER_NO_BALANCE = makeAddr("noBalance");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    // MODIFIERS
    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    // FUNCTIONS
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            , //link
            //deployerKey
            ,
            raffleToken
        ) = helperConfig.activeNetworkConfig();
        deal(address(raffleToken), PLAYER, STARTING_USER_BALANCE);
        vm.prank(PLAYER);
        IERC20(raffleToken).approve(address(raffle), type(uint256).max);
    }

    function testRaffleInitializedInOpenState() public {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    //////////////////////////
    // enterRaffle
    //////////////////////////
    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER_NO_BALANCE);
        vm.expectRevert(Raffle.Raffle_NotEnoughTokenBalance.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle();
    }

    function testTokenTransferOnEntrance() public {
        assert(IERC20(raffleToken).balanceOf(PLAYER) == STARTING_USER_BALANCE);
        assert(IERC20(raffleToken).balanceOf(address(raffle)) == 0);
        vm.prank(PLAYER);
        raffle.enterRaffle();
        assert(IERC20(raffleToken).balanceOf(PLAYER) == STARTING_USER_BALANCE - entranceFee);
        assert(IERC20(raffleToken).balanceOf(address(raffle)) == entranceFee);
    }

    function testCantEnterWhenRaffleIsCalculating() public raffleEnteredAndTimePassed {
        raffle.performUpkeep("");

        vm.expectRevert();
        vm.prank(PLAYER);
        raffle.enterRaffle();
    }

    //////////////////////////
    // checkUpkeep
    //////////////////////////
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public raffleEnteredAndTimePassed {
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public raffleEnteredAndTimePassed {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    //////////////////////////
    // performUpkeep
    //////////////////////////
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public raffleEnteredAndTimePassed {
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public 
        raffleEnteredAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState rState = raffle.getRaffleState();
        
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    //////////////////////////
    // fulfillRandomWords
    //////////////////////////
    function testFulfillRandomWordsCanOnlyBecalledAfterPerformUpkeep(uint256 requestId)
        public 
        raffleEnteredAndTimePassed
        skipFork
    {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksWinnerResetsAndSendsMoney()
        public 
        raffleEnteredAndTimePassed
        skipFork
    {
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; ++i) {
            address player = address(uint160(i));
            deal(address(raffleToken), player, STARTING_USER_BALANCE);
            vm.startPrank(player);
            IERC20(raffleToken).approve(address(raffle), type(uint256).max);
            raffle.enterRaffle();
            vm.stopPrank();
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimestamp = raffle.getLastTimestamp();

        // pretend to be Chainlink VRF to get random number & pick winner
        vm.expectEmit(false, false, false, false, address(raffle));
        emit PickedWinner(address(0)); // don't know winner until after function call
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayer() == 0);
        assert(previousTimestamp < raffle.getLastTimestamp());
        assert(IERC20(raffleToken).balanceOf(raffle.getRecentWinner()) == STARTING_USER_BALANCE + prize - entranceFee);
    }
}