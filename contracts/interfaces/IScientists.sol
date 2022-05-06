//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IScientists is IERC721 {
    function getRandomScientistOwner(uint256) external returns (address);
    function increasePool(uint256) external;
}