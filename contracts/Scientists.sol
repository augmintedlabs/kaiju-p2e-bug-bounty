//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "./interfaces/IScales.sol";
import "./interfaces/IScientists.sol";
import "./interfaces/ISpendable.sol";
import "./interfaces/IRWaste.sol";

error Scientists_AddressAlreadyMinted();
error Scientists_FunctionLocked();
error Scientists_InsufficientSupply();
error Scientists_InsufficientValue();
error Scientists_InvalidScientistData();
error Scientists_InvalidScientistId();
error Scientists_InvalidSignature();
error Scientists_MintMustBeClosed();
error Scientists_ScientistAlreadyMinted();
error Scientists_SenderNotTokenOwner();


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
 * @title Scientists
 * @author Augminted Labs, LLC
 * @notice Scientists passively earn $SCALES, DNA, and KAIJU
 * @notice For more details see: https://medium.com/@AugmintedLabs/kaijukingz-p2e-ecosystem-dc9577ff8773
 */
contract Scientists is IScientists, ERC721AQueryable, AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    struct ScientistInfo {
        bytes32 data;
        uint256 claimed;
    }

    struct MintConfig {
        uint256 price;
        address signer;
    }

    event EmploymentContractSigned(
        address indexed account,
        uint256 indexed tokenId,
        bytes32 indexed scientistData
    );

    IScales public Scales;
    MintConfig public mintConfig;

    uint256 public constant MAX_SUPPLY = 10_000; // Actual SCIENTIST supply is [REDACTED]
    bytes32 public constant POOL_CONTROLLER_ROLE = keccak256("POOL_CONTROLLER_ROLE");

    uint256 public scalesPool;
    mapping(uint256 => ScientistInfo) public scientistInfo;
    mapping(bytes32 => bool) public scientistMinted;
    mapping(address => bool) public addressMinted;
    mapping(bytes4 => bool) public functionLocked;

    string internal _baseTokenURI;

    constructor(address scales)
        ERC721A("Scientists", "SCIENTIST")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        Scales = IScales(scales);

        mintConfig = MintConfig({
            price: 0.01 ether, // Actual SCIENTIST price is [REDACTED]
            signer: address(0)
        });
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert Scientists_FunctionLocked();
        _;
    }

    /**
     * @notice Get random owner of a SCIENTIST
     * @return address Random SCIENTIST owner
     */
    function getRandomScientistOwner(uint256 randomness) public view override returns (address) {
        uint256 totalMinted = _totalMinted();

        return totalMinted == 0
            ? 0x000000000000000000000000000000000000dEaD
            : ownerOf(randomness % totalMinted);
    }

    /**
     * @notice Get claimable $SCALES for a SCIENTIST
     * @param tokenId SCIENTIST to get the claimable $SCALES from
     * @return uint256 Amount of $SCALES claimable for a specified SCIENTIST
     */
    function getClaimable(uint256 tokenId) public view returns (uint256) {
        return (scalesPool / _totalMinted()) - scientistInfo[tokenId].claimed;
    }

    /**
     * @inheritdoc ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Set base token URI
     * @param URI Base metadata URI to be prepended to token ID
     */
    function setBaseTokenURI(string memory URI) public lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = URI;
    }

    /**
     * @notice Set $SCALES token address
     * @param scales Address of $SCALES token contract
     */
    function setScales(address scales) public lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        Scales = IScales(scales);
    }

    /**
     * @notice Set configuration for mint
     * @param _mintConfig Struct with updated configuration values
     */
    function setMintConfig(MintConfig calldata _mintConfig) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintConfig = _mintConfig;
    }

    /**
     * @notice Mint a SCIENTIST
     * @dev Scientist data is validated off-chain to reduce transaction cost
     * @param scientistData Byte string representing SCIENTIST traits
     * @param signature Signature created by mintConfig.signer using validated SCIENTIST data as input
     */
    function mint(bytes32 scientistData, bytes memory signature)
        public
        payable
        lockable
        nonReentrant
    {
        if (addressMinted[_msgSender()]) revert Scientists_AddressAlreadyMinted();
        if (scientistMinted[scientistData]) revert Scientists_ScientistAlreadyMinted();
        if (msg.value != mintConfig.price) revert Scientists_InsufficientValue();
        if (_totalMinted() + 1 > MAX_SUPPLY) revert Scientists_InsufficientSupply();

        if (mintConfig.signer != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(scientistData))),
            signature
        )) revert Scientists_InvalidSignature();

        uint256 tokenId = _totalMinted();
        scientistInfo[tokenId].data = scientistData;
        scientistMinted[scientistData] = true;
        addressMinted[_msgSender()] = true;

        _mint(_msgSender(), 1, "", false);

        emit EmploymentContractSigned(_msgSender(), tokenId, scientistData);
    }

    /**
     * @notice Increase the amount of $SCALES in the pool
     * @param amount $SCALES to add to the pool
     */
    function increasePool(uint256 amount) public override onlyRole(POOL_CONTROLLER_ROLE) {
        scalesPool += amount;
    }

    /**
     * @notice Claim $SCALES earned by a SCIENTIST
     * @dev $SCALES are credited to the sender's account, not actually minted
     * @param tokenId SCIENTIST to claim the $SCALES from
     */
    function claimScales(uint256 tokenId) public nonReentrant {
        if (_msgSender() != ownerOf(tokenId)) revert Scientists_SenderNotTokenOwner();

        _claimScales(tokenId);
    }

    /**
     * @notice Claim $SCALES earned by a SCIENTIST
     * @dev $SCALES are credited to the sender's account, not actually minted
     * @param tokenId SCIENTIST to claim the $SCALES from
     */
    function _claimScales(uint256 tokenId) internal {
        if (!functionLocked[this.mint.selector]) revert Scientists_MintMustBeClosed();

        uint256 claimable = getClaimable(tokenId);

        scientistInfo[tokenId].claimed += claimable;

        Scales.credit(ownerOf(tokenId), claimable);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Claims earned $SCALES when a token is transferred
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721A, IERC721)
    {
        if (functionLocked[this.mint.selector]) _claimScales(tokenId);

        ERC721A.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Claims earned $SCALES when a token is transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A, IERC721)
    {
        if (functionLocked[this.mint.selector]) _claimScales(tokenId);

        ERC721A.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @inheritdoc ERC721A
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Withdraw all ETH transferred to the contract
     */
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyRole(DEFAULT_ADMIN_ROLE) {
        functionLocked[id] = true;
    }
}