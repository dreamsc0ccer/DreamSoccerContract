// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



interface IPieces {

}

contract ShoesNFT is ERC721, Ownable {

    using SafeMath for uint256;

    using Counters for Counters.Counter;

    struct Shoes {
        uint256 attribute;
    }

    Shoes[] public ShoesCollection;

    Counters.Counter private currentTokenId;
    
    string public baseTokenURI;

    IPieces _pieces;

    constructor() ERC721("Shoes", "NFT") {

        baseTokenURI = "";

    }


    modifier onlyPices() {

        require(owner() == _msgSender() || address(_pieces) == _msgSender(), "Caller is not the Piece");	

        _;	
    }


    function setPices(address pices) external onlyPices {

        _pieces = IPieces(pices);
    }


    function Pices() external view returns (address) {

        return address(_pieces);
        
    }


    function getShoesInformation(uint256 shoesID) external view returns (uint256) {

        return ShoesCollection[shoesID].attribute;
        
    }

  function mint(address user, uint256 attr) external onlyPices() {

        uint256 newItemId = ShoesCollection.length;

        uint256 attribute = attr;

        ShoesCollection.push(Shoes(attribute));

        _safeMint(user, newItemId);
        
  }



}
