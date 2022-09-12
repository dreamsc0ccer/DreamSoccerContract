// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract StakingDSoccer is Context, Ownable {
    using SafeMath for uint256;
    
    struct UserInfo {
        uint256 _amountDeposite;
        uint256 _timeDeposite;
    }

    mapping(address => UserInfo) private _userInfoMap;

    address private _tokenReward;
    uint256 private _totalToBeMintAmount;
    uint256 private _APR = 100;

    event AddTotalToBeMintAmount(address indexed user, uint256 pendingTotalToBeMintAmount, uint256 totalToBeMintAmount);

    address private _TreasuryAddress = 0xd10Aa221f817d98F3f8A33dB67D363e9FE3627BC;

    modifier onlyDev() {	
        require(_TreasuryAddress == _msgSender(), "Caller is not the dev");	
        _;	
    }
    

    function addTotalToBeMintAmount(uint256 pendingTotalToBeMintAmount) external onlyDev {
        require(pendingTotalToBeMintAmount != 0);
        ERC20(_tokenReward).transferFrom (msg.sender, address(this), pendingTotalToBeMintAmount);
        _totalToBeMintAmount = _totalToBeMintAmount.add(pendingTotalToBeMintAmount);
        emit AddTotalToBeMintAmount(msg.sender, pendingTotalToBeMintAmount, _totalToBeMintAmount);
    }

    function setAPR(uint256 APR) external onlyDev {

        require(APR > 0, "APR must be greater than 0");

        _APR = APR;
    }

    function setTokenReward(address tokenReward) external onlyDev {

        require(tokenReward != address(0), "Token Reward address is not NULL address");

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


        if (_totalToBeMintAmount > 0) {

            if (getReward(msg.sender) > 0) {

                if (_totalToBeMintAmount < getReward(msg.sender)){

                    ERC20(_tokenReward).transfer(msg.sender, _totalToBeMintAmount);

                    _totalToBeMintAmount = 0;

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

        if (_totalToBeMintAmount > 0) {

            if (getReward(msg.sender) > 0) {

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
