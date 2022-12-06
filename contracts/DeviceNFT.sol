// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

interface ERC998ERC721TopDown {
    event ReceivedChild(address indexed _from, uint256 indexed _tokenId, address indexed _childContract, uint256 _childTokenId);
    event TransferChild(uint256 indexed tokenId, address indexed _to, address indexed _childContract, uint256 _childTokenId);

    function rootOwnerOf(uint256 _tokenId) external view returns (bytes32 rootOwner);
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) external view returns (bytes32 rootOwner);
    function ownerOfChild(address _childContract, uint256 _childTokenId) external view returns (bytes32 parentTokenOwner, uint256 parentTokenId);
    function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns (bytes4);
    function transferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external;
    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external;
    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId, bytes _data) external;
    function transferChildToParent(uint256 _fromTokenId, address _toContract, uint256 _toTokenId, address _childContract, uint256 _childTokenId, bytes _data) external;
    // getChild function enables older contracts like cryptokitties to be transferred into a composable
    // The _childContract must approve this contract. Then getChild can be called.
    function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external;
}

contract DeviceFactory {

    event DeviceCreated (uint256 indexed deviceTokenId);


}

contract DeviceNFT is ERC721, ERC721URIStorage { // IERC721Enumerable, IERC721Reveiver

    
    ERC721 public sparePartContract;
    
    uint256 public tokenCount;
    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // tokenId => token owner
    mapping(uint256 => address) internal tokenIdToOwner;

    // token owner address => token count
    mapping(address => uint256) internal OwnerToTokenCount;

    // token owner => (operator address => bool)
    mapping(address => mapping(address => bool)) internal tokenOwnerToOperators;
    

    function mint(address _to) public returns (uint256) {
        tokenCount++;
        uint256 tokenCount_ = tokenCount;
        tokenIdToOwner[tokenCount_] = _to;
        OwnerToTokenCount[_to]++;
        return tokenCount_;
    }

}