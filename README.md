# Proveably Random Raffle Contracts

## About

This code is to create a proveably random smart contract lottery. It implements Chainlink VRF and to select the winner from an array of participants and Chainlink Automation to trigger automatic payouts to the winner.

In addition to Patrick Collins' Foundry lesson, this has been modified to deploy raffle contracts for native ETH or any ERC20 token. Any number of raffles can be deployed for various tokens and various entranceFee amounts; all take advantage of Chainlink VRF and Automation to trigger automatic payouts.

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

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```
git clone https://github.com/Tyler-Quinn/foundry-smart-contract-lottery-f23.git
cd foundry-smart-contract-lottery-f23
forge build
```

# Usage

## Start a local node

```
make anvil
```

## Library

If you're having a hard time installing the chainlink library, you can optionally run this command. 

```
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
```

## Deploy

This will default to your local node. You need to have it running in another terminal in order for it to deploy.

There are two deploy scripts; one for deploying a raffle for native ETH, one for deploying a raffle for any ERC20 token.

```
make deployEthRaffle

make deployTokenRaffle
```

## Deploy - Other Network

[See below](#deployment-to-a-testnet-or-mainnet)