// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Footballer is ERC721, Ownable {

    using SafeMath for uint256;

    address _operator = 0x9d9EA6FFf3915f08B7269984C6b6B0916A33eD29;

    struct Character {
        uint256 attribute;
        uint256 currentEnergy;
        uint256 lastestUpdate;
        address owner;
    }

    string public baseTokenURI;

    address private _tokenReward;

    constructor() ERC721("Footballer", "NFT") {
        baseTokenURI = "";

    }
    
    modifier onlyOperator() {

        require(owner() == _msgSender() || _operator == _msgSender(), "Caller is not the Operator");	

        _;	
    }
    Character[] private characters;

    function setNewTokenRewardAddress(address tokenReward) external onlyOperator() {

        _tokenReward = tokenReward;
    }

    function Token() external view returns (address) {
        return _tokenReward;
    }

    function operatorAddress() external view returns (address operator) {
        operator = _operator;
    }

    function setOperator(address operator) external onlyOperator {
        _operator = operator;
    }

    function appendString(string memory a,string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a,' ',b));
    } 

    function getAllFootballerbyOwner(address user) external view returns (string memory nftID) {

        for (uint256 i = 0; i < characters.length; i ++ ) {
            if (characters[i].owner == user) {
                string memory iString = Strings.toString(i);
                nftID = appendString(nftID, iString);
            }

        }

    }

    function getNFTInformation(uint256 nftID) external view returns (uint256 Attribute, uint256 Energy, uint256 lastestUpdate) {

        Attribute = characters[nftID].attribute;
          
        if (characters[nftID].lastestUpdate + 1 minutes > block.timestamp) { // 0 Energy

            Energy = characters[nftID].currentEnergy;

          } else if ((characters[nftID].lastestUpdate + 1 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 2 minutes > block.timestamp)) { // 1 Energy

                characters[nftID].currentEnergy < 3 ? Energy = characters[nftID].currentEnergy + 1 : Energy = characters[nftID].currentEnergy;

          } else if ((characters[nftID].lastestUpdate + 2 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 3 minutes > block.timestamp)) { // 2 Energy

                characters[nftID].currentEnergy > 0 ? Energy = 3 : Energy = 2;

          } else if (characters[nftID].lastestUpdate + 3 minutes < block.timestamp) { // 3 Energy

                Energy = 3;

          }

        if (Energy == 2) {

            if (characters[nftID].lastestUpdate + 1 minutes > block.timestamp) {

                lastestUpdate = 1 minutes + characters[nftID].lastestUpdate - block.timestamp;

            } else if ((characters[nftID].lastestUpdate + 1 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 2 minutes > block.timestamp)) {

                lastestUpdate = 2 minutes + characters[nftID].lastestUpdate - block.timestamp;

            } else {
                lastestUpdate = 3 minutes + characters[nftID].lastestUpdate - block.timestamp;
            }

            
        } else if (Energy == 1) {

            if ((characters[nftID].lastestUpdate + 1 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 2 minutes > block.timestamp)) {

                lastestUpdate = 3 minutes + characters[nftID].lastestUpdate - block.timestamp;

            } else {

                lastestUpdate = 2 minutes + characters[nftID].lastestUpdate - block.timestamp;
                
            }

                        

        } else if  (Energy == 0) {

            lastestUpdate = 3 minutes + characters[nftID].lastestUpdate  - block.timestamp;

        } else {
            
            lastestUpdate = 0;
        }


          
    }

    function getNFTInformation1(uint256 nftID) external view returns (uint256 Attribute, uint256 Energy, uint256 lastestUpdate) {

        Attribute = characters[nftID].attribute;
          
        if (characters[nftID].lastestUpdate + 1 minutes > block.timestamp) { // 0 Energy

            Energy = characters[nftID].currentEnergy;

          } else if ((characters[nftID].lastestUpdate + 1 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 2 minutes > block.timestamp)) { // 1 Energy

                characters[nftID].currentEnergy < 3 ? Energy = characters[nftID].currentEnergy + 1 : Energy = characters[nftID].currentEnergy;

          } else if ((characters[nftID].lastestUpdate + 2 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 3 minutes > block.timestamp)) { // 2 Energy

                characters[nftID].currentEnergy > 0 ? Energy = 3 : Energy = 2;

          } else if (characters[nftID].lastestUpdate + 3 minutes < block.timestamp) { // 3 Energy

                Energy = 3;

          }

        lastestUpdate = characters[nftID].lastestUpdate;
          
    }

    function getNFTInformation2(uint256 nftID) external view returns (uint256 Attribute, uint256 Energy, uint256 lastestUpdate) {

        Attribute = characters[nftID].attribute;

        Energy = characters[nftID].currentEnergy;

        lastestUpdate = characters[nftID].lastestUpdate;
          
    }

    function _mint(uint256 attribute, address user) private {

        uint256 newItemId = characters.length;
        uint256 currentEnergy = 3;
        uint256 lastestUpdate = block.timestamp;

        characters.push(Character(attribute, currentEnergy, lastestUpdate, user));

        _safeMint(user, newItemId);

    }

    function buyEnery(uint nftID) external onlyOperator {

        characters[nftID].currentEnergy = 3;
        characters[nftID].lastestUpdate = 0;

    }

    function mint(uint256 attribute, address user) external onlyOperator {

        _mint(attribute, user);
    }
    
    function Training(uint256 nftID, address user, uint256 multiplier) external onlyOperator {

      require(ownerOf(nftID) == user, "User have to owner of this NFT");      

      if (characters[nftID].lastestUpdate + 1 minutes > block.timestamp) { // 0 Energy

           update0Energy(nftID, multiplier);

        }  
    
      if ((characters[nftID].lastestUpdate + 1 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 2 minutes > block.timestamp)) { // 1 Energy

          update1Energy(nftID, multiplier);

        }  
        
      if ((characters[nftID].lastestUpdate + 2 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 3 minutes > block.timestamp)) { // 2 Energy

          update2Energy(nftID, multiplier);

        }
      if (characters[nftID].lastestUpdate + 3 minutes < block.timestamp) { // 3 Energy

            characters[nftID].currentEnergy = 3 - multiplier;

        }

        recoveryEnergy(nftID);


    }

    // function getEnergy(uint256 nftID) private view returns (uint256 Energy) {  

    //     if (characters[nftID].lastestUpdate + 1 minutes > block.timestamp) { // 0 Energy

    //         Energy = characters[nftID].currentEnergy;

    //       } else if ((characters[nftID].lastestUpdate + 1 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 2 minutes > block.timestamp)) { // 1 Energy

    //             characters[nftID].currentEnergy < 3 ? Energy = characters[nftID].currentEnergy + 1 : Energy = characters[nftID].currentEnergy;

    //       } else if ((characters[nftID].lastestUpdate + 2 minutes < block.timestamp) && (characters[nftID].lastestUpdate + 3 minutes > block.timestamp)) { // 2 Energy

    //             characters[nftID].currentEnergy > 0 ? Energy = 3 : Energy = 2;

    //       } else { // 3 Energy

    //             Energy = 3;

    //       }
    // }

    function caculatorDifcult(uint256 difficult, address user) public view returns (uint256 diff) {
        bytes memory source;

        source = abi.encodePacked(
            _operator,
            difficult,
            address(this),
            block.gaslimit,
            gasleft(),
            block.timestamp,
            block.number,
            msg.sig,
            blockhash(block.number),
            block.difficulty,
            user
        );  

        diff = (uint(keccak256(source))).mod(3) + 1;      
    }

    function caculatorReward(uint256 nftID, uint256 difficult, address user) external view returns (uint256 reward) {

        difficult > 3 ? difficult = 2 : difficult = difficult;

        uint256 bounus = ( 1 + difficult) * 10 ** 9 + caculatorDifcult(difficult, user) * 10 ** 8 ;

        if (characters[nftID].attribute == 0) {

            reward = 100 * bounus;

        } else if (characters[nftID].attribute == 1) {

            reward = 200 * bounus;

        } else {

            reward = 500 * bounus;
        }
        

        
    }

    function update0Energy(uint256 nftID, uint256 multiplier) private { // +0

        if (multiplier == 1) {
            
            require(characters[nftID].currentEnergy > 0, "Error");
            


            characters[nftID].currentEnergy = characters[nftID].currentEnergy - multiplier;

        } else if (multiplier == 2) {

            require(characters[nftID].currentEnergy > 1, "Error");

            characters[nftID].currentEnergy == 2 ? characters[nftID].currentEnergy = 0 : characters[nftID].currentEnergy = 1;

        } else {

            require(characters[nftID].currentEnergy > 2, "Error");

            characters[nftID].currentEnergy = 0;

        }
        

    }
    function update1Energy(uint256 nftID, uint256 multiplier) private { //+1

        if (multiplier == 1) {
            
            characters[nftID].currentEnergy == 3 ? characters[nftID].currentEnergy = 2 : characters[nftID].currentEnergy = characters[nftID].currentEnergy; 

        } else if (multiplier == 2) {

            characters[nftID].currentEnergy == 1 ? characters[nftID].currentEnergy = 0 : characters[nftID].currentEnergy = 1;

        } else {

            require(characters[nftID].currentEnergy > 1, "Error");

            characters[nftID].currentEnergy = 0;

        }

        

    }
  
    function update2Energy(uint256 nftID, uint256 multiplier) private { //+2

        if (multiplier == 1) {
            
            characters[nftID].currentEnergy == 0 ? characters[nftID].currentEnergy = 1 : characters[nftID].currentEnergy = 2;

        } else if (multiplier == 2) {

            characters[nftID].currentEnergy == 1;

        } else {

            require(characters[nftID].currentEnergy > 0, "Error");

            characters[nftID].currentEnergy = 0;

        }

        
        
    }


    function recoveryEnergy(uint256 nftID) private {

        if (characters[nftID].currentEnergy == 2) {

            characters[nftID].lastestUpdate = block.timestamp;

        }
    }
}
