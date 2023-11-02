// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AxiomV2Client.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Badge is ERC721, AxiomV2Client, Ownable {
    event ClaimBadge(
        address indexed recipient,
        uint256 indexed queryId,
        uint256 tokenId,
        bytes32[] axiomResults
    );

    bytes32 public constant EVENT_SCHEMA = 0xab752bc10a81e9689c5aa42e23d7ecd59799f9758c37855cc7f7b7a17c751f6d;
    address public constant QUERY_ADDRESS = 0x89faDd7Cc959dAa0171ec2D78E6EE9f6C6d768a9;

    uint64 public callbackSourceChainId;
    bytes32 public axiomCallbackQuerySchema;
    mapping(address => bool) public querySubmitted;
    mapping(address => bool) public hasMinted;

    uint256 public tokenId;

    constructor(
        address _axiomV2QueryAddress,
        uint64 _callbackSourceChainId,
        bytes32 _axiomCallbackQuerySchema
    ) AxiomV2Client(_axiomV2QueryAddress) {
        callbackSourceChainId = _callbackSourceChainId;
        axiomCallbackQuerySchema = _axiomCallbackQuerySchema;
    }

    function updateCallbackQuerySchema(
        bytes32 _axiomCallbackQuerySchema
    ) public onlyOwner {
        axiomCallbackQuerySchema = _axiomCallbackQuerySchema;
        emit AxiomCallbackQuerySchemaUpdated(_axiomCallbackQuerySchema);
    }

    function _axiomV2Callback(
        uint64 sourceChainId,
        address recipient,
        bytes32 querySchema,
        uint256 queryId,
        bytes32[] calldata axiomResults,
        bytes calldata extraData
    ) internal virtual override {
        require(!hasMinted[hasMinted], "Badge: Recipient has minted badge before");

        //Parse result from addToCAllback() in circuits
        bytes32 eventSchema = axiomResults[0];
        address userEventAddress = address(uint160(uint256(axiomResults[1])));
        uint32 blockNum = uint32(uint256(axiomResults[2]));
        address queryContractAddress = address(uint160(uint256(axiomResults[3])));

        require(eventSchema == EVENT_SCHEMA, "Badge: Invalid event check");
        require(userEventAddress == recipient, "Badge: Invlid recipient address");
        require(blockNum >= 9972550, "Badge: Fail in block number limitation check");
        require(queryContractAddress == QUERY_ADDRESS, "Badge: Invalid query contract");

        hasMinted[recipient] = true;
        _safeMint(recipient, tokenId);

        emit ClaimBadge(
            recipient,
            queryId,
            tokenId,
            axiomResults
        );
        tokenId ++;
    }

    function _validateAxiomV2Call(
        uint64 sourceChainId,
        address callerAddr,
        bytes32 querySchema
    ) internal virtual override {
        require(sourceChainId == callbackSourceChainId, "AxiomV2: caller sourceChainId mismatch");
        require(querySchema == axiomCallbackQuerySchema, "AxiomV2: query schema mismatch");
    }
}
