// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        address raffleTokenAddress;

        if (block.chainid == 11155111) {
            raffleTokenAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;   // Sepolia Link
        } else {
            vm.startBroadcast();
            MockERC20 mockERC20 = new MockERC20("testToken", "TT");
            vm.stopBroadcast();
            raffleTokenAddress = address(mockERC20);
        }

        HelperConfig helperConfig = new HelperConfig(raffleTokenAddress);
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit, 
            address link,
            uint256 deployerKey,
            address raffleToken
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator,
                deployerKey
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                link,
                deployerKey
            );
        }

        vm.startBroadcast(deployerKey);
        Raffle raffle = new Raffle (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            raffleToken
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinator,
            subscriptionId,
            deployerKey
        );
        return (raffle, helperConfig);
    }
}