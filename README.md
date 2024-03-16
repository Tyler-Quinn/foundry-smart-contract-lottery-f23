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

## Testing

```
forge test
```

or

```
forge test --fork-url $SEPOLIA_URL
```

### Test Coverage

```
forge coverage
```


# Deployment to a testnet or mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file, similar to what you see in `.env.example`.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)). **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
  - You can [learn how to export it here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key).
- `SEPOLIA_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

1. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

2. Deploy

There are two deploy scripts; one for deploying an ETH raffle, one for deploying an ERC20 raffle. Respectively...

```
make deployEthRaffle ARGS="--network sepolia"

make deployTokenRaffle ARGS="--network sepolia"
```

To change the raffle entranceFee or interval; in the HelperConfig.s.sol, change these values in the returned NetworkConfig for the desired network.

To change the token to be deployed for an ERC20 raffle; in the DeployRaffleToken.s.sol, change the raffleTokenAddress for the desired network.

This will setup a ChainlinkVRF Subscription for you. If you already have one, update it in the `scripts/HelperConfig.s.sol` file. It will also automatically add your contract as a consumer.

3. Register a Chainlink Automation Upkeep

[You can follow the documentation if you get lost.](https://docs.chain.link/chainlink-automation/compatible-contracts)

Go to [automation.chain.link](https://automation.chain.link/new) and register a new upkeep. Choose `Custom logic` as your trigger mechanism for automation. Your UI will look something like this once completed:

![Automation](./img/automation.png)

## Example Deployed Contracts

For my testing, I have a Chainlink VRF with ID=9936 on Ethereum Sepolia. Here are some deployed contracts on Sepolia...

0xfb4ed178d24edbab16ebe51c691329c0bfb00764 - Raffle for native ETH

0xe24ed22205d55400d3fd921f3ce475ea4f3cdd3a - Raffle for LINK ERC20

## Scripts

After deploying to a testnet or local net, you can run the scripts.

Using cast deployed locally example:

```
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.1ether --private-key <PRIVATE_KEY> --rpc-url $SEPOLIA_RPC_URL
```

or, to create a ChainlinkVRF Subscription:

```
make createSubscription ARGS="--network sepolia"
```

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see an output file called `.gas-snapshot`

# Formatting

To run code formatting:

```
forge fmt
```