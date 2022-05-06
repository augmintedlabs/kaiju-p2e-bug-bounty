# KaijuKingz P2E Bug Bounty

Bug Bounty Details: https://medium.com/@AugmintedLabs/kaijukingz-p2e-bug-bounty-864f7fe9e9c

P2E announcement: https://medium.com/@AugmintedLabs/kaijukingz-p2e-ecosystem-dc9577ff8773

Community-built infographic (Credit: [@HelmiMastuki](https://twitter.com/HelmiMastuki))
![](https://pbs.twimg.com/media/FOE68omXoAcGvrV?format=jpg&name=4096x4096 "KaijuKingz P2E")

## Simulator
Community-built
[P2E Simulator](https://my.machinations.io/d/Kaiju-P2E-Simulator-V1-0/bf69f02da07c11ec8c2902f943517e50) (Credit: [@chouapo](https://twitter.com/chouapo)) can be used to get a better understanding of the flow of resources in the P2E ecosystem. Simulator does not demonstrate batch extraction mechanic.

## Contracts
The ecosystem is made up of a total of 8 contracts:

1. KaijuKingz ([Deployed](https://etherscan.io/address/0x1685133a98e1d4fc1fe8e25b7493d186c37b6b24)) - The core ERC-721 contract. These are "Genesis" and "Baby" Kaijus.
2. RWaste ([Deployed](https://etherscan.io/address/0x7e75098588b3a47b4517bdcc29c98e62f9245217)) - ERC-20 token passively earned by Genesis tokens at a rate of 5/day.
3. Scales - ERC-20 token earned by staking Genesis and Baby tokens at a rate of 15/day and 5/day respectively. Staked Genesis generate RWaste tokens for the staking contract, with uses [REDACTED].
4. Mutants ([Deployed](https://etherscan.io/address/0x83f82414b5065bb9a85e330c67b4a10f798f4ed2)) - A supplemental ERC-721 collection. These are "Mutant" Kaijus that are able to be experimented on.
5. MutantScales - An auxiliary contract to the "Scales" contract that adds passive earning functionality for Mutant tokens at a rate of 2/day.  
6. DNA - An ERC-1155 collection. There are 5 elemental types of DNA, each having 5 categories of rarity (common, uncommon, rare, epic, legendary). DNA is earned by running experiments on Mutants, paid for in Scales.
7. Scientists - A supplemental ERC-721 collection. Scientists earn rewards (currently Scales and DNA) when experiments fail.

## Hardhat Commands

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```
