// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface ERC998ERC721TopDown {
    event AttachedChild(address indexed _from, uint256 indexed _tokenId, address indexed _childContract, uint256 _childTokenId);
    event ReceivedToken (uint256 _childTokenId, address indexed _childContract);
    event TransferChild(uint256 indexed tokenId, address indexed _to, address indexed _childContract, uint256 _childTokenId);

    // function rootOwnerOf(uint256 _tokenId) external view returns (bytes32 rootOwner);
    // function rootOwnerOfChild(address _childContract, uint256 _childTokenId) external view returns (bytes32 rootOwner);
    // function ownerOfChild(address _childContract, uint256 _childTokenId) external view returns (bytes32 parentTokenOwner, uint256 parentTokenId);
    // function onERC721Received( address _from, uint256 _childTokenId, bytes memory _data)  external returns (bytes4);
    // function transferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external;
    // function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external;
    // function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId, bytes _data) external;
    // function transferChildToParent(uint256 _fromTokenId, address _toContract, uint256 _toTokenId, address _childContract, uint256 _childTokenId, bytes _data) external;
    
    // getChild function enables older contracts like cryptokitties to be transferred into a composable
    // The _childContract must approve this contract. Then getChild can be called.
    function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external;
}


contract DeviceFactory {

    event DeviceCreated (uint256 indexed deviceTokenId);


}

contract DeviceNFT is ERC721, ERC721URIStorage, ERC998ERC721TopDown, IERC721Receiver{ // IERC721Enumerable, IERC721Reveiver

    //metadata = https://ipfs.io/ipfs/Qme7ss3ARBgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu
    //metadata = ipfs://bafybeidi4xixphrxar6humruz4mn6ul7nzmres7j4triakpfabiezll4ti/0001_v1.json
    // meta = ipfs://bafybeic3ui7dj5dzsvqeiqbxjgg3fjmfmiinb3iyd2trixj2voe4jtefgq/0001_v2.json

    constructor() ERC721("RMDToken", "RMDT") {}

    event DeviceNFTMinted(uint256 indexed _tokenId, address _owner, string _tokenURI);
    event NFTUpdated (uint256 _tokenID, uint256 _version, string _previousMetadata, string _updatedMetadata);

    
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

    // child's TokenId => address of child contract
    mapping (uint256 => address []) internal childContracts;

    // Parent tokenId => (child contract address => array of children tokens)
    mapping (uint256 => mapping (address => uint256 [])) childTokens;

    //mapping childContractsIndex
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) private childTokenIndex;

    // child address => childId => ParentTokenId
    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;

    // tokenId => (child address => contract index+1)
    mapping(uint256 => mapping(address => uint256)) private childContractIndex;
    

    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

    function mint(address _to) public returns (uint256) {
        tokenCount++;
        uint256 tokenCount_ = tokenCount;
        tokenIdToOwner[tokenCount_] = _to;
        OwnerToTokenCount[_to]++;
        return tokenCount_;
    }

    // This smart contract has to be approved in the spare parts contract
    // _from is the current owner of the child token
    function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external override{
        attachChild(_from, _tokenId, _childContract, _childTokenId);
        require(_from == msg.sender ||
        ERC721(_childContract).isApprovedForAll(_from, msg.sender) ||
        ERC721(_childContract).getApproved(_childTokenId) == msg.sender);
        ERC721(_childContract).transferFrom(_from, address(this), _childTokenId);

    }


    // TODO: Modify so that a certificate NFT cannot be transferred
    // function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external {
    //     uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
    //     require(tokenId > 0 || childTokenIndex[tokenId][_childContract][_childTokenId] > 0);
    //     require(tokenId == _fromTokenId);
    //     require(_to != address(0));
    //     address rootOwner = address(rootOwnerOf(tokenId));
    //     require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
    //     rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender);
    //     removeChild(tokenId, _childContract, _childTokenId);
    //     ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId);
    //     emit TransferChild(tokenId, _to, _childContract, _childTokenId);
    // }

    function mintParent (address _to, string calldata _metadata ) external returns (uint256){
        
        // require {
        //     accessControls.hasMinterRole(_msgSender()),
        //     "DeviceNFT.mint: Sender must have minter role"
        // }
        tokenCount++;
        uint256 tokenId = tokenCount;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _metadata);
        tokenIdToOwner[tokenId] = _to;
        OwnerToTokenCount[_to]++;

        emit DeviceNFTMinted (tokenId, _to, _metadata);
        return tokenId;
    }

    

    function attachChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) private{
        // check if parent NFT exists
        require(tokenIdToOwner[_tokenId] != address(0), "_tokenId does not exist.");

        // Check if child token had already been attached
        require(childTokenIndex[_tokenId][_childContract][_childTokenId] == 0, "Cannot receive child token because it has already been received.");

        //Check if the smart contract of the child NFT had been stored
        uint256 childTokensLength = childTokens[_tokenId][_childContract].length;
        if (childTokensLength == 0) {
            childContractIndex[_tokenId][_childContract] = childContracts[_tokenId].length;
            childContracts[_tokenId].push(_childContract);
        }
        childTokens[_tokenId][_childContract].push(_childTokenId);
        childTokenIndex[_tokenId][_childContract][_childTokenId] = childTokensLength + 1;
        childTokenOwner[_childContract][_childTokenId] = _tokenId;
        emit AttachedChild(_from, _tokenId, _childContract, _childTokenId);
    }

     function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes memory _data) virtual external returns (bytes4) {
         
        require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
        // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
        uint256 _parentTokenId = _extractReceivedTokenId();
        // assembly {tokenId := calldataload(132)}
        // if (_data.length < 32) {
        //     tokenId = tokenId >> 256 - _data.length * 8;
        // }


        require (_exists (_parentTokenId), "");
        attachChild(_from, _parentTokenId, msg.sender, _childTokenId);
        require(ERC721(msg.sender).ownerOf(_childTokenId) != address(0), "Child token not owned.");
        
        emit ReceivedToken(_childTokenId, msg.sender);
        
        // return ERC721_RECEIVED;
        return this.onERC721Received.selector;
    }

    function updateNFT (uint _tokenId, string calldata _newMetadata) external{
        require (_exists (_tokenId), "updateNFT: token does not exist");
        require (msg.sender == ownerOfToken (_tokenId));
        string memory prevMetadata = tokenURI (_tokenId);

        _setTokenURI (_tokenId, _newMetadata);

        emit NFTUpdated (_tokenId, 2, prevMetadata, _newMetadata);

    }


    

    // function mintParentWithChild () {}
    // function attachChildren (){}

    // function transferChild() {}

    // function removeChild () {}

    function _extractReceivedTokenId() internal pure returns (uint256) {
        // Extract out the embedded token ID from the sender
        uint256 _receiverTokenId;
        uint256 _index = msg.data.length - 32;
        assembly {_receiverTokenId := calldataload(_index)}
        return _receiverTokenId;
    }


    // TO-REVIEW
    function ownerOfToken(uint256 _tokenId) public view returns (address tokenOwner) {
        tokenOwner = tokenIdToOwner[_tokenId];
        require(tokenOwner != address(0));
        return tokenOwner;
    }
    // function approve(address _approved, uint256 _tokenId) external {
    //     address rootOwner = address(rootOwnerOf(_tokenId));
    //     require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender]);
    //     rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
    //     emit Approval(rootOwner, _approved, _tokenId);
    // }

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