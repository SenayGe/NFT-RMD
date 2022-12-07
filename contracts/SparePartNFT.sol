// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract SparePartNFT is ERC721, ERC721URIStorage {


    function mint(address _to) public returns (uint256) {
        tokenCount++;
        uint256 tokenCount_ = tokenCount;
        tokenIdToOwner[tokenCount_] = _to;
        OwnerToTokenCount[_to]++;
        return tokenCount_;
    }

    function safeTransfer () {}

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

}