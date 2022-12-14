// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

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

    function buyEnergy(uint nftID) external;
}

interface IMonsterFootball {

    function getMonsterInformation(uint256 nftID) external view returns (uint256 difficult, uint256 startTime, uint256 endTime);

    function caculatorReward(uint256 nftID, uint256 monsterID) external view returns (uint256 reward);

    function callMonster() external returns (uint256);

}

interface IPieces {

    function Shoes() external view returns (address);

    function getNFTPiecesInformation(uint256 piecesID) external view returns (uint256);

    function rewardPieces(address user) external returns (uint256);

    function combineShoesPieces(uint256[] memory piecesID, address user) external;

}

interface IShoes {

    function mint(address user, uint256 attr) external;

    function pieces() external view returns (address);

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

    address private _tokenReward = 0x3761493C189F9c5483302d823CFfE8108c21d668;
    uint256 private _totalToBeMintAmount;
    uint256 private _APR = 100;

    address _operator = 0xd10Aa221f817d98F3f8A33dB67D363e9FE3627BC;


    modifier onlyOperator() {

        require(owner() == _msgSender() || _operator == _msgSender(), "Caller is not the Operator");	

        _;	
    }

    event AddTotalToBeMintAmount(address indexed user, uint256 pendingTotalToBeMintAmount, uint256 totalToBeMintAmount);

    function addTotalToBeMintAmount(uint256 pendingTotalToBeMintAmount) external onlyOperator {
        require(pendingTotalToBeMintAmount != 0);
        ERC20(_tokenReward).transferFrom (msg.sender, address(this), pendingTotalToBeMintAmount);
        _totalToBeMintAmount = _totalToBeMintAmount.add(pendingTotalToBeMintAmount);
        emit AddTotalToBeMintAmount(msg.sender, pendingTotalToBeMintAmount, _totalToBeMintAmount);
    }

    function setAPR(uint256 APR) external onlyOperator {

        require(APR > 0, "APR must be greater than 0");

        _APR = APR;
    }

    function operatorAddress() external view returns (address operator) {
        
        operator = _operator;
    }

    function setOperator(address operator) external onlyOperator {

        require(operator != address(0), "Operator address is not NULL address");

        _operator = operator;
    }
    
    function updateNewStaking(address newStaking) external onlyOperator()  {

        require(newStaking != address(0), "Staking address is not NULL address");

        uint256 balanceToken = ERC20(_tokenReward).balanceOf(address(this));

        ERC20(_tokenReward).transfer(newStaking, balanceToken);

    }

    function setTokenReward(address tokenReward) external onlyOperator {

        require(tokenReward != address(0), "Token Reward address is not NULL address");
        _tokenReward = tokenReward;
    }

    function TokenReward() public view returns (address) {
        return _tokenReward;
    }

    function getReward(address user) public view returns (uint256) {

        uint256 depositedTime = block.timestamp - _userInfoMap[user]._timeDeposite;

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

    IShoes _shoes;

    mapping(address => NFTInfo) private userInfoMap;

    address private _tokenReward = 0x3761493C189F9c5483302d823CFfE8108c21d668;
    uint256 private _totalToBeMintAmount;

    uint256 private _commonShoes = 2;
    uint256 private _rareShoes = 3;
    uint256 private _legendaryShoes = 5;

    uint256 private _totalCommon;
    uint256 private _totalRare;
    uint256 private _totalLegendary;

    uint256 private _APR = 100;

    address _operator = 0xd10Aa221f817d98F3f8A33dB67D363e9FE3627BC;

    event AddTotalToBeMintAmount(address indexed user, uint256 pendingTotalToBeMintAmount, uint256 totalToBeMintAmount);

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

    function updateNewNFTStaking(address newNFTStaking) external onlyOperator()  {

        require(newNFTStaking != address(0), "NFTStaking address is not NULL address");

        uint256 balanceToken = ERC20(_tokenReward).balanceOf(address(this));

        ERC20(_tokenReward).transfer(newNFTStaking, balanceToken);

    }

    function addTotalToBeMintAmount(uint256 pendingTotalToBeMintAmount) external onlyOperator {
        require(pendingTotalToBeMintAmount != 0, "Total to be mint amount must be greater than 0");
        ERC20(_tokenReward).transferFrom (msg.sender, address(this), pendingTotalToBeMintAmount);
        _totalToBeMintAmount = _totalToBeMintAmount.add(pendingTotalToBeMintAmount);
        emit AddTotalToBeMintAmount(msg.sender, pendingTotalToBeMintAmount, _totalToBeMintAmount);
    }

    function setShoesAddress(address shoes) external onlyOperator() {

        require(shoes != address(0), "Shoes address is not NULL address");

        _shoes = IShoes(shoes);
        
    }

    function getRewardPerShoes(uint256 nftID, address user) public view returns (uint256 reward) {

        uint256 depositedTime = block.timestamp - userInfoMap[user].timeDeposite;

        uint256 Attribute = _shoes.getShoesInformation(nftID);

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

    function setAPR(uint256 APR) external onlyOperator {

        require(APR > 0, "APR must be greater than 0");

        _APR = APR;
    }

    function getAPR() public view returns (uint256) {

        return _APR;

    }


    function setTokenReward(address tokenReward) external onlyOperator {

        require(tokenReward != address(0), "Token Reward address is not NULL address");
        _tokenReward = tokenReward;
    }

    function TokenReward() public view returns (address) {
        return _tokenReward;
    }


    function stake(uint256 nftID) external {

        require(_shoes.ownerOf(nftID) == msg.sender, "User have to owner of this NFT"); 

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

        _shoes.transferFrom(msg.sender, address(this), nftID);

        uint256 Attribute = _shoes.getShoesInformation(nftID);

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

        require(_shoes.ownerOf(nftID) == msg.sender, "User have to owner of this NFT"); 

            if (getReward(msg.sender) != 0) {

                if (_totalToBeMintAmount < getReward(msg.sender)){

                    ERC20(_tokenReward).transfer(msg.sender, _totalToBeMintAmount);

                    _totalToBeMintAmount = 0;

                } else {

                    ERC20(_tokenReward).transfer(msg.sender, getReward(msg.sender));

                    _totalToBeMintAmount = _totalToBeMintAmount - getReward(msg.sender);

                }

                
            }

        
        _shoes.transferFrom(address(this), msg.sender, nftID);

        uint256 Attribute = _shoes.getShoesInformation(nftID);

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

    address private _tokenReward = 0x3761493C189F9c5483302d823CFfE8108c21d668;

    StakingDSoccer private _stakingDSoccer = new StakingDSoccer();

    NFTStaking private _stakingNFT = new NFTStaking();

    address private _stakingShoes;

    mapping (address => uint256) private rewardTraining;

    mapping (address => uint256) private rewardMonster;

    mapping (address => uint256) private claimTime;

    mapping (address => bool) private isClaimed;

    IFootballer _footballer = IFootballer(0x3167Fd7e0D836D275dd450D02De5dc978F5bde2C);

    IMonsterFootball _monster = IMonsterFootball(0xd87bfDBB43c51622A7FcEeF61de90fF37a83374a);

    IShoes _shoes = IShoes(0xC9391d3a72B16F87E21EbA0eD1087ae98fd1C55D);

    IPieces _pieces = IPieces(0xc261aaAae649EF1C3f350156ABC353F9b591b18d);

    uint256 private _commonPrice = 20000 * 10 ** 9;
    uint256 private _rarePrice = 50000 * 10 ** 9;
    uint256 private _legendaryPrice = 60000 * 10 ** 9; 

    uint256 private _price;

    uint256 private _priceCombine = 10000 * 10**9;

    uint256 private _energyPrice;

    bool private _isRecoveryEnergyOpen;

    address payable private _TreasuryAddress = payable(0xd10Aa221f817d98F3f8A33dB67D363e9FE3627BC);

    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    function setNewTokenRewardAddress(address tokenReward) external onlyOwner() {

        require(tokenReward != address(0), "Token Reward address is not NULL address");

        _tokenReward = tokenReward;

    }

    function setFootballerAddress(address footballer) external onlyOwner() {

        require(footballer != address(0), "Footballer address is not NULL address");

        _footballer = IFootballer(footballer);
        
    }

    function setMonsterAddress(address monster) external onlyOwner() {

        require(monster != address(0), "Monster address is not NULL address");

        _monster = IMonsterFootball(monster);
        
    }

    function setShoesAddress(address shoes) external onlyOwner() {

        require(shoes != address(0), "Shoes address is not NULL address");

        _shoes = IShoes(shoes);
        
    }

    function setStakingDSoccer(address stakingDSoccer) external onlyOwner() {

        require(stakingDSoccer != address(0), "Staking address is not NULL address");

        _stakingDSoccer = StakingDSoccer(stakingDSoccer);
        
    }

    function setNFTStaking(address stakingNFT) external onlyOwner() {

        require(stakingNFT != address(0), "NFT Staking address is not NULL address");

        _stakingNFT = NFTStaking(stakingNFT);
        
    }

    function setPiecesAddress(address pieces) external onlyOwner() {

        require(pieces != address(0), "Pieces address is not NULL address");

        _pieces = IPieces(pieces);
        
    }

    function setRecoveryEnergyStatus(bool status) external onlyOwner() {

        _isRecoveryEnergyOpen = status;

    }

    
    function getRecoveryEnergyStatus() external view returns (bool) {

        return _isRecoveryEnergyOpen;

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


    function Pieces() external view returns (address) {
        return address(_pieces);
    }


    function Token() external view returns (address) {
        return _tokenReward;
    }



    function mint(uint256 attribute) external {

        priceMint(attribute);

        _footballer.mint(attribute, msg.sender);

    }

    event RewardTrainingNFT(uint256 reward);

    function TrainingNFT(uint256 nftID, uint256 difficult, uint256 multiplier) external returns (uint256 reward) {

        require(multiplier > 0, "Multiplier must be greater than 0 ");

        _footballer.Training(nftID, msg.sender, multiplier);
        
        reward = _footballer.caculatorReward(nftID, difficult, msg.sender) * multiplier;

        rewardTraining[msg.sender] += reward; 

        if (!isClaimed[msg.sender]) {

            claimTime[msg.sender] = block.timestamp;

            isClaimed[msg.sender] == true;

        }
        
        emit RewardTrainingNFT(reward);

    }

    function getTotalReward(address user) external view returns (uint256) {

        return rewardTraining[user];
    }

    function priceMint(uint256 attribute) private {
        
        if (attribute == 0) {

            _price =  _commonPrice;

        } else if (attribute == 1) {

            _price = _rarePrice;

        } else {

            _price = _legendaryPrice;

        }

        require(ERC20(_tokenReward).balanceOf(msg.sender) >= _price, "You are not enough tokens to buy"); 

        ERC20(_tokenReward).transferFrom(msg.sender, DEAD , _price);    
         

    }

    function buyEnergy(uint256 nftID) external {

        require(_isRecoveryEnergyOpen, "This feature has not been opened yet"); 

        (uint256 Attribute  , , ) = _footballer.getNFTInformation(nftID);

        if (Attribute == 0) {

            _energyPrice = _commonPrice.div(5);

        } else if (Attribute ==1) {

            _energyPrice = _rarePrice.div(5);

        } else {

            _energyPrice = _legendaryPrice.div(5);
            
        }

        ERC20(_tokenReward).transferFrom(msg.sender, DEAD , _energyPrice);   

        _footballer.buyEnergy(nftID);
    }

    function claim() external {

        require(rewardTraining[msg.sender] > 0, "You do not have any token to claim");

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

    function callMonster() external onlyOwner returns (uint256 monsterID) {
        monsterID = _monster.callMonster();

        
    }
    
    event RewardFightMonster(uint256 reward, uint256 piecesID);

    function fightMonster(uint256 nftID, uint256 monsterID, uint256 multiplier) external returns (uint256 reward, uint256 piecesID) {

        require(multiplier > 0, "Multiplier must be greater than 0 ");

        (  , , uint256 endTime) = _monster.getMonsterInformation(monsterID);

        require(endTime > block.timestamp, "End Time");
        
        _footballer.Training(nftID, msg.sender, multiplier);

        reward = _monster.caculatorReward(nftID, monsterID) * multiplier;

        piecesID = _pieces.rewardPieces(msg.sender);

        rewardMonster[msg.sender] += reward;

        emit RewardFightMonster(reward, piecesID);

    }
    
    function claimMosterReward() external {

        uint256 amount = rewardMonster[msg.sender];

        require(amount > 0, "You do not have any token to claim" );

        amount > ERC20(_tokenReward).balanceOf(address(this)) ? ERC20(_tokenReward).transfer(msg.sender, ERC20(_tokenReward).balanceOf(address(this)) ) : ERC20(_tokenReward).transfer(msg.sender, amount);

        rewardMonster[msg.sender] = 0;

    }

    function updateNewOperator(address newOperator) external onlyOwner()  {

        require(newOperator != address(0), "Operator address is not NULL address");

        uint256 balanceToken = ERC20(_tokenReward).balanceOf(address(this));

        ERC20(_tokenReward).transfer(newOperator,balanceToken);

    }

    function combine(uint256[] memory piecesID) external {

        ERC20(_tokenReward).transferFrom(msg.sender, DEAD , _priceCombine);

        _pieces.combineShoesPieces(piecesID, msg.sender);
    }

    function manualsend() public onlyOwner()  {

        uint256 contractETHBalance = address(this).balance;

        _TreasuryAddress.transfer(contractETHBalance);
    }

    receive() external payable {}

}
