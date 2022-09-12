// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


interface IFootballer {

    function caculatorReward(uint256 nftID, uint256 difficult, address user) external view returns (uint256 reward);

    function getNFTInformation(uint256 nftID) external view returns (uint256 Attribute, uint256 Energy, uint256 lastestUpdate);

    function Training(uint256 nftID, address user) external;

    function setNewTokenRewardAddress(address tokenReward) external;

    function mint(uint256 attribute, address user) external;
}


contract MonsterFootball is ERC721, Ownable {

    using SafeMath for uint256;

    using Counters for Counters.Counter;

    struct Monster {
        uint256 difficult;
        uint256 startTime;
        uint256 endTime;
    }

    IFootballer _footballer;

    Monster[] public Monsters;

    Counters.Counter private currentTokenId;
    
    string public baseTokenURI;

    address _operator;

    constructor() ERC721("Monster", "NFT") {

        baseTokenURI = "";

    }

    modifier onlyOperator() {

        require(owner() == _msgSender() || _operator == _msgSender(), "Caller is not the Operator");	

        _;	
    }


    function setFootballerAddress(address footballer) external onlyOperator {

         require(footballer != address(0), "Footballer address is not NULL address");


        _footballer = IFootballer(footballer);
        
    }

    function setOperator(address operator) external onlyOperator {

        require(operator != address(0), "Operator address is not NULL address");

        _operator = operator;
    }

    function footballerAddress() external view returns (address footballer) {
        footballer = address(_footballer);
    }

    function operatorAddress() external view returns (address operator) {
        operator = _operator;
    }


    function callMonster() external onlyOperator {

        uint256 newItemId = Monsters.length;
        uint256 difficult = uint(keccak256(abi.encodePacked(block.number))).mod(3);
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 5 minutes;
        Monsters.push(Monster(difficult, startTime, endTime));
        _safeMint(0x000000000000000000000000000000000000dEaD, newItemId);

    }
    
    function getMonsterInformation(uint256 nftID) external view returns (uint256 difficult, uint256 startTime, uint256 endTime) {

          difficult = Monsters[nftID].difficult;

          startTime = Monsters[nftID].startTime;
          
          endTime = Monsters[nftID].endTime;
          
    }
    function caculatorReward(uint256 nftID, uint256 monsterID) external view returns (uint256 reward) {

        (uint256 Attribute, , ) = _footballer.getNFTInformation(nftID);

        uint256 difficult = Monsters[monsterID].difficult;

        difficult > 3 ? difficult = 2 : difficult = difficult;

        uint256 bonus = ( 1 + difficult) * uint(keccak256(abi.encodePacked(block.number))).mod(3) * 10 ** 8;

        if (Attribute == 0) {

            reward = 200 * 2 * bonus;

        } else if (Attribute == 1) {

            reward = 1000 * 2 * bonus;

        } else {

            reward = 1500 * 2 * bonus;
        }
        

        
    }

}
