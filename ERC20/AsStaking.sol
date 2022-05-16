// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./interface/IERC20.sol";

contract AsStaking{

    using SafeMath for uint256;
    uint256 internal constant MASK = type(uint256).max;

    address AsToken;
    address[] array;

    mapping(address => UserInfo) userMapping;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner,address indexed spender,uint256 amount);
    event depositEvent(address indexed user,address indexed to,uint256 _amount);
    event withdrawEvent(address indexed from,address indexed user,uint256 _amount,uint256 earnings);
    event withdrawAllEvent(address indexed from,address indexed user,uint256 _amount,uint256 earnings);
    event claimEvent(address indexed user,uint256 earnings);

    struct UserInfo {
        address user;
        uint256 amount;
        uint256 time;
        bool used;
    }

    constructor(address _AsToken){
        AsToken = _AsToken;
    }


    //需要使用用户账号去调用AS的approve给staking授权
    //_index:后台先查询合约的index，然后再存储一个大于indiex的字段，表示用户的id。调用接口时，需传入，以此判断是否是新用户，或是二次质押
    //质押
    function deposit(address user, uint256 _amount) public {

        require(msg.sender == user,"NotI am not");

        if (userMapping[user].used == false){//判断是否是新用户
            userMapping[user] = UserInfo(//是，则存储新用户信息
                user,
                _amount,
                block.timestamp,//获取用户质押的当前天数
                true
            );
            array.push(user);
        }else{//不是新用户，则是老用户在增加质押的币
            userMapping[user].amount += _amount;
        }

        IERC20(AsToken).transferFrom(user,address(this),_amount);//用户向合约转钱
        
        emit depositEvent(user,address(this),_amount);//发送事件
    }

    //取出指定token和所有利息
    function withdraw(address user, uint256 _amount) public {

        require(msg.sender == user,"NotI am not");
        
        uint256 earnings = calculateEarnings(user);
        
        require(_amount <= userMapping[user].amount,"The withdrawal amount is greater than the pledged amount");//余额是否充足
        require(userMapping[user].amount != 0,"The balance is zero");//余额不等于0
        
        IERC20(AsToken).transferFrom(address(this),user,_amount);//合约向用户转出用户指定提取的数量代币
        IERC20(AsToken).transferFrom(address(this),user,earnings);//合约向用户转出所有计算好的利息

        userMapping[user].time = block.timestamp;//存储天数归0，重新计算利息
        userMapping[user].amount -= _amount;//更改用户信息，减去取出的代币
        
        emit withdrawEvent(address(this),user,_amount,earnings);//发送事件
    }

    //取出所有token和所有利息，逻辑同上。
    function withdrawAll(address user) public {
        
        withdraw(user,userMapping[user].amount);

    }

    //取出利息
    function claim(address user) public {

        require(msg.sender == user,"NotI am not");

        uint256 earnings = calculateEarnings(user);
        
        IERC20(AsToken).transferFrom(address(this),user,earnings);//合约向用户转出所有计算好的利息
        
        userMapping[user].time = block.timestamp;//存储天数归0，重新计算利息
        
        emit claimEvent(user,earnings); //发送事件
    }

    // //取出所有利息
    // function claimAll() public {

    // }

    // function getIndex() public view returns(uint256){
    //     return index;
    // }

    function getData(address user) public view returns(UserInfo memory){
        return userMapping[user];
    }

    //刷新数据
    function getAllData() public view returns(address[] memory,uint[] memory,uint[] memory) {

        address[] memory accounts = new address[](uint256(array.length));
        uint[] memory amounts = new uint[](uint256(array.length));
        uint[] memory earnings = new uint[](uint256(array.length));

        for(uint256 i=0;i<array.length;i++){

            address userAddress = array[i];

            accounts[i] = userMapping[userAddress].user;//用户
            amounts[i] = userMapping[userAddress].amount;//已存入的金额 
            earnings[i] = calculateEarnings(userAddress);//可提取的奖励
        }
        return (accounts,amounts,earnings);//返回值

    }

    // function emergencyWithdraw(address _lpToken) public {

    // }

    function calculateEarnings(address user) internal view returns(uint256){
        
        uint256 day = (block.timestamp - userMapping[user].time)/(24*60*60);//判断存入天数与取出天数之间，是年化率还是日化率，最后根据公式取值
        uint256 earnings;

        if(day < 365){
            earnings = userMapping[user].amount * day * 2/3650;//日化率
        }else{
            earnings = userMapping[user].amount;//年化率
        } 

        return earnings;
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];
        if (spender != src && spenderAllowance != MASK) {
            uint256 newAllowance = spenderAllowance.sub(amount);
            allowances[src][spender] = newAllowance;
            emit Approval(src, spender, newAllowance);
        }
        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(
            src != address(0),
            "_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "_transferTokens: cannot transfer to the zero address"
        );
        balances[src] = balances[src].sub(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(src, dst, amount);
        
    }
}