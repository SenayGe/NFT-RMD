// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


interface IDeviceNFT {

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}
contract SparePartNFT is ERC721, ERC721URIStorage {


    function mint(address _to) public returns (uint256) {
        tokenCount++;
        uint256 tokenCount_ = tokenCount;
        tokenIdToOwner[tokenCount_] = _to;
        OwnerToTokenCount[_to]++;
        return tokenCount_;
    }

    function safeTransfer (address _from, address _to, uint256 _tokenId, bytes _data) external{
        transferFrom(_from, _to, _tokenId);
        if (isContract(_to)) {
            bytes4 val = IDeviceNFT(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            // require(retval == ERC721_RECEIVED_OLD);
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



}