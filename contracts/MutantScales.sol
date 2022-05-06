//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMutants.sol";
import "./interfaces/IScales.sol";

error MutantScales_FunctionLocked();
error MutantScales_SenderNotTokenOwner();
error MutantScales_TokenIdOutOfRange();

/**                                     ..',,;;;;:::;;;,,'..
                                 .';:ccccc:::;;,,,,,;;;:::ccccc:;'.
                            .,:ccc:;'..                      ..';:ccc:,.
                        .':cc:,.                                    .,ccc:'.
                     .,clc,.                                            .,clc,.
                   'clc'                                                    'clc'
                .;ll,.                                                        .;ll;.
              .:ol.                                                              'co:.
             ;oc.                                                                  .co;
           'oo'                                                                      'lo'
         .cd;                                                                          ;dc.
        .ol.                                                                 .,.        .lo.
       ,dc.                                                               'cxKWK;         cd,
      ;d;                                                             .;oONWMMMMXc         ;d;
     ;d;                                                           'cxKWMMMMMMMMMXl.        ;x;
    ,x:            ;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0NMMMMMMMMMMMMMMNd.        :x,
   .dc           .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.        cd.
   ld.          .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl'         .dl
  ,x;          .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.             ;x,
  oo.         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                .oo
 'x:          .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                     :x'
 :x.           .xWMMMMMMMMMMM0occcccccccccccccccccccccccccccccccccccc:'                         .x:
 lo.            .oNMMMMMMMMMX;                                                                  .ol
.ol              .lXMMMMMMMWd.  ,dddddddddddddddo;.   .:dddddddddddddo,                          lo.
.dl                cXMMMMMM0,  'OMMMMMMMMMMMMMMNd.   .xWMMMMMMMMMMMMXo.                          ld.
.dl                 ;KMMMMNl   oWMMMMMMMMMMMMMXc.   ,OWMMMMMMMMMMMMK:                            ld.
 oo                  ,OWMMO.  ,KMMMMMMMMMMMMW0;   .cKMMMMMMMMMMMMWO,                             oo
 cd.                  'kWX:  .xWMMMMMMMMMMMWx.  .dKNMMMMMMMMMMMMNd.                             .dc
 ,x,                   .dd.  ;KMMMMMMMMMMMXo.  'kWMMMMMMMMMMMMMXl.                              ,x;
 .dc                     .   .,:loxOKNWMMK:   ;0WMMMMMMMMMMMMW0;                                cd.
  :d.                      ...      ..,:c'  .lXMMMMMMMMMMMMMWk'                                .d:
  .dl                      :OKOxoc:,..     .xNMMMMMMMMMMMMMNo.                                 cd.
   ;x,                      ;0MMMMWWXKOxoclOWMMMMMMMMMMMMMKc                                  ,x;
    cd.                      ,OWMMMMMMMMMMMMMMMMMMMMMMMMWO,                                  .dc
    .oo.                      .kWMMMMMMMMMMMMMMMMMMMMMMNx.                                  .oo.
     .oo.                      .xWMMMMMMMMMMMMMMMMMMMMXl.                                  .oo.
      .lo.                      .oNMMMMMMMMMMMMMMMMMW0;                                   .ol.
       .cd,                      .lXMMMMMMMMMMMMMMMWk'                                   ,dc.
         ;dc.                      :KMMMMMMMMMMMMNKo.                                  .cd;
          .lo,                      ;0WWWWWWWWWWKc.                                   'ol.
            ,ol.                     .,,,,,,,,,,.                                   .lo,
             .;oc.                                                                .co:.
               .;ol'                                                            'lo;.
                  ,ll:.                                                      .:ll,
                    .:ll;.                                                .;ll:.
                       .:ll:,.                                        .,:ll:.
                          .,:ccc;'.                              .';ccc:,.
                              .';cccc::;'...            ...';:ccccc;'.
                                    .',;::cc::cc::::::::::::;,..
                                              ........
 * @title MutantScales
 * @author Augminted Labs, LLC
 * @notice Passive rewards contract allowing MUTANT to earn $SCALES
 * @notice For more details see: https://medium.com/@AugmintedLabs/kaijukingz-p2e-ecosystem-dc9577ff8773
 */
contract MutantScales is Ownable, Pausable, ReentrancyGuard {
    IMutants public Mutants;
    IScales public Scales;

    uint256 public immutable START_TIME;
    uint256 public constant BASE_RATE = 2 ether;

    mapping(uint256 => uint256) public claimed;
    mapping(bytes4 => bool) public functionLocked;

    constructor(
        address mutants,
        address scales
    ) {
        Mutants = IMutants(mutants);
        Scales = IScales(scales);
        START_TIME = block.timestamp;
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert MutantScales_FunctionLocked();
        _;
    }

    /**
     * @notice Set SCALES token address
     * @param scales Address of SCALES token contract
     */
    function setScales(address scales) public lockable onlyOwner {
        Scales = IScales(scales);
    }

    /**
     * @notice Set MUTANT token address
     * @param mutants Address of MUTANT token contract
     */
    function setMutants(address mutants) public lockable onlyOwner {
        Mutants = IMutants(mutants);
    }

    /**
     * @notice Get the amount of $SCALES claimable from a MUTANT
     * @param tokenId MUTANT to return the the claimable $SCALES for
     * @return uint256 Amount of $SCALES claimable for specified MUTANT
     */
    function getClaimable(uint256 tokenId) public view returns (uint256) {
        if (tokenId >= Mutants.MAX_SUPPLY()) revert MutantScales_TokenIdOutOfRange();

        return ((BASE_RATE * (block.timestamp - START_TIME)) / 1 days) - claimed[tokenId];
    }

    /**
     * @notice Claim $SCALES for a specified set of MUTANT tokens
     * @param tokenIds MUTANT which the sender owns to claim $SCALES for
     */
    function claim(uint256[] calldata tokenIds) public whenNotPaused nonReentrant {
        uint256 totalClaimable = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != Mutants.ownerOf(tokenIds[i])) revert MutantScales_SenderNotTokenOwner();

            uint256 claimable = getClaimable(tokenIds[i]);
            claimed[tokenIds[i]] += claimable;
            totalClaimable += claimable;
        }

        Scales.credit(_msgSender(), totalClaimable);
    }

    /**
     * @notice Flip paused state to temporarily disable claiming
     */
    function flipPaused() public lockable onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyOwner {
        functionLocked[id] = true;
    }
}