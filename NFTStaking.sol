// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IShoes {

    function getShoesInformation(uint256 shoesID) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;

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

    uint256 private _APY = 365 * 24 * 60 * 20 * 100;

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

            reward = _totalToBeMintAmount.mul(_commonShoes).mul(depositedTime).div(365 days).mul(_APY).div(100).div(_totalCommon);

        } else if (Attribute == 1) {

            reward = _totalToBeMintAmount.mul(_rareShoes).mul(depositedTime).div(365 days).mul(_APY).div(100).div(_totalRare);

        } else {

            reward = _totalToBeMintAmount.mul(_legendaryShoes).mul(depositedTime).div(365 days).mul(_APY).div(100).div(_totalLegendary);

        }

    }

    function getReward(address user) public view returns (uint256 reward) {

        uint256 commonAmount = userInfoMap[user].commonAmount;
        uint256 rareAmount = userInfoMap[user].rareAmount;
        uint256 legendaryAmount = userInfoMap[user].legendaryAmount;

        reward = getRewardPerShoes(0, user).mul(commonAmount) + getRewardPerShoes(1, user).mul(rareAmount) + getRewardPerShoes(2, user).mul(legendaryAmount);

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
