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

    function Training(uint256 nftID, address user, uint256 multiplier) external;

    function setNewTokenRewardAddress(address tokenReward) external;

    function mint(uint256 attribute, address user) external;

    function transferFrom(address from, address to, uint value) external returns (bool);

    function buyEnery(uint nftID) external;
}

interface IMonsterFootball {

    function getMonsterInformation(uint256 nftID) external view returns (uint256 difficult, uint256 startTime, uint256 endTime);

    function caculatorReward(uint256 nftID, uint256 monsterID) external view returns (uint256 reward);

    function callMonster() external;

}

interface IPices {

    function Shoes() external view returns (address);

    function getNFTPicesInformation(uint256 picesID) external view returns (uint256);

    function rewardPices(address user) external;

    function combineShoesPices(uint256[] memory picesID, address user) external;

}

interface IShoes {
    function mint(address user, uint256 attr) external;
    function Pices() external view returns (address);

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

    IShoes _shoes;

    IPices _pices;

    uint256 private _commonPrice = 2000 * 10 ** 9;
    uint256 private _rarePrice = 3000 * 10 ** 9;
    uint256 private _legendaryPrice = 4500 * 10 ** 9; 

    uint256 private _price;

    uint256 private _priceCombine = 4500 * 10**9;
    uint256 private _enegryPrice;

    address payable private _TreasuryAddress = payable(0xd10Aa221f817d98F3f8A33dB67D363e9FE3627BC);

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

    function setShoesAddress(address shoes) external onlyOwner() {

        _shoes = IShoes(shoes);
        
    }

    function setPicesAddress(address pices) external onlyOwner() {

        _pices = IPices(pices);
        
    }

    function getPrice() external view returns (uint256 commonPrice, uint256 rarePrice, uint256 legendaryPrice) {

        return (_commonPrice, _rarePrice, _legendaryPrice);

    }

    function Footballer() external view returns (address) {
        return address(_footballer);
    }


    function Monster() external view returns (address) {
        return address(_monster);
    }

    function Shoes() external view returns (address) {
        return address(_shoes);
    }


    function Pices() external view returns (address) {
        return address(_pices);
    }


    function Token() external view returns (address) {
        return _tokenReward;
    }

    function mint(uint256 attribute) external {

        priceMint(attribute);
        _footballer.mint(attribute, msg.sender);

    }

    function TrainingNFT(uint256 nftID, uint256 difficult, uint256 multiplier) external returns (uint256 reward) {

        require(multiplier > 0, "Error");

        _footballer.Training(nftID, msg.sender, multiplier);
        
        reward = _footballer.caculatorReward(nftID, difficult, msg.sender) * multiplier;

        rewardTraining[msg.sender] += reward; 

        if (!isClaimed[msg.sender]) {

            claimTime[msg.sender] = block.timestamp;

            isClaimed[msg.sender] == true;

        }
        

    }

    function getTotalReward(address user) external view returns (uint256) {
        return rewardTraining[user];
    }

    function priceMint(uint256 attribute) private {

        require(attribute < 3, "Error");
        
        if (attribute == 0) {

            _price =  _commonPrice;

        } else if (attribute == 1) {

            _price = _rarePrice;

        } else {

            _price = _legendaryPrice;

        }

        require(ERC20(_tokenReward).balanceOf(msg.sender) >= _price, "You are not enough tokens to buy"); 

        ERC20(_tokenReward).transferFrom(msg.sender, _TreasuryAddress , _price);    
         

    }

    function buyEnery(uint256 nftID) external {

        require(ERC20(_tokenReward).balanceOf(msg.sender) >= _price, "You are not enough tokens"); 

        (uint256 Attribute  , , ) = _footballer.getNFTInformation(nftID);

        if (Attribute == 0) {

            _price = _commonPrice.div(2);

        } else if (Attribute ==1) {

            _price = _rarePrice.div(2);

        } else {

            _price = _legendaryPrice.div(2);
            
        }

        ERC20(_tokenReward).transferFrom(msg.sender, _TreasuryAddress , _price);   

        _footballer.buyEnery(nftID);
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

    function callMonster() external onlyOwner {
        _monster.callMonster();
    }
    
    function fightMonster(uint256 nftID, uint256 monsterID, uint256 multiplier) external returns (uint256 reward) {

        require(multiplier > 0, "Error");

        (  , , uint256 endTime) = _monster.getMonsterInformation(monsterID);

        require(endTime > block.timestamp, "End Time");
        
        _footballer.Training(nftID, msg.sender, multiplier);

        reward = _monster.caculatorReward(nftID, monsterID) * multiplier;

        _pices.rewardPices(msg.sender);

        rewardMonster[msg.sender] += reward;


    }
    
    function claimMosterReward() external {

        require(rewardMonster[msg.sender] > 0, "You do not have any token to claim" );

        ERC20(_tokenReward).transfer(msg.sender, rewardMonster[msg.sender]);

        rewardMonster[msg.sender] = 0;

    }

    function combine(uint256[] memory picesID) external {

        _footballer.transferFrom(msg.sender, _TreasuryAddress, _priceCombine);

        _pices.combineShoesPices(picesID, msg.sender);
    }

}
