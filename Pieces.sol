// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IShoes {

    function mint(address user, uint256 attribute) external;

}

contract PiecesNFT is ERC721, Ownable {

    using SafeMath for uint256;

    using Counters for Counters.Counter;

    struct Pieces {

        uint256 attribute;
    }

    Pieces[] public PiecesCollection;

    Counters.Counter private currentTokenId;
    
    string public baseTokenURI;

    address _operator = 0x829E64a5Ff6F272cc00c8551dCE1A30654a3AFA4;

    IShoes _shoes = IShoes(0xA9ad5F2151eC2F55578eF7ab8982c78A2C842230);

    constructor() ERC721("PiecesNFT", "NFT") {

        baseTokenURI = "";

    }

    modifier onlyOperator() {

        require(owner() == _msgSender() || _operator == _msgSender(), "Caller is not the Operator");	

        _;	
    }

    function operatorAddress() external view returns (address operator) {
        operator = _operator;
    }

    function setOperator(address operator) external onlyOperator {

        require(operator != address(0), "Operator address is not NULL address");
        _operator = operator;
    }

    function setShoes(address shoes) external onlyOperator {

        require(shoes != address(0), "Shoes address is not NULL address");
        _shoes = IShoes(shoes);
    }


    function Shoes() external view returns (address) {

        return address(_shoes);
        
    }

    function getNFTPiecesInformation(uint256 piecesID) external view returns (uint256) {

        return PiecesCollection[piecesID].attribute;
        
    }

    function rewardPieces(address user) external onlyOperator() returns (uint256) {

        uint256 newItemId = PiecesCollection.length;

        uint256 attribute = uint(keccak256(abi.encodePacked(block.number, msg.sig))).mod(3);

        PiecesCollection.push(Pieces(attribute));

        _safeMint(user, newItemId);

        return  newItemId;
        

    }

    function combineCommonShoesPieces(uint256[] memory piecesID, address user) external onlyOperator() {

        require(piecesID.length == 9, "Not Enough");

        for (uint256 i = 0; i < piecesID.length; i++) {

            require(ownerOf(piecesID[i]) == user, "You do not have this piece" );

            require(PiecesCollection[i].attribute == PiecesCollection[i + 1].attribute, "Not same attribute");

            transferFrom(user, 0x000000000000000000000000000000000000dEaD, piecesID[i]);
        }

        _shoes.mint(user, PiecesCollection[0].attribute);

    }

    function combineRareShoesPieces(uint256[] memory piecesID, address user) external onlyOperator() {

        require(piecesID.length == 16, "Not Enough");

        for (uint256 i = 0; i < piecesID.length; i++) {

            require(ownerOf(piecesID[i]) == user, "You do not have this piece" );

            require(PiecesCollection[i].attribute == PiecesCollection[i + 1].attribute, "Not same attribute");

            transferFrom(user, 0x000000000000000000000000000000000000dEaD, piecesID[i]);
        }

        _shoes.mint(user, PiecesCollection[0].attribute);

    }

    function combineLegendaryShoesPieces(uint256[] memory piecesID, address user) external onlyOperator() {

        require(piecesID.length == 25 , "Not Enough");

        for (uint256 i = 0; i < piecesID.length; i++) {

            require(ownerOf(piecesID[i]) == user, "You do not have this piece" );

            require(PiecesCollection[i].attribute == PiecesCollection[i + 1].attribute, "Not same attribute");

            transferFrom(user, 0x000000000000000000000000000000000000dEaD, piecesID[i]);
        }

        _shoes.mint(user, PiecesCollection[0].attribute);

    }    

}
