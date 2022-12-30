// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


interface IDeviceNFT {

    // function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}
contract SparePartNFT is ERC721, ERC721URIStorage {

    // string metadata = "https://ipfs.io/ipfs/Qme7ss3ARVqxv6rXVPiikMJ8u2NLqmgszg13pYrDKEoiu"
    constructor() ERC721("SPToken", "SPT") {}

    event ReplacementPartNFTMinted(uint256 indexed _tokenId, address _owner, string _tokenURI);
    event Retval (bytes4 retval);
    event TokenTransferedToParentNFT (uint256 _childTokenId, address _parentContract, bytes _encodedData);

    uint256 public tokenCount;

    // tokenId => token owner
    mapping(uint256 => address) internal tokenIdToOwner;
    // token owner address => token count
    mapping(address => uint256) internal OwnerToTokenCount;


    function mint(address _to, string calldata _metadata) public returns (uint256) {
        tokenCount++;
        uint256 tokenId = tokenCount;
        tokenIdToOwner[tokenId] = _to;
        OwnerToTokenCount[_to]++;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _metadata);
        emit ReplacementPartNFTMinted (tokenId, _to, _metadata);
        return tokenId;
    }

    function safeTransfer (address _from, address _to, uint256 _tokenId, bytes memory _data) external{
        transferFrom(_from, _to, _tokenId);
        if (isContract(_to)) {
            bytes4 val = IDeviceNFT(_to).onERC721Received(msg.sender, _from,_tokenId, _data);
            // require(retval == ERC721_RECEIVED_OLD);
            emit Retval (val);
            emit TokenTransferedToParentNFT (_tokenId, _to, _data);
        }

    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(_addr)}
        return size > 0;
    }

    function toBytes(uint256 x) public view returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) 
    }
}



}