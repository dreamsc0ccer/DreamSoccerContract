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

interface IMonsterFootball {

    function getMonsterInformation(uint256 nftID) external view returns (uint256 difficult, uint256 startTime, uint256 endTime);

    function caculatorReward(uint256 nftID, uint256 monsterID) external view returns (uint256 reward);

}

interface IPices {

    function Shoes() external view returns (address);

    function getNFTPicesInformation(uint256 picesID) external view returns (uint256);

    function rewardPices(address user) external;

    function combineShoesPices(uint256[] memory picesID, address user) external;
    
}

contract Operator is Context, Ownable {

    using SafeMath for uint256;

    address private _tokenReward;

    mapping (address => uint256) private rewardTraining;

    mapping (address => uint256) private rewardMonster;

    mapping (address => uint256) private claimTime;

    mapping (address => bool) private isClaimed;

    IFootballer _footballer;

    IMonsterFootball _monster;

    function setNewTokenRewardAddress(address tokenReward) external onlyOwner() {

        _tokenReward = tokenReward;

        _footballer.setNewTokenRewardAddress(tokenReward);

    }

    function setFootballerAddress(address footballer) external onlyOwner() {

        _footballer = IFootballer(footballer);
        
    }

    function setMonsterAddress(address monster) external onlyOwner() {

        _monster = IMonsterFootball(monster);
        
    }


    function Footballer() external view returns (address) {
        return address(_footballer);
    }


    function Monster() external view returns (address) {
        return address(_monster);
    }


    function Token() external view returns (address) {
        return _tokenReward;
    }

    function mint(uint256 attribute) external {

        _footballer.mint(attribute, msg.sender);

    }

    function TrainingNFT(uint256 nftID, uint256 difficult) external {

        _footballer.Training(nftID, msg.sender);
        
        uint256 reward = _footballer.caculatorReward(nftID, difficult, msg.sender);

        rewardTraining[msg.sender] += reward; 

        if (!isClaimed[msg.sender]) {

            claimTime[msg.sender] = block.timestamp;

            isClaimed[msg.sender] == true;

        }
        

    }

    function getTotalReward(address user) external view returns (uint256) {
        return rewardTraining[user];
    }

    function claim() external {

        uint256 amount;

        if (claimTime[msg.sender] + 7 days < block.timestamp) {

            amount = rewardTraining[msg.sender];   
            

        } else if (claimTime[msg.sender] + 6 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(95).div(100);  

        } else if (claimTime[msg.sender] + 5 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(90).div(100);
            
        } else if (claimTime[msg.sender] + 4 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(85).div(100);  
            
        } else if (claimTime[msg.sender] + 3 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(80).div(100);  
            
        } else if (claimTime[msg.sender] + 2 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(75).div(100);  
            
        } else if (claimTime[msg.sender] + 1 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(70).div(100);  
            
        }
 
        ERC20(_tokenReward).transfer(msg.sender, amount);

        isClaimed[msg.sender] = false;

        rewardTraining[msg.sender] = 0;
    }

    function getRewardMonster(address user) external view returns (uint256) {
        return rewardMonster[user];
    }

    function fightMonster(uint256 nftID, uint256 monsterID) external {

        (  , , uint256 endTime) = _monster.getMonsterInformation(monsterID);

        require(endTime > block.timestamp, "End Time");
        
        _footballer.Training(nftID, msg.sender);

        uint256 reward = _monster.caculatorReward(nftID, monsterID);

        rewardMonster[msg.sender] += reward;

    }
    
    function claimMosterReward() external {

        require(rewardMonster[msg.sender] > 0, "You do not have any token to claim" );

        ERC20(_tokenReward).transfer(msg.sender, rewardMonster[msg.sender]);

        rewardMonster[msg.sender] = 0;

    }

}
