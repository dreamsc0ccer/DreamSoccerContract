pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LotteryBall is Context, Ownable {
    using SafeMath for uint256;

    uint _lastTime;

    uint _openTime;
    uint _endTime;

    uint256 _price = 1 * 10**9;

    bool _isLotteryOpen;

    uint256 _numericalOrderLottery;

    uint[] private _Prize;
    uint private  _xFactor = 32;

    address _tokenReward;

    struct ticketNumber {
        uint[] numberInTicket;
    }

    struct ticket {
        uint numericalOrder; // How many LP tokens the user has provided.
        ticketNumber numberInTicket;
        uint purchaseDate;
        uint expiryDate;
    }

    mapping(address => ticket[]) private _userInfoMap;

    ticket _templateTicket;
           
    // mapping(address => ticket[]) private _userInfoMapList;

    function getLatestPrize() external view returns (uint256 timeStamp, uint[] memory Prize) {
        timeStamp = _lastTime;
        Prize = _Prize;
    }

    function newLottery(uint openTime, uint endTime) external onlyOwner() {

        _openTime = openTime;
        _endTime = endTime;

    }
    
    function openLottery(bool isLotteryOpen) external onlyOwner() {

        _isLotteryOpen = isLotteryOpen;
    }

    function getUserInfo(address user) public view returns (ticket[] memory numberInT) {

        return (_userInfoMap[user]);
    }


    function buyTicket(ticketNumber[] memory ticketList) external {

        uint amountOfTicket = ticketList.length;

        // require(_isLotteryOpen, "Lottery closed");

        // require(block.timestamp > _openTime, "Not time to buy");

        // require(ERC20(_tokenReward).balanceOf(_msgSender()) >= _price * amountOfTicket, "You are not enough tokens to buy"); 



        for (uint i = 0; i < amountOfTicket; i++) {
            
            require(ticketList[i].numberInTicket.length == 8, "You have to choose 8 teams");

            _templateTicket.numericalOrder = _userInfoMap[_msgSender()].length + 1;
            _templateTicket.numberInTicket = ticketList[i];
            _templateTicket.purchaseDate = block.timestamp;
            _templateTicket.expiryDate = _endTime;

            _userInfoMap[_msgSender()].push(_templateTicket);

        }
        

    }

    function lotteryTicket() external onlyOwner() {
        for (uint i = 0; i < 8; i++) {
            _Prize.push(random(i));
        }
        _lastTime = block.timestamp;

        _numericalOrderLottery += 1;

    }
    function random(uint numericalOrder) private view returns(uint) {

        bytes memory source;

        source = abi.encodePacked(
            _tokenReward,
            numericalOrder,
            _numericalOrderLottery,
            address(this),
            block.gaslimit,
            gasleft(),
            block.timestamp,
            block.number,
            msg.sig,
            blockhash(block.number),
            block.difficulty
        );  


        uint rand = (uint(keccak256(source))).mod(_xFactor);

        return rand;
    }

}
