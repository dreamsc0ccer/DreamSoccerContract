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

    function getShoesInformation(uint256 shoesID) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;


}

contract StakingDSoccer is Context, Ownable {
    using SafeMath for uint256;
    
    struct UserInfo {
        uint256 _amountDeposite;
        uint256 _timeDeposite;
    }

    mapping(address => UserInfo) private _userInfoMap;

    address private _tokenReward;
    uint256 private _totalToBeMintAmount;
    uint256 private _APR = 365 * 24 * 60 * 20 * 100;

    event AddTotalToBeMintAmount(address indexed user, uint256 pendingTotalToBeMintAmount, uint256 totalToBeMintAmount);

    function addTotalToBeMintAmount(uint256 pendingTotalToBeMintAmount) external onlyOwner {
        require(pendingTotalToBeMintAmount != 0);
        ERC20(_tokenReward).transferFrom (msg.sender, address(this), pendingTotalToBeMintAmount);
        _totalToBeMintAmount = _totalToBeMintAmount.add(pendingTotalToBeMintAmount);
        emit AddTotalToBeMintAmount(msg.sender, pendingTotalToBeMintAmount, _totalToBeMintAmount);
    }

    function setAPR(uint256 APR) external onlyOwner {
        _APR = APR;
    }

    function setTokenReward(address tokenReward) external onlyOwner {
        _tokenReward = tokenReward;
    }

    function getReward(address user) public view returns (uint256) {

        uint256 depositedTime = block.timestamp - _userInfoMap[msg.sender]._timeDeposite;

        return _userInfoMap[user]._amountDeposite.mul(depositedTime).div(365 days).mul(_APR).div(100);

    }

    function getTotalToBeMintAmount() public view returns (uint256) {

        return _totalToBeMintAmount;

    }

    function getAPR() public view returns (uint256) {

        return _APR;

    }

    function getTotalReward(uint256 startBlock, uint256 endBlock, uint256 amountStake) public view returns (uint256 totalReward) {

        uint256 timeStake = endBlock - startBlock;

        return amountStake.mul(timeStake).div(365 days).mul(_APR).div(100);

    }

    function getUserInfo(address user) public view returns (uint256 amountDeposite, uint256 timeDeposite) {

        return (_userInfoMap[user]._amountDeposite,_userInfoMap[user]._timeDeposite);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Can not stake 0 token");

        require(ERC20(_tokenReward).balanceOf(msg.sender) >= amount, "You do not have enough tokens to stake");


        if (_userInfoMap[msg.sender]._amountDeposite != 0) {

            if (getReward(msg.sender) != 0) {

                if (_totalToBeMintAmount < getReward(msg.sender)){

                    ERC20(_tokenReward).transfer(msg.sender, _totalToBeMintAmount);
                    
                } else {

                    ERC20(_tokenReward).transfer(msg.sender, getReward(msg.sender));

                    _totalToBeMintAmount = _totalToBeMintAmount - getReward(msg.sender);

                }
            }

        }

        ERC20(_tokenReward).transferFrom(msg.sender, address(this), amount);

        _userInfoMap[msg.sender]._amountDeposite = _userInfoMap[msg.sender]._amountDeposite.add(amount);

        _userInfoMap[msg.sender]._timeDeposite = block.timestamp;


    }

    function unstake(uint256 amount) external {

        require(amount > 0, "Can not unstake 0 token");

        require(_userInfoMap[msg.sender]._amountDeposite >= amount, "You do not have enough tokens to unstake");

        if (_userInfoMap[msg.sender]._amountDeposite != 0) {

            if (getReward(msg.sender) != 0) {
                if (_totalToBeMintAmount < getReward(msg.sender)){

                    ERC20(_tokenReward).transfer(msg.sender, _totalToBeMintAmount);

                    _totalToBeMintAmount = 0;

                } else {

                    ERC20(_tokenReward).transfer(msg.sender, getReward(msg.sender));

                    _totalToBeMintAmount = _totalToBeMintAmount - getReward(msg.sender);

                }

                
            }

        }
        ERC20(_tokenReward).transfer(msg.sender, amount);

        _userInfoMap[msg.sender]._amountDeposite = _userInfoMap[msg.sender]._amountDeposite.sub(amount);

        _userInfoMap[msg.sender]._timeDeposite = block.timestamp;
    }


}

contract NFTStaking is Context, Ownable {
    
    using SafeMath for uint256;
    
    struct NFTInfo {
        uint256 commonAmount;
        uint256 rareAmount;
        uint256 legendaryAmount;
        uint256 timeDeposite;
    }

    IShoes shoes = IShoes(0xf3e07d4d31151C92198374d412893d1d40A1Df99);

    mapping(address => NFTInfo) private userInfoMap;

    address private _tokenReward;
    uint256 private _totalToBeMintAmount;

    uint256 private _commonShoes = 2;
    uint256 private _rareShoes = 3;
    uint256 private _legendaryShoes = 5;

    uint256 private _totalCommon;
    uint256 private _totalRare;
    uint256 private _totalLegendary;

    uint256 private _APR = 365 * 24 * 60 * 20 * 100;

    event AddTotalToBeMintAmount(address indexed user, uint256 pendingTotalToBeMintAmount, uint256 totalToBeMintAmount);

    function addTotalToBeMintAmount(uint256 pendingTotalToBeMintAmount) external onlyOwner {
        require(pendingTotalToBeMintAmount != 0);
        ERC20(_tokenReward).transferFrom (msg.sender, address(this), pendingTotalToBeMintAmount);
        _totalToBeMintAmount = _totalToBeMintAmount.add(pendingTotalToBeMintAmount);
        emit AddTotalToBeMintAmount(msg.sender, pendingTotalToBeMintAmount, _totalToBeMintAmount);
    }

    function getRewardPerShoes(uint256 nftID, address user) public view returns (uint256 reward) {

        uint256 depositedTime = block.timestamp - userInfoMap[user].timeDeposite;

        uint256 Attribute = shoes.getShoesInformation(nftID);

        if (Attribute == 0) {

            reward = _totalToBeMintAmount.mul(_commonShoes).mul(depositedTime).div(365 days).mul(_APR).div(100).div(_totalCommon);

        } else if (Attribute == 1) {

            reward = _totalToBeMintAmount.mul(_rareShoes).mul(depositedTime).div(365 days).mul(_APR).div(100).div(_totalRare);

        } else {

            reward = _totalToBeMintAmount.mul(_legendaryShoes).mul(depositedTime).div(365 days).mul(_APR).div(100).div(_totalLegendary);

        }

    }

    function getReward(address user) public view returns (uint256 reward) {

        uint256 commonAmount = userInfoMap[user].commonAmount;
        uint256 rareAmount = userInfoMap[user].rareAmount;
        uint256 legendaryAmount = userInfoMap[user].legendaryAmount;

        reward = getRewardPerShoes(0, user).mul(commonAmount) + getRewardPerShoes(1, user).mul(rareAmount) + getRewardPerShoes(2, user).mul(legendaryAmount);

    }

    function setAPR(uint256 APR) external onlyOwner {
        _APR = APR;
    }

    function getAPR() public view returns (uint256) {

        return _APR;

    }

    function stake(uint256 nftID) external {

        require(shoes.ownerOf(nftID) == msg.sender, "User have to owner of this NFT"); 

        if ((userInfoMap[msg.sender].commonAmount != 0) || (userInfoMap[msg.sender].rareAmount != 0) || (userInfoMap[msg.sender].legendaryAmount != 0)) {

            if (getReward(msg.sender) != 0) {

                if (_totalToBeMintAmount < getReward(msg.sender)){

                    ERC20(_tokenReward).transfer(msg.sender, _totalToBeMintAmount);
                    
                } else {

                    ERC20(_tokenReward).transfer(msg.sender, getReward(msg.sender));

                    _totalToBeMintAmount = _totalToBeMintAmount - getReward(msg.sender);

                }
            }

        }

        shoes.transferFrom(msg.sender, address(this), nftID);

        uint256 Attribute = shoes.getShoesInformation(nftID);

        if (Attribute == 0) {

            userInfoMap[msg.sender].commonAmount += 1;

        } else if (Attribute == 1) {

            userInfoMap[msg.sender].rareAmount += 1;

        } else {

            userInfoMap[msg.sender].legendaryAmount += 1;

        }

        userInfoMap[msg.sender].timeDeposite = block.timestamp;


    }

    function unstake(uint256 nftID) external {

        require(shoes.ownerOf(nftID) == msg.sender, "User have to owner of this NFT"); 

            if (getReward(msg.sender) != 0) {

                if (_totalToBeMintAmount < getReward(msg.sender)){

                    ERC20(_tokenReward).transfer(msg.sender, _totalToBeMintAmount);

                    _totalToBeMintAmount = 0;

                } else {

                    ERC20(_tokenReward).transfer(msg.sender, getReward(msg.sender));

                    _totalToBeMintAmount = _totalToBeMintAmount - getReward(msg.sender);

                }

                
            }

        
        shoes.transferFrom(address(this), msg.sender, nftID);

        uint256 Attribute = shoes.getShoesInformation(nftID);

        if (Attribute == 0) {

            userInfoMap[msg.sender].commonAmount -= 1;

        } else if (Attribute == 1) {

            userInfoMap[msg.sender].rareAmount -= 1;

        } else {

            userInfoMap[msg.sender].legendaryAmount -= 1;

        }

        userInfoMap[msg.sender].timeDeposite = block.timestamp;

    }



}

contract Operator is Context, Ownable {

    using SafeMath for uint256;

    StakingDSoccer sDSoccer;

    address private _tokenReward;

    StakingDSoccer private _stakingDSoccer = new StakingDSoccer();

    NFTStaking private _stakingNFT = new NFTStaking();

    address private _stakingShoes;

    mapping (address => uint256) private rewardTraining;

    mapping (address => uint256) private rewardMonster;

    mapping (address => uint256) private claimTime;

    mapping (address => bool) private isClaimed;

    IFootballer _footballer;

    IMonsterFootball _monster;

    IShoes _shoes;

    IPices _pices;

    uint256 private _commonPrice = 2000000 * 10 ** 9;
    uint256 private _rarePrice = 3000000 * 10 ** 9;
    uint256 private _legendaryPrice = 4500000 * 10 ** 9; 

    uint256 private _price;

    uint256 private _priceCombine = 4500000 * 10**9;
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


    function Staking() external view returns (address) {
        return address(_stakingDSoccer);
    }

    function StakingNFT() external view returns (address) {

        return address(_stakingNFT);

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

        if (claimTime[msg.sender] + 6 days < block.timestamp) {

            amount = rewardTraining[msg.sender];   
            

        } else if (claimTime[msg.sender] + 5 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(95).div(100);  

        } else if (claimTime[msg.sender] + 4 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(90).div(100);
            
        } else if (claimTime[msg.sender] + 3 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(85).div(100);  
            
        } else if (claimTime[msg.sender] + 2 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(80).div(100);  
            
        } else if (claimTime[msg.sender] + 1 days < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(75).div(100);  
            
        } else if (claimTime[msg.sender] < block.timestamp) {

            amount = rewardTraining[msg.sender].mul(70).div(100);  
            
        }
        
        amount > ERC20(_tokenReward).balanceOf(address(this)) ? ERC20(_tokenReward).transfer(msg.sender, ERC20(_tokenReward).balanceOf(address(this)) ) : ERC20(_tokenReward).transfer(msg.sender, amount);

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

        uint256 amount = rewardMonster[msg.sender];

        require(amount > 0, "You do not have any token to claim" );

        amount > ERC20(_tokenReward).balanceOf(address(this)) ? ERC20(_tokenReward).transfer(msg.sender, ERC20(_tokenReward).balanceOf(address(this)) ) : ERC20(_tokenReward).transfer(msg.sender, amount);

        rewardMonster[msg.sender] = 0;

    }

    function combine(uint256[] memory picesID) external {

        _footballer.transferFrom(msg.sender, _TreasuryAddress, _priceCombine);

        _pices.combineShoesPices(picesID, msg.sender);
    }

    function manualsend() public onlyOwner()  {

        uint256 contractETHBalance = address(this).balance;
        _TreasuryAddress.transfer(contractETHBalance);
    }

    receive() external payable {}

}

