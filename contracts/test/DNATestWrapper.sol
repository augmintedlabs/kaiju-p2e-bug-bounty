//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "../DNA.sol";

contract DNATestWrapper is DNA {
    constructor(
        string memory uri,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subId
    )
        DNA(
            uri,
            vrfCoordinator,
            keyHash,
            subId
        )
    {}

    function __fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) public {
        fulfillRandomWords(requestId, randomWords);
    }

    function __getTokenId(uint256 randomness, uint256 boost) public view returns (uint256) {
        return getTokenId(randomness, boost);
    }

    function __getExtractionResults(
        uint256 randomness,
        uint256 mutantId,
        uint256 boost
    )
        public
        view
        returns (ExtractionResults memory)
    {
        return ExtractionResults({
            success: (randomness % 10) < (2 + contracts.Mutants.tier(mutantId)),
            tokenId: getTokenId(randomness, boost),
            criticality: uint8(uint256((keccak256(abi.encode(randomness, CRITICALITY_ENTROPY)))) % 100)
        });
    }
}