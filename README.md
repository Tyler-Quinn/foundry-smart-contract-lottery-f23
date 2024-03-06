# Proveably Random Raffle Contracts

## About

This code is to create a proveably random smart contract lottery. It implements Chainlink VRF and to select the winner from an array of participants and Chainlink Automation to trigger automatic payouts to the winner.

From Patrick Collins' Foundry course
https://github.com/Cyfrin/foundry-smart-contract-lottery-f23/tree/main

## What we want it to do

1. Users can enter by paying for a ticket
   1. The ticket fees are going to go to the winner during the draw
2. After X period of time, the lottery will automatically draw a winner
   1. And this will be done programatically
3. Using Chainlink VRF and Chainklink Automation
   1. Chainlink VRF -> Randomness
   2. Chainlink Automation -> Time based trigger

## Tests

1. Write some deploy scripts
2. Write our tests
   1. Work on a local chain
   2. Forked Testnet